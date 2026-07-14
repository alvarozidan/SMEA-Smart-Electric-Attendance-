import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../data/datasource/dashboard_remote_datasource.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/trend_point.dart';
import '../../domain/repositories/dashboard_repository.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDatasource>((ref) {
  return DashboardRemoteDatasource(ref.watch(dioProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});

final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).getSummary();
});

final dashboardTrendProvider = FutureProvider.autoDispose<List<TrendPoint>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getTrend();
});