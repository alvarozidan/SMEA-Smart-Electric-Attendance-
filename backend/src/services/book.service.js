const prisma = require('../config/prisma');
const { Prisma } = require('../../generated/prisma');

async function getAll({ category, status } = {}) {
    return prisma.book.findMany({
        where: {
            ...(category && { category}),
            ...(status && { status }),
        },
        orderBy: { title: "asc" },
    });
} 

async function getById(id) {
    const book = await prisma.book.findUnique({ where: { id } });
    if (!book){
        throw { status: 404, message: "Buku tidak ditemukan" };
    }
    return book;
}

async function create({ barcode, title, category }) {
    if (!barcode || !title || !category) {
        throw { status: 400, message: "barcode, title, dan category wajib diisi" };
    }
    if (!["UMUM", "PELAJARAN"].includes(category)) {
        throw { status: 400, message: "category harus UMUM atau PELAJARAN" };
    }

    try {
        return await prisma.book.create({
            data: { barcode, title, category },
        });
    } catch (err) {
        if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
            throw { status: 409, message: "Barcode buku sudah terdaftar" };
        }
        throw err;
    }
}

async function update(id, { title, category }) {
    await getById(id);

    if (category !== undefined && !["UMUM", '"PELAJARAN'].includes(category)) {
        throw { status: 400, message: "categroy harus UMUM atau PELAJARAN" };
    }
    return prisma.book.update({
        where: { id },
        data: {
            ...(title !== undefined && { title }),
            ...(category !== undefined && { category }),
        },
    });
}

async function remove(id) {
    const book = await getById(id);

    if (book.status === "DIPINJAM") {
        throw { status: 409, message: "Buku sedang dipinjam, tidak bisa dihapus" };
    }

    const hasHistory = await prisma.loan.findFirst({ where: { bookId: id } });
    if (hasHistory) {
        throw { status: 409, message: "Buku memiliki riwayat peminjaman, tidak bisa dihapus" };
    }

    return prisma.book.delete({ where: { id } });
}

module.exports = { getAll, getById, create, update, remove };