const prisma = require('../config/prisma');
const { Prisma } = require('../../generated/prisma');
const { hashPassword } = require('../utils/hash');
const { PrismaClientKnownRequestError } = require('../../generated/prisma/runtime/library');

async function getAll(filter = {}) {
    const where = {};
    if(filter.role) {
        where.role = filter.role;
    }

    return prisma.user.findMany({
        where,
        select: { id: true, name: true, email: true, role: true },
        orderBy: { name: 'asc' },
    });
}

async function create(data) {
    const passwordHash = await hashPassword(data.password);

    try {
        return await prisma.user.create({
            data : {
                name : data.name,
                email: data.email,
                passwordHash,
                role: data.role,
            },
            select: { id: true, name: true, email: true, role: true, createdAt: true },
        });
    } catch (err) {
        if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
            throw { status: 409, message: "Email sudah terdaftar" };
        }

        throw err;
    }
}

async function getById(id) {
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) {
        throw { status: 404, message: "User tidak ditemukan" };
    }
    return user;
}

async function update(id, data) {
    await getById(id);

    const updateData = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.email !== undefined) updateData.name = data.email;
    if (data.role !== undefined) updateData.name = data.role;
    if (data.password !== undefined) updateData.passwordHash = await hashPassword(data.password);

    try {
        return await prisma.user.update({
            where: { id },
            data: updateData,
            select: { id: true, name: true, email: true, role: true, isActive: true },
        });
    } catch (err) {
        if (err instanceof PrismaClientKnownRequestError && err.code === "P2002") {
            throw { status: 409, message: "Email sudah terdaftar "};
        }
        throw err;
    }
}

async function deactive(id, actingUser) {
    if (id === actingUser.id) {
        throw { status: 400, message: "Tidak bisa menonaktifkan akun sendiri" };
    }

    await getById(id);

    return prisma.$transaction(async (tx) => {
        const user = await tx.user.update({
            where: { id },
            data: { isActive: false },
            select: { id: true, name: true, email: true, role: true, isActive: true },
        });

        await tx.refreshToken.updateMany({
            where: { userId: id, revokedAt: null },
            data: { revokedAt: new Date() },
        });

        return user;
    })
}

async function reactivate(id) {
    const user = await getById(id);

    if (user.isActive) {
        throw { status: 400, message: "Akun sudah aktif" };
    }

    return prisma.user.update({
        where: { id },
        data: { isActive: true },
        select: { id: true, name: true, email: true, role: true, isActive: true },
    });
}

module.exports = { getAll, create, getById, update, deactive, reactivate };