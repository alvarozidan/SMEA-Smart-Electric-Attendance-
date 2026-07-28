const prisma = require('../config/prisma');

const LOAN_PERIOD_DAYS = 7;
const MAX_UMUM_BOOKS = 2;

async function recordLibraryScan({ deviceId, rfidUid, scannedAt }) {
    return prisma.log.create({
        data: {
            eventType: "library_scan",
            method: "rfid",
            deviceId,
            payload: { rfidUid },
            ...(scannedAt ? { createdAt: new Date(scannedAt) } : {}),
        },
    });
}

async function getLastLibraryScan(deviceId) {
    const log = await prisma.log.findFirst({
        where: { deviceId, eventType: "library_scan" },
        orderBy: { createdAt: "desc" },
    });

    if (!log) return null;

    return {
        rfidUid: log.payload.rfidUid,
        scannedAt: log.createdAt,
    };
}

async function borrowLoan({ rfidUid, bookBarcodes, actorUserId }) {
    if (!Array.isArray(bookBarcodes) || bookBarcodes.length === 0) {
        throw { status: 400, message: "bookBarcodes wajib diisi (minimal 1)" };
    }

    return prisma.$transaction(async (tx) => {
        const studentCred = await tx.studentCredential.findUnique({
            where: { rfidUid },
            include: { student: true },
        });
        if (!studentCred || studentCred.student.isDeleted) {
            throw { status: 401, message: "RFID tidak terdaftar" };
        }

        const books = await tx.book.findMany({
            where: { barcode: { in: bookBarcodes } }
        });
        if (books.length !== bookBarcodes.length) {
            throw { status: 404, message: "Sebagiann barcode buku tidak ditemukan" };
        }

        const unavailable = books.filter((b) => b.status === "DIPINJAM");
        if (unavailable.length) {
            throw { status: 409, message: `Buku sedang dipinjam: ${unavailable.map((b) => b.barcode).join(", ")}` };
        }

        const activeUmumCount = await tx.loan.count({
            where: {
                status: "DIPINJAM",
                book: { category: "UMUM" },
                studentCredential: { studentId: studentCred.studentId },
            },
        });
        const newUmumCount = books.filter((b) => b.category === "UMUM").length;
        if (activeUmumCount + newUmumCount > MAX_UMUM_BOOKS) {
            throw { status: 409, message: `Kuota buku terlampaui (maks. ${MAX_UMUM_BOOKS}, sedang dipinjam ${activeUmumCount})` };
        }

        const dueDate = new Date();
        dueDate.setDate(dueDate.getDate() + LOAN_PERIOD_DAYS);

        const createdLoans = [];
        for (const book of books) {
            createdLoans.push(await tx.loan.create({
                data: { bookId: book.id, rfidUid, dueDate }
            }));
        }

        await tx.book.updateMany({
            where: { id: { in: books.map((b) => b.id) } },
            data: { status: "DIPINJAM" },
        });

        await tx.log.create({
            data: {
                eventType: "library_borrow",
                method: "rfid",
                studentId: studentCred.studentId,
                payload: { actorUserId, bookBarcodes, loanIds: createdLoans.map((l) => l.id) },
            },
        });

        return createdLoans;
    });
}

async function returnLoan({ bookBarcodes, actorUserId }) {
    return prisma.$transaction(async (tx) => {
        const book = await tx.book.findUnique({
            where: { barcode: bookBarcodes }
        });
        if (!book) throw { sttaus: 404, message: "Buku tidak ditemukan" };

        const activeLoan = await tx.loan.findFirst({
            where: { bookId: book.id, status: "DIPINJAM" }
        });
        if (!activeLoan) throw { status: 404, message: "Tidak ada peminjaman aktif untuk buku ini" };

        const returnedAt = new Date();
        const diffMs = returnedAt - activeLoan.dueDate;
        const overdueDays = diffMs > 0 ? Math.ceil(diffMs / 86400000) : 0;

        const updatedLoan = await tx.loan.update({
            where: { id: activeLoan.id },
            data: { returnedAt, status: "DIKEMBALIKAN", overdueDays },
        });

        await tx.book.update({
            where: { id: book.id },
            data: { status: "TERSEDIA" }
        });

        await tx.log.create({
            data: {
                eventType: "library_return",
                method: "rfid",
                payload: { actorUserId, bookBarcodes, overdueDays, loanId: activeLoan.id },
            },
        });

        return updatedLoan;
    });
}

async function listActiveLoansWithOverdue() {
    return prisma.$queryRaw`
    SELECT
        l.id, b.barcode AS book_barcode, b.title AS book_title, l.rfid_uid,
        l.borrowed_at, l.due_date,
        GREATES(0, DATE_PART('day', NOW() - l.due_date))::int AS overdue_days_live
    FROM loans l
    JOIN books b ON b.id = l.book_id
    WHERE l.status = 'DIPINJAM',
    ORDER BY l.due_date ASC
    `;
}

module.exports = { recordLibraryScan, getLastLibraryScan, borrowLoan, returnLoan, listActiveLoansWithOverdue };
