import '../../domain/entities/device_entity.dart';

class DeviceModel {
  static DeviceEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int?;
    final deviceCode = json['deviceCode'] as String?;
    final statusRaw = json['status'] as String?;

    if (id == null || deviceCode == null || statusRaw == null) {
      throw const FormatException('Response /devices tidak sesuai kontrak');
    }

    return DeviceEntity(
      id: id, 
      deviceCode: deviceCode, 
      location: json['location'] as String?, 
      status: statusRaw == 'online' ? DeviceStatus.online : DeviceStatus.offline, 
      registrationMode: json['registrationMode'] as bool? ?? false, 
      lastSeenAt: json['lastSeenAt'] != null ? DateTime.parse(json['lastSeenAt'] as String).toLocal() : null, 
      firmwareVersion: json['firmwareVersion'] as String?
    );
  }

  static List<DeviceEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => DeviceModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

