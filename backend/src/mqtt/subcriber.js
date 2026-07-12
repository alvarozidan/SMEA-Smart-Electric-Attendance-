const { getMqttClient } = require('./client');
const { SCAN_WILDCARD, HEARTBEAT_WILDCARD, SYNC_WILDCARD } = require('./topics');
const { publishResult } = require('./publisher');
const prisma = require('../config/prisma');
const attendanceService = require('../services/attendance.service');
const devicesService = require('../services/devices.service');

function extractDeviceCode(topic){
    return topic.split("/")[1];
}

async function resolveDeviceId(deviceCode) {
    const device = await prisma.device.findUnique({ where: {deviceCode } });
    if(!device){
        throw { status: 404, message: `Device dengan code ${deviceCode} tidak terdaftar` };
    }
    return device.id;
}

async function handleScan(deviceCode, payload){
    try {
        const deviceId = await resolveDeviceId(deviceCode);
        const attendance = await attendanceService.recordScan({
            method: payload.type,
            value: payload.value,
            deviceId,
        });
        publishResult(deviceCode, { success: true, status: attendance.status });
    }catch(err){
        publishResult(deviceCode, { success: false, message: err.message || "Terjadi kesalahan" });
    }
}

async function handleHeartbeat(deviceCode, payload){
    try {
        await devicesService.heartbeat(deviceCode, payload.firmwareVersion);
    } catch(err){
        console.error(`[MQTT] Heartbeat gagal untuk ${deviceCode}: `, err.message);
    }
}

async function handleSync(deviceCode, payload){
    if(!Array.isArray(payload)){
        console.error(`[MQTT] Payload sync dari ${deviceCode} bukan array, diabaikan`);
        return;
    }

    let deviceId;
    try {
        deviceId = await resolveDeviceId(deviceCode);
    } catch(err){
        console.error(err.message);
        return;
    }

    for (const item of payload){
        try {
            await attendanceService.recordScan({
                method: item.type,
                value: item.value,
                deviceId,
                scannedAt: item.scannedAt,
            });
        } catch(err){
            console.error(`[MQTT] Gagal proses buffered scan dari ${deviceCode}: `, err.message);
        }
    }

    publishResult(deviceCode, { success: true, message: `${payload.length} data buffer berhasil disinkronkan` });
}

function startMqttSubscriber(){
    const client = getMqttClient();

    client.on("connect", () => {
        client.subscribe([SCAN_WILDCARD, HEARTBEAT_WILDCARD, SYNC_WILDCARD], (err) => {
            if(err){
                console.error("[MQTT] Gagal subscribe: ", err.message);
            } else{
                console.log("[MQTT] Subscribe ke topic scan, heartbeat, sync");
            }
        });
    });

    client.on("message", async (topic, messageBuffer) => {
        const deviceCode = extractDeviceCode(topic);
        let payload;

        try {
            payload = JSON.parse(messageBuffer.toString());
        } catch {
            console.error(`[MQTT] Payload tidak valid JSON dari topic ${topic}`);
            return;
        }

        if(topic.endsWith("/scan")){
            await handleScan(deviceCode, payload);
        } else if (topic.endsWith("/heartbeat")){
            await handleHeartbeat(deviceCode, payload);
        } else if (topic.endsWith("/sync")){
            await handleSync(deviceCode, payload);
        }
    });
}

module.exports = { startMqttSubscriber };