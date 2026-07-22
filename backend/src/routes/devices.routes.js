const express = require("express");
const router = express.Router();
const authenticate = require("../middlewares/auth.middleware");
const devicesController = require("../controllers/devices.controller");
const { requireRole } = require('../middlewares/rbac.middleware');

router.post("/heartbeat", devicesController.heartbeat); // ESP32, bukan user login
router.get("/", authenticate, requireRole('admin'), devicesController.getAll); // dashboard Admin
router.get("/:id/last-scan", authenticate, requireRole("admin"), devicesController.lastScan);

module.exports = router;