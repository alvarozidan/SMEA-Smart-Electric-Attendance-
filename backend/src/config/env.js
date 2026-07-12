require("dotenv").config();

module.exports = {
    port: process.env.PORT || 3000,
    databaseUrl: process.env.DATABASE_URL,
    jwt: {
        accessSecret: process.env.JWT_ACCESS_SECRET,
        refreshSecret: process.env.JWT_REFRESH_SECRET,
        accessExpiry: "1h",
        refreshExpiry: "7d",
    },
    deviceApiKey: process.env.DEVICE_API_KEY,
    mqtt: {
        url: process.env.MQTT_BROKER_URL || "mqtt://localhost:1883",
        username: process.env.MQTT_USERNAME,
        password: process.env.MQTT_PASSWORD,
    },
};