const prisma = require('../config/prisma');

const TIME_REGEX = /^([01]\d|2[0-3]):([0-5]\d)$/;

function parseTime(value, fieldName){
    if (!TIME_REGEX.test(value)){
        throw { status: 400, message: `${fieldName} harus berformat HH:mm (contoh: 07:00)` };
    }
    return new Date(`1970-01-01T${value}:00Z`);
}

async function getAll(user){
    const where = user.role === "guru" ? { homeroomTeacherId: user.id } : {};

    return prisma.class.findMany({
        where,
        orderBy: { name: "asc" },
    });
}

async function create(data){
    if (data.homeroomTeacherId !== undefined && data.homeroomTeacherId !== null){
        const teacher = await prisma.user.findUnique({
            where: { id : data.homeroomTeacherId },
        });

        if (!teacher){
            throw { status: 400, message: "Guru dengan ID tersebut tidak ditemukan" };
        }

        if (teacher.role !== "guru"){
            throw { status: 400, message: "User dengan ID tersebut bukan guru" };
        }
    }

    const checkInStart = parseTime(data.checkInStart, "checkInStart");
    const checkInDeadline = parseTime(data.checkInDeadline, "checkInDeadline");

    if (checkInDeadline <= checkInStart){
        throw { status: 400, message: "checkInDeadline harus lebih besar dari checkInStart" };
    }
    return prisma.class.create({
        data : {
            name: data.name,
            homeroomTeacherId: data.homeroomTeacherId ?? null,
            checkInStart,
           checkInDeadline,
        },
    });
}

async function update(id, data){
    const existing = await prisma.class.findUnique({ where: { id }});
    if (!existing){
        throw { status: 404, message: "Kelas tidak ditemukan" };
    }

    const updateData = {};

    if (data.name !== undefined){
        updateData.name = data.name;
    }

    if (data.homeroomTeacherId !== undefined){
        if (data.homeroomTeacherId !== null){
            const teacher = await prisma.user.findUnique({
                where: { id: data.homeroomTeacherId },
            });
            if (!teacher){
                throw { status: 400, message: "Guru dengan ID tersebut tidak ditemukan" };
            }
            if (teacher.role !== "guru"){
                throw { status: 400, message: "User dengan ID tersebut bukan guru" };
            }
        }
        updateData.homeroomTeacherId = data.homeroomTeacherId;
    }

    let checkInStart = existing.checkInStart;
    let checkInDeadline = existing.checkInDeadline;

    if (data.checkInStart !== undefined) {
        checkInStart = parseTime(data.checkInStart, "checkInStart");
        updateData.checkInStart = checkInStart;
    }
    if (data.checkInDeadline !== undefined) {
        checkInDeadline = parseTime(data.checkInDeadline, "checkInDeadline");
        updateData.checkInDeadline = checkInDeadline;
    }

    if (checkInDeadline <= checkInStart) {
        throw { status: 400, message: "checkInDeadline harus lebih besar dari checkInStart" };
    }

    return prisma.class.update({ where: { id }, data: updateData });
}

module.exports = { getAll, create, update };