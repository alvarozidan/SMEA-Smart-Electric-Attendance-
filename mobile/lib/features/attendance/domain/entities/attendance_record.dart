import 'attendance_status.dart';

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.date,
    required this.checkInTime,
    required this.status,
    required this.method,
  });

  final int id;
  final int studentId;
  final String studentName;
  final int classId;
  final String className;
  final DateTime date;
  final DateTime? checkInTime;
  final AttendanceStatus status;
  final String? method;
}