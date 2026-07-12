const express = require("express");
const router = express.Router();
const authenticate = require('../middlewares/auth.middleware');
const { requireRole } = require('../middlewares/rbac.middleware');
const rfidController = require('../controllers/rfid.controller');

router.use(authenticate);

router.post("/register", rfidController.register);
router.delete("/:uid", rfidController.unbind);
router.post("/mode/register", requireRole("admin"), rfidController.toggleRegistrationMode);

module.exports = router;
