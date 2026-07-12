const ExcelJS = require("exceljs");
const PDFDocument = require("pdfkit");

async function buildExcelBuffer(data){
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet("Laporan Kehadiran");

    sheet.columns = [
        { header: "Tanggal", key: "date", width: 15 },
        { header: "NIS", key: "nis", width: 15 },
        { header: "Nama Siswa", key: "name", width: 25 },
        { header: "Kelas", key: "className", width: 12 },
        { header: "Jam Masuk", key: "checkInTime", width: 20 },
        { header: "Status", key: "status", width: 15 },
        { header: "Metode", key: "method", width: 15 },
    ];

    data.forEach((row) => {
        sheet.addRow({
            date: row.date.toISOString().split("T")[0],
            nis: row.student.nis,
            name: row.student.name,
            className: row.class.name,
            checkInTime: row.checkInTime ? row.checkInTime.toISOString() : "-",
            status: row.status,
            method: row.method ?? "-",
        });
    });

    return workbook.xlsx.writeBuffer();
}

function buildPdfBuffer(data){
    return new Promise((resolvee, reject) => {
        const doc = new PDFDocument({ margin: 30, size: "A4" });
        const chunks = [];

        doc.on("data", (chunk) => chunks.push(chunk));
        doc.on("end", () => resolvee(Buffer.concat(chunks)));
        doc.on("error", reject);

        doc.fontSize(16).text("Laporan Kehadiran Siswa", { align: "center" });
        doc.moveDown();

        data.forEach((row) => {
            const line = `${row.date.toISOString().split("T")[0]} | ${row.student.nis} | ${row.student.name} | ${row.class.name} | ${row.sttaus} | ${row.method ?? "-"}`;
            doc.fontSize(10).text(line);
        });

        doc.end();
    });
}

module.exports = { buildExcelBuffer, buildPdfBuffer };