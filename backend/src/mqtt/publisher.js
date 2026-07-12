const { getMqttClient } = require('./client');
const { resultTopics } = require('./topics');

function publishResult(deviceCode, result){
    const client = getMqttClient();
    client.publish(resultTopics(deviceCode), JSON.stringify(result));
}

module.exports = { publishResult };