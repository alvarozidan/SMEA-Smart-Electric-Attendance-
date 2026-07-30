const bwipjs = require('bwip-js');
const PDFDocument = require('pdfkit');
const prisma = require('../config/prisma');

async function generateBarcodeImage(barcodeValue) {
    return bwipjs.toBuffer({
        bcid: 'code128',
        text: barcodeValue,
        scale: 3,
        height: 10,
        includetext: true,
        textxalign: 'center',
    });
}

async function generateBookLabel(barcodeParam) {
    const book = await prisma.book.findUnique({
        where: { barcode: barcodeParam },
    });

    if (!book) {
        const err = new Error('Buku tidak ditemukan');
        err.statusCode = 404;
        throw err;
    }

    const barcodeImage = await generateBarcodeImage(book.barcode);

    return new Promise((resolve, reject) => {
        const doc = new PDFDocument({ size: [151, 76] });
        const chunks = [];

        doc.on('data', (chunk) => chunks.push(chunk));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        doc.fontSize(8).text(book.title, {align: 'center', width: 151 });
        doc.image(barcodeImage, 10, 25, { width: 130 });

        doc.end();
    });
}

module.exports = { generateBarcodeImage, generateBookLabel };