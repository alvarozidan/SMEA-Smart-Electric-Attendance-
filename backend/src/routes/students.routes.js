const express = require('express');
const router = express.Router();
const authenticate = require('../middlewares/auth.middleware');
const { requireRole } = require('../middlewares/rbac.middleware');
const upload = require('../middlewares/upload.middleware');
const studentsController = require('../controllers/students.controller');

router.use(authenticate);
router.use(requireRole("admin", "guru"));

router.get("/", studentsController.getAll);
router.get("/:id", studentsController.getById);
router.post("/", studentsController.create);
router.post("/import", requireRole('admin'), upload.single('file'), studentsController.importStudents);
router.put("/:id", studentsController.update);
router.delete("/:id", studentsController.remove);

module.exports = router;