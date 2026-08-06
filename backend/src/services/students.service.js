const prisma = require('../config/prisma');
const { Prisma } = require('../../generated/prisma');
const { hashPassword } = require('../utils/hash');
const ExcelJS = require('exceljs');

async function createStudentAccount(tx, student){
    const passwordHash = await hashPassword(student.nis);
    return tx.user.create({
        data: {
            name: student.name,
            role: "murid",
            passwordHash,
            mustChangePassword: true,
            studentId: student.id,
        },
    });
}

async function getAll(user){
    const where = { isDeleted: false };
    if (user.role === "guru"){
        where.class = { homeroomTeacherId: user.id };
    }
    return prisma.student.findMany({
        where,
        include: { class: true, credential: true },
        orderBy: { name: "asc" },
    });
}

async function getById(id, user){
    const student = await prisma.student.findFirst({
        where : { id, isDeleted: false },
        include: { class: true, credential: true },
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
        return await prisma.$transaction(async (tx) => {
            const student = await tx.student.create({
                data: {
                    nis: data.nis,
                    name: data.name,
                    classId: data.classId ?? null,
                },
            });
            await createStudentAccount(tx, student);
            return student;
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

        await tx.user.updateMany({
            where: { studentId: id },
            data: { isActive: false },
        });

        return student;
    });
}

function normalizeClassName(value) {
    return String(value ?? '').trim().toUpperCase();
}

async function bulkImport(fileBuffer, user) {
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(fileBuffer);

    const sheet = workbook.worksheets[0];
    if (!sheet) {
        throw { status: 400, message: "File excel tidak punya sheet" };
    }

    const classes = await prisma.class.findMany();
    const classMap = new Map(classes.map((c) => [normalizeClassName(c.name), c.id]));

    const existingStudents = await prisma.student.findMany({ select: { nis: true } });
    const existingNisSet = new Set(existingStudents.map((s) => s.nis));

    const validRows = [];
    const failed = [];
    const seenNisInFile = new Set();

    for (let rowNumber = 2; rowNumber <= sheet.rowCount; rowNumber++) {
        const row = sheet.getRow(rowNumber);
        const nis = String(row.getCell(1).value ?? '').trim();
        const name = String(row.getCell(2).value ?? '').trim();
        const className = String(row.getCell(3).value ?? '').trim();

        if (!nis && !name && !className) continue;

        if (!nis || !name) {
            failed.push({ row: rowNumber, nis: nis || null, name: name || null, reason: "NIS dan nama wajib terisi" });
            continue;
        }
        if (seenNisInFile.has(nis)) {
            failed.push({ row: rowNumber, nis, name, reason: "Terdapat NIS yang sama" });
            continue;
        }
        if (existingNisSet.has(nis)) {
            failed.push({ row: rowNumber, nis, name, reason: "NIS sudah terdaftar" });
            continue;
        }

        let classId = null;
        if (className) {
            classId = classMap.get(normalizeClassName(className)) ?? null;
            if (classId === null) {
                failed.push({ row: rowNumber, nis, name, reason: `Kelas '${className}' tidak ditemukan` });
                continue;
            }
        }

        seenNisInFile.add(nis);
        validRows.push({ nis, name, classId });
    }

    let successCount = 0;

    if (validRows.length > 0) {
        await prisma.$transaction(async (tx) => {
            for (const row of validRows) {
                const student = await tx.student.create({ data: row });
                await createStudentAccount(tx, student);
                successCount++;
            }
        });
    }

    await prisma.log.create({
        data: {
            eventType: "bulk_import_students",
            payload: {
                actorUserId: user.id,
                totalRows: validRows.length + failed.length,
                successCount,
                failedCount: failed.length,
            },
        },
    });

    return {
        totalRows: validRows.length + failed.length,
        successCount,
        failedCount: failed.length,
        failed,
    };
}

module.exports = { getAll, getById, create, update, softDelete, bulkImport };