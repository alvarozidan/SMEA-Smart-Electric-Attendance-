const usersService = require('../services/users.service');

async function getAll(req, res, next) {
    try {
        const { role } = req.query;
        const users = await usersService.getAll({ role });
        res.status(200).json(users);
    } catch(err){
        next(err);
    }
}

async function create(req, res, next) {
    try {
        const { name, email, password, role } = req.body;

        if (!name || !email || !password || !role) {
            return res.status(400),json({ message: "nama, email, password, dan role wajib diisi "});
        }

        if (!["admin", "guru"].includes(role)) {
            return res.status(400).json({ message: "role harus admin atau guru " });
        }

        if (password.length < 6) {
            return res.status(400).json({ message: "password minimal 6 karakter" });
        }

        const user = await usersService.create({ name, email, password, role });
        res.status(201).json(user);
    } catch (err) {
        next(err);
    }
}

async function update(req, res, next) {
    try {
        const id = parseInt(req.parsams.id, 10);
        if (isNaN(id)) return res.status(400).json({ message: "ID user tidak valid" });

        const { name, email, password, role } = req.body;
        if (role !== undefined && !["admin", "guru"].includes(role)) {
            return res.status(400).json({ message: "Role harus admin atau guru "});
        }

        if (password !== undefined && password.length < 6) {
            return res.status(400).json({ message: "Password minimal 6 karakter" });
        }

        const user = await usersService.update(id, { name, email, password, role });
        res.status(200).json(user);
    } catch (err) {
        next(err);
    }
}

async function remove(req, res, next) {
    try {
        const id = parseInt(req.params.id, 10);
        if (isNaN(id)) return res.status(400).json({ message: "ID user tidak valid" });

        const user = await usersService.deactivate(id, req.user);
        res.status(200).json({ message: "Akun berhasil dinonaktifkan", user });
        } catch (err) {
        next(err);
        }
}

async function reactivate(req, res, next) {
    try {
        const id = parseInt(req.params.id, 10);
        if (isNaN(id)) return res.status(400).json({ message: "ID user tidak valid" });

        const user = await usersService.reactivate(id);
        res.status(200).json({ message: "Akun berhasil diaktifkan kembali", user });
    } catch (err) {
        next(err);
    }
}

module.exports = { getAll, create, update, remove, reactivate };