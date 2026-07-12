const studentsService = require('../services/students.service');

async function getAll(req, res, next){
    try {
        const students = await studentsService.getAll(req.user);
        res.status(200).json(students);
    } catch(err){
        next(err);
    }
}

async function getById(req, res, next) {
    try {
        const id = parseInt(req.params.id, 10);
        if (isNaN(id)) return res.status(400).json({ message: "ID siswa tidak valid" });

        const student = await studentsService.getById(id, req.user);
        res.status(200).json(student);
    } catch (err){
        next(err);
    }
}

async function create(req, res, next){
    try {
        const { nis, name, classId } = req.body;
        if (!nis || !name){
            return res.status(400).json({ message: "nis dan nama harus diisi" });
        }

        const student = await studentsService.create({ nis, name, classId }, req.user);
        res.status(201).json(student);
    }catch (err){
        next(err);
    }
}

async function update(req, res, next){
    try {
        const id = parseInt(req.params.id, 10);
        if (isNaN(id)) return res.status(400).json({ message: "ID siswa tidak valid" });

        const student = await studentsService.update(id, req.body, req.user);
        res.status(200).json(student);
    } catch(err){
        next(err);
    }
}

async function remove(req, res, next){
    try {
        const id = parseInt(req.params.id, 10);
        if(isNaN(id)) return res.status(400).json({ message: "ID siswa tidak valid" });

        await studentsService.softDelete(id, req.user);
        res.status(200).json({ message: "Siswa berhasil dihapus" });
    } catch(err){
        next(err);
    }
}

module.exports = { getAll, getById, create, update, remove };