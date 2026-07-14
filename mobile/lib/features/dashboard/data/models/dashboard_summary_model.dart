import '../../domain/entities/attendance_status_counts.dart';
import '../../domain/entities/dashboard_summary.dart';

class DashboardSummaryModel {
  static DashboardSummary fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date'] as String?;
    final totalStudents = json['totalStudents'] as int?;
    final notYetRecorded = json['notYetRecorded'] as int?;
    final statusCountsRaw = json['statusCounts'] as Map<String, dynamic>?;

    if (dateRaw == null || totalStudents == null || statusCountsRaw == null) {
      throw const FormatException(
        'Response /dashboard/summary tidak sesuai kontrak',
      );
    }

    return DashboardSummary(
      date: DateTime.parse(dateRaw), 
      totalStudents: totalStudents, 
      notYetRecorded: notYetRecorded ?? 0,
      statusCounts: AttendanceStatusCounts.fromJson(statusCountsRaw),
      );
  }
}