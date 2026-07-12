const classesService = require('../services/classes.service');

async function getAll(req, res, next){
    try {
        const classes = await classesService.getAll(req.user);
        res.status(200).json(classes);
    } catch (err){
        next(err);
    }
}

async function create(req, res, next){
    try {
        const { name, homeroomTeacherId, checkInStart, checkInDeadline } = req.body;

        if (!name || !checkInStart || !checkInDeadline){
            return res.status(400).json({ message: "name, checkInStart, dan checkInDeadline wajib diisi",
            });
        }
 

    const newClass = await classesService.create({
        name,
        homeroomTeacherId,
        checkInStart,
        checkInDeadline,
    });
    res.status(201).json(newClass);
    } catch (err){
        next(err);
    }
}

async function update(req, res, next){
    try {
        const id = parseInt(req.params.id, 10);
        if (isNaN(id)){
            return res.status(400).json({ message: "ID kelas tidak valid" });
        }
        const updated = await classesService.update(id, req.body);
        res.status(200).json(updated);
    } catch (err){
        next(err);
    }
}

module.exports = { getAll, create, update };