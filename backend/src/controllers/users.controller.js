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

module.exports = { getAll };