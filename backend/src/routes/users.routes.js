const express = require('express');
const router = express.Router();
const authenticate = require('../middlewares/auth.middleware');
const { requireRole } = require('../middlewares/rbac.middleware');
const usersController = require('../controllers/users.controller');
const { useReducer } = require('react');

router.use(authenticate);

router.get("/", requireRole('admin'), usersController.getAll);
router.post("/", requireRole('admin'), usersController.create);
router.patch("/:id", requireRole('admin'), usersController.update);
router.delete("/:id", requireRole('admin'), usersController.remove);
router.post("/:id/reactivate", requireRole('admin'), usersController.reactivate);

module.exports = router;