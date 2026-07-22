const prisma = require("../config/prisma");

const HEARTBEAT_INTERVAL_MS = 60 * 1000; 

function isOnline(device) {
    if (!device.lastSeenAt) return false;
    return Date.now() - device.lastSeenAt.getTime() <= HEARTBEAT_INTERVAL_MS;
}

async function getAll() {
    const devices = await prisma.device.findMany({ orderBy: { deviceCode: "asc" } });

    return devices.map((d) => ({
        ...d,
        status: isOnline(d) ? "online" : "offline",
    }));
}

async function heartbeat(deviceCode, firmwareVersion) {
    const device = await prisma.device.findUnique({ where: { deviceCode } });

    if (!device) {
        throw { status: 404, message: "Device tidak terdaftar" };
    }

    return prisma.device.update({
        where: { deviceCode },
        data: {
            status: "online",
            lastSeenAt: new Date(),
            ...(firmwareVersion ? { firmwareVersion } : {}),
        },
    });
}

async function getLastUnknownScan(deviceId) {
    const log = await prisma.log.findFirst({
        where: {
            deviceId,
            eventType: "scan_attempt",
            payload: { path: ['result'], equals: "unknown_credential" },
        },
        orderBy: { createdAt: 'desc' },
    });

    if (!log) return null;

    return {
        value: log.payload.value,
        type: log.method,
        scannedAt: log.createdAt,
    };
}

module.exports = { getAll, heartbeat, isOnline, HEARTBEAT_INTERVAL_MS, getLastUnknownScan };