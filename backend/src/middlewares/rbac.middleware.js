function requireRole(...allowedRoles) {
    return (req, res, next) => {
        if (!req.user || !allowedRoles.includes(req.user.role)) {
            return res.status(403).json({ message : " Anda tidak punya akses ke resource ini" });
        }
        next();
    };
}

module.exports = { requireRole } ;