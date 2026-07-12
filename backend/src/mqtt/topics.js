function scanTopics(deviceCode){
    return `smartatt/${deviceCode}/scan`;
}

function heartbeatTopics(deviceCode){
    return `smartatt/${deviceCode}/heartbeat`;
}

function syncTopics(deviceCode){
    return `smartatt/${deviceCode}/sync`;
}

function resultTopics(deviceCode){
    return `smartatt/${deviceCode}/result`;
}

const SCAN_WILDCARD = "smartatt/+/scan";
const HEARTBEAT_WILDCARD = "smartatt/+/heartbeat";
const SYNC_WILDCARD = "smartatt/+/sync";

module.exports = { scanTopics, heartbeatTopics, syncTopics, resultTopics, SCAN_WILDCARD, HEARTBEAT_WILDCARD, SYNC_WILDCARD };