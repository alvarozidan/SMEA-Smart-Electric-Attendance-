import '../../domain/entities/class_entity.dart';

class ClassModel {
  static ClassEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int?;
    final name = json['name'] as String?;

    if (id == null || name == null) {
      throw const FormatException('Response /classes tidak sesuai kontrak');
    }

    return ClassEntity(
      id: id, 
      name: name,
      homeroomTeacherId: json['homeroomTeacherId'] as int?,
      checkInStart: _extractTime(json['checkInStart']),
      checkInDeadline: _extractTime(json['checkInDeadline']),
      );
  }

  static List<ClassEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => ClassModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String? _extractTime(dynamic raw) {
    if (raw is! String) return null;
    try {
      final parsed = DateTime.parse(raw).toUtc();
      final hh = parsed.hour.toString().padLeft(2, '0');
      final mm = parsed.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } catch(_) {
      return null;
    }
  }
}