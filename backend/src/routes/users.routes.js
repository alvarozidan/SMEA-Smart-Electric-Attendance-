const express = require('express');
const router = express.Router();
const authenticate = require('../middlewares/auth.middleware');
const { requireRole } = require('../middlewares/rbac.middleware');
const usersController = require('../controllers/users.controller');

router.use(authenticate);

router.get("/", requireRole('admin'), usersController.getAll);

module.exports = router;