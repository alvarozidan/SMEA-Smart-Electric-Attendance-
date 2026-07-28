const express = require("express");
const router = express.Router();
const authenticate = require('../middlewares/auth.middleware');
const { requireRole } = require('../middlewares/rbac.middleware');
const bookController = require('../controllers/book.controller');

router.use(authenticate);

router.get("/", bookController.getAll);
router.get(":id", bookController.getById);
router.post("/", requireRole("admin"), bookController.create);
router.put("/:id", requireRole("admin"), bookController.update);
router.delete("/:id", requireRole("admin"), bookController.remove);

module.exports = router;