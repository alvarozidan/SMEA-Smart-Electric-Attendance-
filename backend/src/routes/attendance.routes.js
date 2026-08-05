const express = require('express');
const router = express.Router();
const authenticate = require('../middlewares/auth.middleware');
const { requireRole } = require('../middlewares/rbac.middleware');
const attendanceController = require('../controllers/attendance.controller');

router.use(authenticate);
router.use(requireRole("admin", "guru"));

router.get("/report", attendanceController.report);
router.get("/", attendanceController.getAll);
router.patch("/:id", attendanceController.manualUpdate);

module.exports = router;