const prisma = require('../config/prisma');
const { toDateOnlyWIB } = require("../utils/date.util");

async function getSummary(user){
    const classFilter = user.role === "guru" ? { homeroomTeacherId: user.id } : {};

    const totalStudents = await prisma.student.count({
        where: { isDeleted: false, class: classFilter },
    });

    const today = toDateOnlyWIB();
    const todayAttendance = await prisma.attendance.groupBy({
        by: [ "status" ],
        where: {
            date: today,
            class: classFilter,
        },
        _count: { status: true },
    });

    const statusCounts = { hadir: 0, terlambat: 0, tidak_hadir: 0, izin: 0, sakit: 0 };
    todayAttendance.forEach((row) => {
        statusCounts[row.status] = row._count.status;
    });

    const totalRecordedToday = Object.values(statusCounts).reduce((a, b) => a + b, 0);
    const notYetRecorded = totalStudents - totalRecordedToday;

    return {
        date: today.toISOString().split("T")[0],
        totalStudents,
        statusCounts,
        notYetRecorded: notYetRecorded < 0 ? 0 : notYetRecorded,
    };
}

async function getTrend(query, user){
    const days = query.days ? parseInt(query.days, 10) : 7;
    if(isNaN(days) || days < 1 || days > 90){
        throw { status: 400, message: "days harus angka antara 1 - 90" };
    }

    const today = toDateOnlyWIB()
    const startDate = new Date(today);
    startDate.setUTCDate(startDate.getUTCDate() - (days - 1));

    let rows;

    if(user.role === "guru"){
        rows = await prisma.$queryRaw`
        SELECT 
            a.date::text AS date,
            a.status,
            COUNT(*)::int AS count
            FROM attendance a
            JOIN classes c ON c.id = a.class_id
            WHERE a.date >= ${startDate}
            AND c.homeroom_teacher_id = ${user.id}
            GROUP BY a.date, a.status
            ORDER BY a.date ASC
            `;
    } else {
        rows = await prisma.$queryRaw`
        SELECT 
            a.date::text AS date,
            a.status,
            COUNT(*)::int AS count
            FROM attendance a 
            WHERE a.date >= ${startDate}
            GROUP BY a.date, a.status
            ORDER BY a.date ASC
            `;
    }

    const trendMap = {};
    rows.forEach((row) => {
        if(!trendMap[row.date]){
            trendMap[row.date] = { hadir: 0, terlambat: 0, tidak_hadir: 0, izin: 0, sakit: 0 };
        }
        trendMap[row.date][row.status] = row.count;
    });

    return Object.entries(trendMap).map(([date, statusCounts]) => ({ date, statusCounts }));
}

module.exports = { getSummary, getTrend };