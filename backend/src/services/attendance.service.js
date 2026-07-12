const prisma = require('../config/prisma');
const { toDateOnlyWIB } = require("../utils/date.util");

const DUPLICATE_WINDOWS_MS = 5 * 60 * 1000;
const DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/;

function getTimeMs(date){
    return date.getHours() * 3600000 + date.getMinutes() * 60000 + date.getSeconds() * 1000;
}

function determineStatus(scanTime, classRecord){
    return getTimeMs(scanTime) <= getTimeMs(classRecord.checkInDeadline) ? "hadir" : "terlambat";
}

async function recordScan({ method, value, deviceId, scannedAt }){
    const scanTime = scannedAt ? new Date(scannedAt) : new Date();
    
    let credential;

    if(method === "rfid"){
        credential = await prisma.studentCredential.findUnique({
            where: { rfidUid: value},
            include: { student: { include: { class: true } } },
        });
    } else if(method === "fingerprint"){
        credential = await prisma.studentCredential.findUnique({
            where: { fingerprintIndex: parseInt(value, 10) },
            include: { student: { include: { class: true } } },
        });
    }else {
        throw { status: 400, message: "method harus rfid atau fingerprint" };
    }

    if(!credential || credential.student.isDeleted){
        await prisma.log.create({
            data: { eventType: "scan_attempt", method, deviceId, payload: { value, result: "unknown_credential" } },
        });
        throw { status: 404, message: "Kredensial tidak dikenali" };
    }

    const student = credential.student;

    if(!student.classId || !student.class){
        throw{ status: 400, message: "Siswa belum terdaftar di kelas manapun" };
    }

    const date = toDateOnlyWIB(scanTime);

    const existing = await prisma.attendance.findUnique({
        where: { studentId_date: { studentId: student.id, date } },
    });

    if(existing){
        const withinWindow = Math.abs(scanTime - existing.checkInTime) <= DUPLICATE_WINDOWS_MS;
        await prisma.log.create({
            data: {
                eventType: "scan_attempt",
                method,
                deviceId,
                studentId: student.id,
                payload: { result: withinWindow ? "duplicate_ignored" : "duplicate_outside_window" },
            },
        });
        return existing;
    }

    const status = determineStatus(scanTime, student.class);

    return prisma.$transaction(async (tx) => {
        const created = await tx.attendance.create({
            data: { studentId: student.id, classId: student.classId, date, checkInTime: scanTime, status, method },
        });
        await tx.log.create({
            data: {
                eventType: "attendance_recorded",
                method,
                deviceId,
                studentId: student.id,
                payload: { attendanceId: created.id, status, source: scannedAt ? "offline_sync" : "live" },
            },
        });
        return created;
    });
}

async function getAll(query, user){
    const where = {};

    if(user.role === "guru"){
        where.class = { homeroomTeacherId: user.id};
    }
    if(query.classId) where.classId = parseInt(query.classId, 10);
    if(query.date) where.date = new Date(query.date);
    if(query.studentId) where.studentId = parseInt(query.studentId, 10);

    return prisma.attendance.findMany({
        where,
        include: { student: true, class: true },
        orderBy: { date: "desc" },
    });
}

async function manualUpdate(id, data, user){
    const existing = await prisma.attendance.findUnique({ where: { id }, include: { class: true } });

    if(!existing){
        throw{ status: 404, message: "Data kehadiran tidak ditemukan" };
    }
    if(user.role === "guru" && existing.class.homeroomTeacherId !== user.id){
        throw{ status: 403, message: "Anda tidak punya akses ke data kehadiran ini" };
    }

    const allowedStatus = ["hadir", "terlambat", "tidak_hadir", "izin", "sakit"];
    if(!allowedStatus.includes(data.status)){
        throw { status: 400, message: "Status tidak valid" };
    }

    return prisma.$transaction(async (tx) => {
        const updated = await tx.attendance.update({
            where: { id },
            data: { status: data.status, method: "manual" },
        });
        await tx.log.create({
            data: {
                eventType: "attendance_manual_update",
                studentId: existing.studentId,
                payload: {
                    actorUserid: user.id,
                    previousStatus: existing.status,
                    newStatus: data.status,
                    attendanceId: id,
                },
            },
        });
        return updated;
    });
}

function parseDateParam(value, fieldName){
    if(!DATE_REGEX.test(value)){
        throw { status: 400, message: `${fieldName} harus berformat YYYY-MM-DD (contoh: 2026-07-01)` };
    }
    const date = new Date(value);
    if(isNaN(date.getTime())){
        throw { status: 400, message: `${fieldName} bukan tanggal yang valid` };
    }
    return date;
}

async function getReportData(query, user){
    const where = {};

    if(user.role === "guru"){
        where.class = { homeroomTeacherId: user.id };
    }
    if(query.classId) where.classId = parseInt(query.classId, 10);

    if(query.startDate || query.endDate){
        where.date = {};
        if(query.startDate) where.date.gte = parseDateParam(query.startDate, "startDate");
        if(query.endDate) where.date.lte = parseDateParam(query.endDate, "endDate");
    }

    if(where.date && where.date.gte && where.date.lte && where.date.gte > where.date.lte){
        throw { status: 400, message: "startDate harus lebih awal atau sama dengan endDate" };
    }

    return prisma.attendance.findMany({
        where,
        include: { student: true, class: true },
        orderBy: [{ date: "asc"}, { student: { name: "asc"} }],
    });
}


module.exports = { recordScan, getAll, manualUpdate, getReportData };