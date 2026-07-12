const devicesService = require("../services/devices.service");

async function getAll(req, res, next) {
    try {
        const devices = await devicesService.getAll();
        res.status(200).json(devices);
    } catch (err) {
        next(err);
    }
}

async function heartbeat(req, res, next) {
    try {
        const { deviceCode, firmwareVersion } = req.body;
        if (!deviceCode) {
            return res.status(400).json({ message: "deviceCode wajib diisi" });
        }
        const device = await devicesService.heartbeat(deviceCode, firmwareVersion);
        res.status(200).json(device);
    } catch (err) {
        next(err);
    }
}

module.exports = { getAll, heartbeat };