const express = require("express");
const router = express.Router();
const authenticate = require("../middlewares/auth.middleware");
const authController = require("../controllers/auth.controller");

router.post("/login", authController.login);
router.post("/login-siswa", authController.loginStudent);
router.post("/change-password", authenticate, authController.changePassword);
router.post("/refresh", authController.refresh);
router.post("/logout", authController.logout);

module.exports = router;