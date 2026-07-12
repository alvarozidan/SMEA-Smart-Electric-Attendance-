const app = require("./src/app");
const env = require("./src/config/env");
const { startMqttSubscriber } = require("./src/mqtt");

app.listen(env.port, () => {
    console.log(`Server jalan di port ${env.port}`);
    startMqttSubscriber();
});