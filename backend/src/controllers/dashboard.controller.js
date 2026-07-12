const dashboardService = require('../services/dashboard.service');

async function summary(req, res, next) {
    try {
        const data = await dashboardService.getSummary(req.user);
        res.status(200).json(data);
    } catch(err){
        next(err);
    }
}

async function trend(req, res, next) {
    try {
        const data = await dashboardService.getTrend(req.query, req.user);
        res.status(200).json(data);
    } catch(err){
        next(err);
    }
}

module.exports = { summary, trend };