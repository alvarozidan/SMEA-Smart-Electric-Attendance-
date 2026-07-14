import 'attendance_status_counts.dart';

class TrendPoint {
  const TrendPoint({
    required this.date,
    required this.statusCounts
  });

  final DateTime date;
  final AttendanceStatusCounts statusCounts;
}