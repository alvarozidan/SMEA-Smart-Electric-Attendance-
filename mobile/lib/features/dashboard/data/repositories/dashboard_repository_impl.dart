import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/trend_point.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasource/dashboard_remote_datasource.dart';
import '../models/dashboard_summary_model.dart';
import '../models/trend_point_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._remote);

  final DashboardRemoteDatasource _remote;

  @override
  Future<DashboardSummary> getSummary() async {
    final json = await _remote.getSummary();
    return DashboardSummaryModel.fromJson(json);
  }

  @override
  Future<List<TrendPoint>> getTrend({int days = 7}) async {
    final jsonList = await _remote.getTrend(days: days);
    return TrendPointModel.fromJsonList(jsonList);
  }
}