const express = require("express");
const router = express.Router();
const authenticate = require("../middlewares/auth.middleware");
const { requireRole } = require("../middlewares/rbac.middleware");
const classesController = require("../controllers/classes.controller");

router.use(authenticate);

router.get("/", classesController.getAll);
router.post("/", requireRole("admin"), classesController.create);
router.put("/:id", requireRole("admin"), classesController.update);

module.exports = router;