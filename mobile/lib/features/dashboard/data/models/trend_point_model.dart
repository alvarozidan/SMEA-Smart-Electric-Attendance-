import '../../domain/entities/attendance_status_counts.dart';
import '../../domain/entities/trend_point.dart';

class TrendPointModel {
  static TrendPoint fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date'] as String?;
    final statusCountsRaw = json['statusCounts'] as Map<String, dynamic>?;

    if (dateRaw == null || statusCountsRaw == null) {
      throw const FormatException(
        'Response /dashboard/trend tidak sesuai kontrak',
      );
    }

    return TrendPoint(
      date: DateTime.parse(dateRaw),
      statusCounts: AttendanceStatusCounts.fromJson(statusCountsRaw),
       );
  }

  static List<TrendPoint> fromJsonList(List<dynamic> jsonList) {
    return jsonList
      .map((e) => TrendPointModel.fromJson(e as Map<String, dynamic>))
      .toList();
  }
}