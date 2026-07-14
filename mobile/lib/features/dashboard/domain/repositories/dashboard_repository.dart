import '../entities/dashboard_summary.dart';
import '../entities/trend_point.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> getSummary();
  Future<List<TrendPoint>> getTrend({int days = 7});
}