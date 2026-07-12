const mqtt = require("mqtt");
const env = require('../config/env');

let client = null;

function getMqttClient(){
    if(client) return client;

    client = mqtt.connect(env.mqtt.url, {
        username: env.mqtt.username || undefined,
        password: env.mqtt.password || undefined,
        reconnectPeriod: 5000,
    });

    client.on("connect", () => {
        console.log(`[MQTT] Terhubung ke broker: ${env.mqtt.url}`);
    });
    client.on("error", (err) => {
        console.error("[MQTT] Error koneksi: ", err.message);
    });
    client.on("reconnect", () => {
        console.log("[MQTT] Mencoba reconnect ke broker...");
    });

    return client;
}

module.exports = { getMqttClient };