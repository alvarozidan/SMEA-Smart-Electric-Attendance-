const crypto = require('crypto');
const prisma = require('../config/prisma');
const { comparePassword } = require('../utils/hash');
const { signAccessToken, signRefreshToken, verifyRefreshToken } = require('../utils/jwt');

function hashToken(token){
    return crypto.createHash("sha256").update(token).digest("hex");
}

async function login(email, password){
    const user = await prisma.user.findUnique({ where: { email }});
    if (!user) {
        throw { status: 401, message: "Email atau password anda salah"};
    }

    if (!user.isActive) {
        throw { status: 403, message: "Akun anda telah dinonaktifkan" };
    }

    const isValid = await comparePassword(password, user.passwordHash);
    if (!isValid) {
        throw { status: 401, message: "Email atau password anda salah"};
    }

    const payload = { userId: user.id, role: user.role }
    const accessToken = signAccessToken(payload);
    const refreshToken = signRefreshToken(payload);

    await prisma.refreshToken.create({
        data: {
            userId: user.id,
            tokenHash: hashToken(refreshToken),
            expiresAt: new Date(Date.now() + 7 *24 * 60 * 60 * 1000),
        },
    });

    return {
        accessToken,
        refreshToken,
        user: { id: user.id, email: user.email, role: user.role },
    };
}

async function refresh(oldRefreshToken){
    let decoded;
    try {
        decoded = verifyRefreshToken(oldRefreshToken);
    } catch {
        throw {
            status: 401,
            message: "Refresh token tidak valid atau expired",
        };
    }

    const tokenHash = hashToken(oldRefreshToken);
    const stored = await prisma.refreshToken.findFirst({ 
        where: { userId: decoded.userId, tokenHash },
    });

    if (!stored || stored.revokedAt){
        throw {
            status: 401,
            message: "Refresh token sudah di-revoke atau tidak valid",
        };
    }

    if (stored.expiresAt < new Date()){
        throw {
            status: 401,
            message: "Refresh token sudah expired",
        };
    }

    const payload = { userId: decoded.userId, role: decoded.role };
    const newAccessToken = signAccessToken(payload);

    return{ accessToken: newAccessToken };
}

async function logout(refreshToken){
    const tokenHash = hashToken(refreshToken);
    await prisma.refreshToken.updateMany({
        where: { tokenHash, revokedAt: null },
        data: { revokedAt: new Date() },
    });
}

module.exports = { login, refresh, logout };
