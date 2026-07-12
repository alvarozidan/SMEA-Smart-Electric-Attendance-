const env = require('../config/env');

function authenticateDevice(req, res, next){
    const apiKey = req.headers["x-api-key"];

    if(!apiKey || apikey !== env.deviceApiKey){
        return res(401).json({ message: "API key perangkat tidak valid" });
    }

    next();
}

module.exports = authenticateDevice;