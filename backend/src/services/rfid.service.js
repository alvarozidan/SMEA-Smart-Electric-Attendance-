const prisma = require('../config/prisma');
const { Prisma } = require('../../generated/prisma');
const { isOnline } = require('./devices.service');

async function assertDeviceReady(deviceId){
    const device = await prisma.device.findUnique({ where: { id: deviceId } });
    if(!device){
        throw{ status: 404, message: "Devvice tidak ditemukan" };
    }
    if(!device.registrationMode){
        throw{ status: 403, message: "Mode registrasi belum diaktifkan" };
    }
    if(!isOnline(device)){
        throw{ status: 409, message: "Device sedang offline - registrasi tidak bisa dilakukan" };
    }
    return device;
}

async function assertStudentAccessible(studentId, user){
    const student = await prisma.student.findFirst({
        where: { id: studentId, isDeleted: false },
        include: { class: true },
    });
    if(!student){
        throw{ status: 404, message: "Siswa tidak ditemukan" };
    }
    if(user.role === "guru" && student.class?.homeroomTeacherId !== user.id){
        throw{ status: 403, message: "Anda tidak punya akses terhadap siswa ini" };
    }
    return student;
}

async function register(data, user){
    const { studentId, deviceId, type, value } = data;

    if(!["rfid", "fingerprint"].includes(type)){
        throw{ status: 400, message: "Type harus rfid atau fingerprint" };
    }
    
    await assertDeviceReady(deviceId);
    await assertStudentAccessible(studentId, user);

    const existing = await prisma.studentCredential.findUnique({ where: { studentId } });

    if(type === "rfid" && existing?.rfidUid){
        throw{ status: 409, message: "Siswa sudah puna RFID aktif" };
    }
    if(type === "fingerprint" && existing?.fingerprintIndex != null){
        throw{ status: 409, message: "Siswa sudah punya fingerprint aktif" };
    }
    
    const dataToWrite = type === "rfid"
        ? { rfidUid: value }
        : { fingerprintIndex: parseInt(value, 10) };

        try {
            return await prisma.$transaction(async (tx) => {
                const credential = await tx.studentCredential.upsert({
                    where: { studentId },
                    create: { studentId, ...dataToWrite },
                    update: dataToWrite,
                });
                await tx.log.create({
                    data: {
                        eventType: "bind_rfid",
                        method: type,
                        deviceId,
                        studentId,
                        payload: { actorUserId: user.id, value },
                    },
                });
                return credential
            });
        } catch(err){
            if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002"){
                throw {
                    status: 409,
                    message: `${type === "rfid" ? "RFID UID" : "Fingerprint index"} sudah dipakai siswa lain`,
                };
            }
            throw err;
        }
}

async function unbind(uid, user){
    const credential = await prisma.studentCredential.findUnique({
        where: { rfidUid: uid },
        include: { student: { include: { class: true } } },
    });

    if(!credential){
        throw { status: 404, message: "RFID UID tidak ditemukan" };
    }
    if(user.role === "guru" && credential.student.class?.homeroomTeacherId !== user.id){
        throw { status: 403, message: "Anda tidak punya akses terhadap siswa ini" };
    }

    return prisma.$transaction(async (tx) => {
        const updated = await tx.studentCredential.update({
            where: { id: credential.id },
            data: { rfidUid: null },
        });
        await tx.log.create({
            data: {
                eventType: "unbind_rfid",
                method: "rfid",
                studentId: credential.studentId,
                payload: { actorUserId: user.id, unboundUid: uid },
            },
        });
        return updated;
    });
}

async function toggleRegistrationMode(deviceId, enabled){
    const device = await prisma.device.findUnique({ where: { id: deviceId } });
    if(!device){
        throw { status: 404, message: "Device tidak ditemukan" };
    }
    return prisma.device.update({
        where: { id: deviceId },
        data: { registrationMode: enabled },
    });
}

module.exports = { register, unbind, toogleRegistrationMode };
