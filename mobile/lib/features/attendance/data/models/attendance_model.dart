import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_status.dart';

class AttendanceModel {
  static AttendanceRecord fromJson(Map<String, dynamic> json){
    final id = json['id'] as int?;
    final studentId = json['studentId'] as int?;
    final classId = json['classId'] as int?;
    final dateRaw = json['date'] as String?;
    final statusRaw = json['status'] as String?;
    final student = json['student'] as Map<String, dynamic>?;
    final classData = json['class'] as Map<String, dynamic>?;

    if (id == null || studentId == null || classId == null || dateRaw == null || statusRaw == null) {
      throw const FormatException('Response /attendance tidak sesuai kontrak');
    }

    return AttendanceRecord(
      id: id, 
      studentId: studentId, 
      studentName: student?['name'] as String? ?? '-', 
      classId: classId, 
      className: classData?['name'] as String? ?? '-', 
      date: _dateOnly(dateRaw), 
      checkInTime: _parseNullableDateTime(json['checkInTime'] as String?), 
      status: AttendanceStatusX.fromRaw(statusRaw), 
      method: json['method'] as String?,
      );
  }

  static List<AttendanceRecord>fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static DateTime _dateOnly(String raw) {
    final parsed = DateTime.parse(raw).toUtc();
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static DateTime? _parseNullableDateTime(String? raw) {
    if (raw == null) return null;
    return DateTime.parse(raw).toLocal();
  }
}