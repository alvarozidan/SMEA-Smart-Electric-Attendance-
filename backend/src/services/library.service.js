const prisma = require('../config/prisma');

const LOAN_PERIOD_DAYS = 7;
const MAX_UMUM_BOOKS = 2;
const MAX_EXTENSIONS = 1;

/**
 * Dipanggil dari mqtt/subcriber.js saat device bertipe PERPUSTAKAAN menerima tap RFID.
 * Pola sama persis dengan getLastUnknownScan di devices.service.js — simpan ke logs,
 * bukan cache in-memory, supaya konsisten dengan arsitektur existing.
 */
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

/**
 * Dipoll oleh Flutter (Timer.periodic) sampai dapat UID baru.
 * Tidak difilter "since" di backend — sama seperti getLastUnknownScan,
 * staleness dicek di client pakai scannedAt (lihat rfid_bind_screen.dart).
 */
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

/**
 * FR-04, Rule #11: validasi kuota. Batch (>1 barcode) diproses atomik —
 * kalau melanggar kuota, seluruh batch ditolak, tidak ada partial-save.
 */
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
      throw { status: 404, message: "RFID tidak terdaftar" };
    }

    const books = await tx.book.findMany({ where: { barcode: { in: bookBarcodes } } });
    if (books.length !== bookBarcodes.length) {
      throw { status: 404, message: "Sebagian barcode buku tidak ditemukan" };
    }

    const unavailable = books.filter((b) => b.status === "DIPINJAM");
    if (unavailable.length) {
      throw { status: 409, message: `Buku sedang dipinjam: ${unavailable.map((b) => b.barcode).join(", ")}` };
    }

    // Rule #11: hitung via relasi studentId, bukan rfidUid saja — supaya tetap benar
    // kalau kartu siswa pernah diganti (rule #1) di tengah periode peminjaman.
    const activeUmumCount = await tx.loan.count({
      where: {
        status: "DIPINJAM",
        book: { category: "UMUM" },
        studentCredential: { studentId: studentCred.studentId },
      },
    });
    const newUmumCount = books.filter((b) => b.category === "UMUM").length;
    if (activeUmumCount + newUmumCount > MAX_UMUM_BOOKS) {
      throw {
        status: 409,
        message: `Kuota buku UMUM terlampaui (maks ${MAX_UMUM_BOOKS}, sedang dipinjam ${activeUmumCount})`,
      };
    }

    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + LOAN_PERIOD_DAYS);

    const createdLoans = [];
    for (const book of books) {
      createdLoans.push(await tx.loan.create({ data: { bookId: book.id, rfidUid, dueDate } }));
    }

    await tx.book.updateMany({
      where: { id: { in: books.map((b) => b.id) } },
      data: { status: "DIPINJAM" },
    });

    // Rule #10: audit trail
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

/**
 * FR-06, Rule #12: quick return via scan barcode, tanpa cari ID transaksi manual.
 */
async function returnLoan({ bookBarcode, actorUserId }) {
  return prisma.$transaction(async (tx) => {
    const book = await tx.book.findUnique({ where: { barcode: bookBarcode } });
    if (!book) throw { status: 404, message: "Buku tidak ditemukan" };

    const activeLoan = await tx.loan.findFirst({ where: { bookId: book.id, status: "DIPINJAM" } });
    if (!activeLoan) throw { status: 404, message: "Tidak ada transaksi peminjaman aktif untuk buku ini" };

    const returnedAt = new Date();
    const diffMs = returnedAt - activeLoan.dueDate;
    const overdueDays = diffMs > 0 ? Math.ceil(diffMs / 86400000) : 0;

    const updatedLoan = await tx.loan.update({
      where: { id: activeLoan.id },
      data: { returnedAt, status: "DIKEMBALIKAN", overdueDays },
    });

    await tx.book.update({ where: { id: book.id }, data: { status: "TERSEDIA" } });

    await tx.log.create({
      data: {
        eventType: "library_return",
        method: "rfid",
        payload: { actorUserId, bookBarcode, overdueDays, loanId: activeLoan.id },
      },
    });

    return updatedLoan;
  });
}

/**
 * Perpanjangan masa pinjam: maksimal 1x, TIDAK berlaku untuk buku kategori PELAJARAN.
 * Dicari via bookBarcode (quick-flow), konsisten dengan returnLoan.
 */
async function extendLoan({ bookBarcode, actorUserId }) {
  return prisma.$transaction(async (tx) => {
    const book = await tx.book.findUnique({ where: { barcode: bookBarcode } });
    if (!book) throw { status: 404, message: "Buku tidak ditemukan" };

    if (book.category === "PELAJARAN") {
      throw { status: 409, message: "Buku kategori PELAJARAN tidak dapat diperpanjang" };
    }

    const activeLoan = await tx.loan.findFirst({ where: { bookId: book.id, status: "DIPINJAM" } });
    if (!activeLoan) throw { status: 404, message: "Tidak ada transaksi peminjaman aktif untuk buku ini" };

    if (activeLoan.extensionCount >= MAX_EXTENSIONS) {
      throw { status: 409, message: `Buku ini sudah pernah diperpanjang (maks ${MAX_EXTENSIONS}x)` };
    }

    if (activeLoan.dueDate < new Date()) {
      throw { status: 409, message: "Buku sudah melewati tenggat waktu, tidak bisa diperpanjang" };
    }

    const newDueDate = new Date(activeLoan.dueDate);
    newDueDate.setDate(newDueDate.getDate() + LOAN_PERIOD_DAYS);

    const updatedLoan = await tx.loan.update({
      where: { id: activeLoan.id },
      data: {
        dueDate: newDueDate,
        extensionCount: { increment: 1 },
      },
    });

    await tx.log.create({
      data: {
        eventType: "library_extend",
        method: "rfid",
        payload: {
          actorUserId,
          bookBarcode,
          loanId: activeLoan.id,
          oldDueDate: activeLoan.dueDate,
          newDueDate,
        },
      },
    });

    return updatedLoan;
  });
}

async function listActiveLoansWithOverdue() {
  return prisma.$queryRaw`
    SELECT
      l.id, b.barcode AS "bookBarcode", b.title AS "bookTitle", b.category AS "bookCategory",
      l.rfid_uid AS "rfidUid", s.name AS "studentName", s.nis AS "studentNis",
      l.borrowed_at AS "borrowedAt", l.due_date AS "dueDate", l.extension_count AS "extensionCount",
      GREATEST(0, DATE_PART('day', NOW() - l.due_date))::int AS "overdueDaysLive"
    FROM loans l
    JOIN books b ON b.id = l.book_id
    JOIN student_credentials sc ON sc.rfid_uid = l.rfid_uid
    JOIN students s ON s.id = sc.student_id
    WHERE l.status = 'DIPINJAM'
    ORDER BY l.due_date ASC
  `;
}

module.exports = {
  recordLibraryScan,
  getLastLibraryScan,
  borrowLoan,
  returnLoan,
  extendLoan,
  listActiveLoansWithOverdue,
};