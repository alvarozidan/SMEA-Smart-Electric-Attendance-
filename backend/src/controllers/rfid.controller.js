const rfidService = require('../services/rfid.service');

async function register(req, res, next){
    try {
        const { studentId, deviceId, type, value } = req.body;
        if (!studentId || !deviceId || !type || !value){
            return res.status(400).json({ message: "StudentId, deviceId, type, dan value wajib diisi" });
        }
        const result = await rfidService.register(
            { studentId: parseInt(studentId, 10), deviceId: parseInt(deviceId, 10), type, value },
            req.user
        );
        res.status(200).json(result);
    } catch(err){
        next(err);
    }
}

async function unbind(req, res, next){
    try {
        const result = await rfidService.unbind(req.params.uid, req.user);
        res.status(200).json(result);
    } catch(err){
        next(err);
    }
}

async function toggleRegistrationMode(req, res, nex){
    try {
        const { deviceId, enabled } = req.body;
        if(deviceId === undefined || typeof enabled !== "boolean"){
            return res.status(400).json({ message: "deviceId dan enabled(boolean) wajib diisi" });
        }
        const device = await rfidService.toogleRegistrationMode(parseInt(deviceId, 10), enabled);
        res.status(200).json(device);
    } catch(err){
        next(err);
    }
}

module.exports = { register, unbind, toggleRegistrationMode };
