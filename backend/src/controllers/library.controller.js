const libraryService = require('../services/library.service');

async function lastScan(req, res, next) {
    try {
        const deviceId = parseInt(req.params.id, 10);
        if (isNaN(deviceId)) return res.status(400).json({ message: "ID device tidak valid" });

        const result = await libraryService.getLastLibraryScan(deviceId);
        res.status(200).json(result);
    } catch (err) {
        next (err);
    }
}

async function borrow(req, res, next) {
    try {
        const { rfidUid, bookBarcodes } = req.body;
        if (!rfidUid || !Array.isArray(bookBarcodes) || bookBarcodes.length === 0) {
            return res.status(400).json({ message: "rfidUid dan bookBarcodes[] wajib diisi" });
        }
        const loans = await libraryService.borrowLoan({ rfidUid, bookBarcodes, actorUserId: req.user.id });
        res.status(201).json(loans); 
    } catch (err) {
        next(err);
    }
}

async function returnBook(req, res, next) {
    try {
        const { bookBarcodes } = req.body;
        if (!bookBarcodes) {
            return res.status(400).json({ message: "bookBarcodes wajib diisi" });
        }
        const loan = await libraryService.returnLoan({ bookBarcodes, actorUserId: req.user.id });
        res.status(200).json(loan);
    } catch (err) {
        next(err);
    }
}

async function listLoans(req, res, next) {
    try {
        const loans = await libraryService.listActiveLoansWithOverdue();
        res.status(200).json(loans);
    } catch(err) {
        next(err);
    }
}
module.exports = { lastScan, borrow, returnBook, listLoans };