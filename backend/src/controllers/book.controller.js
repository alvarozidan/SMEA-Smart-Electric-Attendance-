const bookService = require('../services/book.service');
const labelService = require('../services/label.service');

async function getAll(req,res, next) {
    try {
        const { category, status } = req.query;
        const books = await bookService.getAll({ category, status });
        res.status(200).json(books);
    } catch (err) {
        next(err);
    }
}

async function getById(req, res, next) {
    try {
        const id = parseInt(req.params.id, 10);
        if(isNaN(id)) return res.status(400).json({ message: "ID buku tidak ditemukan" });

        const book = await bookService.getById(id);
        res.status(200).json(book);
    } catch (err) {
        next(err);
    }
}

async function create(req, res, next) {
    try {
        const { barcode, title, category } = req.body;
        const book = await bookService.create({ barcode, title, category });
        res.status(201).json(book);
    } catch (err) {
        next(err);
    }
} 

async function update(req, res, next) {
    try {
        const id = parseInt(req.params.id, 10);
        if (isNaN(id)) return res.status(400).json({ message: "ID buku tidak ditemukan" });

        const { title, category } = req.body;
        const book = await bookService.update(id, { title, category });
        res.status(200).json(book);
    } catch (err) {
        next(err);
    }
}

async function remove(req, res, next) {
    try {
        const id = parseInt(req.params.id, 10);
        if (isNaN(id)) return res.status(400).json({ message: "ID buku tidak ditemukan" });

        await bookService.remove(id);
        res.status(200).json({ message: "Buku berhasil dihapus" });  
    } catch (err) {
        next(err);
    }
}

async function getBookLabel(req, res, next) {
    try {
        const { barcode } = req.params;
        const pdfBuffer = await labelService.generateBookLabel(barcode);

        res.set({
            'Content-Type' :'application/pdf',
            'Content-Disposition' : `inline; filename="label-${barcode}.pdf"`,
        });
        res.send(pdfBuffer);
    } catch (err) {
        next(err);
    }
}

module.exports = { getAll, getById, create, update, remove, getBookLabel };