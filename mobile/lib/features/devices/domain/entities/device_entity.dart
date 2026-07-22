enum DeviceStatus { online, offline }

class DeviceEntity {
  const DeviceEntity({
    required this.id,
    required this.deviceCode,
    required this.location,
    required this.status,
    required this.registrationMode,
    required this.lastSeenAt,
    required this.firmwareVersion,
  });

  final int id;
  final String deviceCode;
  final String? location;
  final DeviceStatus status;
  final bool registrationMode;
  final DateTime? lastSeenAt;
  final String? firmwareVersion;
}