const express = require("express");
const router = express.Router();
const authenticate = require("../middlewares/auth.middleware");
const { requireRole } = require("../middlewares/rbac.middleware");
const libraryController = require("../controllers/library.controller");

router.get("/devices/:id/last-scan", authenticate, requireRole("admin"), libraryController.lastScan);
router.post("/borrow", authenticate, requireRole("admin"), libraryController.borrow);
router.post("/return", authenticate, requireRole("admin"), libraryController.returnBook);
router.get("/loans", authenticate, requireRole("admin"), libraryController.listLoans);

module.exports = router;
