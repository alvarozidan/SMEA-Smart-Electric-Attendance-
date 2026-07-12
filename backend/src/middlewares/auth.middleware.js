const { verifyAccessToken } = require('../utils/jwt');

function authenticate(req, res, next){
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")){
        return res.status(401).json({ message: "Token tidak ditemukan" });
    }

    const token = authHeader.split(" ")[1];

    try {
        const decoded = verifyAccessToken(token);
        req.user = { id: decoded.userId, role: decoded.role };
        next();
    } catch (err){
        return res.status(401).json({ message: "Token tidak valid atau expired" });
    }
}

module.exports = authenticate;