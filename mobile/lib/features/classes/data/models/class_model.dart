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
      );
  }

  static List<ClassEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => ClassModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}