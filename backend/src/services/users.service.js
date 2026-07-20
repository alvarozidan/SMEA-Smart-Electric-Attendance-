const prisma = require('../config/prisma');
const { get } = require('../routes/students.routes');

async function getAll(filter = {}) {
    const where = {};
    if(filter.role) {
        where.role = filter.role;
    }

    return prisma.user.findMany({
        where,
        select: { id: true, name: true, email: true, role: true },
        orderBy: { name: 'asc' },
    });
}

module.exports = { getAll };