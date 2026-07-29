enum DeviceStatus { online, offline }
enum DeviceType { absensi, perpustakaan }

class DeviceEntity {
  const DeviceEntity({
    required this.id,
    required this.deviceCode,
    required this.location,
    required this.status,
    required this.deviceType,
    required this.registrationMode,
    required this.lastSeenAt,
    required this.firmwareVersion,
  });

  final int id;
  final String deviceCode;
  final String? location;
  final DeviceStatus status;
  final DeviceType deviceType;
  final bool registrationMode;
  final DateTime? lastSeenAt;
  final String? firmwareVersion;
}