import 'attendance_status_counts.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.date,
    required this.totalStudents,
    required this.statusCounts,
    required this.notYetRecorded,
  });

  final DateTime date;
  final int totalStudents;
  final AttendanceStatusCounts statusCounts;
  final int notYetRecorded;
}