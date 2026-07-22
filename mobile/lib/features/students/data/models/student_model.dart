import '../../domain/entities/student_entity.dart';

class StudentModel {
  static StudentEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int?;
    final nis = json['nis'] as String?;
    final name = json['name'] as String?;

    if (id == null || nis == null || name == null) {
      throw const FormatException('Response /students tidak sesuai kontrak');
    }

    final classJson = json['class'] as Map<String, dynamic>?;
    final credentialJson = json['credential'] as Map<String, dynamic>?;

    return StudentEntity(
      id: id, 
      nis: nis, 
      name: name, 
      classId: json['classId'] as int?,
      className: classJson?['name'] as String?,
      rfidUid: credentialJson?['rfidUid'] as String?,
      fingerprintIndex: credentialJson?['fingerprintIndex'] as int?,
    );
  }

  static List<StudentEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => StudentModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}