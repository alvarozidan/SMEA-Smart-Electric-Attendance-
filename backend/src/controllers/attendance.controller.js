const attendanceService= require("../services/attendance.service");
const { buildExcelBuffer, buildPdfBuffer } = require("../utils/report.util");

async function getAll(req, res, next){
    try {
        const data = await attendanceService.getAll(req.query, req.user);
        res.status(200).json(data)
    } catch(err){
        next(err);
    }
}

async function manualUpdate(req, res, next){
    try {
        const id = parseInt(req.params.id, 10);
        if(isNaN(id)) return res.status(400).json({ message: "ID kehadiran tidak valid" });

        const updated = await attendanceService.manualUpdate(id, req.body, req.user);
        res.status(200).json(updated);
    } catch(err){
        next(err);
    }
}

async function report(req, res, next){
    try {
        const format = req.query.format;
        if(!["excel", "pdf"].includes(format)){
            return res.status(400).json({ message: "formal harus excel atau pdf"});
        }

        const data = await attendanceService.getReportData(req.query, req.user);

        if (format === "excel"){
            const buffer = await buildExcelBuffer(data);
            res.setHeader("Content-Type", "application/vnd.opnxmlformats-officedocument.spreadsheetml.sheet");
            res.setHeader("Content-Disposition", "attachment; filename=laporan_kehadiran.xlsx");
            return res.send(buffer);
        }

        const buffer = await buildPdfBuffer(data);
        res.setHeader("Content-Type", "application/pdf");
        res.setHeader("Content-Disposition", "attachment; filename=laporan_kehadiran.pdf");
        res.send(buffer);
    } catch (err){
        next(err);
    }
}

module.exports = { getAll, manualUpdate, report };