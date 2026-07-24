const express = require("express");
const cors = require("cors");
const authRoutes = require("./routes/auth.routes");
const errorHandler = require("./middlewares/error.middleware");
const classesRoutes = require("./routes/classes.routes");
const studentsRoutes = require('./routes/students.routes');
const attendanceRoutes = require('./routes/attendance.routes');
const rfidRoutes = require('./routes/rfid.routes');
const devicesRoutes = require('./routes/devices.routes');
const dashboardRoutes = require('./routes/dashboard.routes');
const usersRoutes = require('./routes/users.routes');

const app = express();

app.use(cors({ origin: "*" }));
app.use(express.json());
app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/classes", classesRoutes);
app.use("/api/v1/students", studentsRoutes);
app.use("/api/v1/attendance", attendanceRoutes);
app.use("/api/v1/rfid", rfidRoutes);
app.use("/api/v1/devices", devicesRoutes);
app.use("/api/v1/dashboard", dashboardRoutes);
app.use("/api/v1/users", usersRoutes);

app.use(errorHandler);

module.exports = app;