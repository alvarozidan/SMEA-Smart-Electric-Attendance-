const express = require('express');
const router = express.Router();
const authenticate = require('../middlewares/auth.middleware');
const { requireRole } = require('../middlewares/rbac.middleware');
const dashboardController = require('../controllers/dashboard.controller');

router.use(authenticate);
router.use(requireRole("admin", "guru"));

router.get("/summary", dashboardController.summary);
router.get("/trend", dashboardController.trend);

module.exports = router;