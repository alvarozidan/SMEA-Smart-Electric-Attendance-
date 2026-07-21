import '../entities/attendance_record.dart';
import '../entities/attendance_status.dart';
import '../entities/report_file.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceRecord>> getAll({
    required DateTime date,
    int? classId,
  });

  Future<AttendanceRecord> updateStatus(int id, AttendanceStatus status);

  Future<ReportFile> downloadReport({
    required String format,
    required DateTime startDate,
    required DateTime endDate,
    int? classId,
  });
}