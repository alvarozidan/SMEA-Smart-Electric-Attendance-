const express = require("express");
const router = express.Router();
const authenticate = require("../middlewares/auth.middleware");
const devicesController = require("../controllers/devices.controller");

router.post("/heartbeat", devicesController.heartbeat); // ESP32, bukan user login
router.get("/", authenticate, devicesController.getAll); // dashboard Admin/Guru

module.exports = router;