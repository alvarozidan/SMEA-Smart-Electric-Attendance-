const express = require("express");
const router = express.Router();
const authenticate = require("../middlewares/auth.middleware");
const { requireRole } = require("../middlewares/rbac.middleware");
const libraryController = require("../controllers/library.controller");

router.get("/devices/:id/last-scan", authenticate, requireRole("admin", "pustakawan"), libraryController.lastScan);
router.post("/borrow", authenticate, requireRole("admin", "pustakawan"), libraryController.borrow);
router.post("/return", authenticate, requireRole("admin", "pustakawan"), libraryController.returnBook);
router.post("/extend", authenticate, requireRole("admin", "pustakawan"), libraryController.extend);
router.get("/loans", authenticate, requireRole("admin", "pustakawan"), libraryController.listLoans);

module.exports = router;
