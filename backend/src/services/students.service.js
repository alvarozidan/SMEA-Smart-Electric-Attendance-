const prisma = require('../config/prisma');
const { Prisma } = require('../../generated/prisma');

async function getAll(user){
    const where = { isDeleted: false };

    if (user.role === "guru"){
        where.class = { homeroomTeacherId: user.id };
    }

    return prisma.student.findMany({
        where,
        include: { class: true },
        orderBy: { name: "asc" },
    });
}

async function getById(id, user){
    const student = await prisma.student.findFirst({
        where : { id, isDeleted: false },
        include: { class: true }, 
    });

    if (!student){
        throw { status: 404, message: "Siswa tidak ditemukan" };
    }

    if (user.role === "guru" && student.class?.homeroomTeacherId !== user.id){
        throw { status: 403, message: "Anda tidak memiliki akses ke siswa ini" };
    }

    return student;
}

async function create(data, user){
    if (data.classId !== undefined && data.classId !== null){
        const classRecord = await prisma.class.findUnique({ where: { id: data.classId } });
        if (!classRecord){
            throw { status: 400, message: "classId tidak ditemukan" };
        }
        if (user.role === "guru" && classRecord.homeroomTeacherId !== user.id){
            throw { status: 403, message: "Guru hanya boleh menambahkan siswa di kelas tanggung jawabnya" };
        }
    }

    try{
        return await prisma.student.create({
            data: {
                nis: data.nis,
                name: data.name,
                classId: data.classId ?? null,
            },
        });
    
    } catch(err){
        if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002"){
            throw { status: 409, message: "NIS sudah terdaftar"};
        }
        throw err;
    }
    
}
        
async function update(id, data, user){
    const existing = await getById(id, user);

    const updateData = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.nis !== undefined) updateData.nis = data.nis;

    if (data.classId !== undefined){
        if (data.classId !== null){
            const classRecord = await prisma.class.findUnique({ where: {id: data.classId } });
            if (!classRecord){
                throw { status: 400, message: "classId tidak ditemukan" };
            }
            if (user.role === "guru" && classRecord.homeroomTeacherId !== user.id){
                throw { status: 403, message: "Guru hanya boleh memindahkan siswa ke kelas yang jadi tanggung jawabnya" };
            }
        }
        updateData.classId = data.classId;
    }
    try {
    return prisma.student.update({ where: {id: existing.id }, data: updateData });
    } catch (err){
        if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002"){
            throw { status: 409, message: "NIS sudah terdaftar" };
        }
        throw err;
    }
}

async function softDelete(id,user){
    await getById(id, user);

    return prisma.$transaction(async (tx) => {
        const student = await tx.student.update({
            where: { id },
            data: { isDeleted: true },
        });

        const credential = await tx.studentCredential.findUnique({ where: { studentId: id } });

        if(credential && (credential.rfidUid || credential.fingerprintIndex != null)){
            await tx.studentCredential.update({
                where: { studentId: id },
                data: { rfidUid: null, fingerprintIndex: null},
            });

            await tx.log.create({
                data: {
                    eventType: "credential_released_on_student_delete",
                    studentId: id,
                    payload: {
                        actorUserId: user.id,
                        releasedRfidUid: credential.rfidUid,
                        releasedFingerprintIndex: credential.fingerprintIndex,
                    },
                },
            });
        }

        return student;
    });
}

module.exports = { getAll, getById, create, update, softDelete };