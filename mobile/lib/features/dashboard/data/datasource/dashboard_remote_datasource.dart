import 'package:dio/dio.dart';

import '../../../../core/constant/api_constant.dart';

class DashboardRemoteDatasource {
  DashboardRemoteDatasource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getSummary() async {
    final response = await _dio.get(ApiConstants.dashboardSummary);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTrend({int days = 7}) async {
    final response = await _dio.get(
      ApiConstants.dashboardTrend,
      queryParameters: {'days': days},
    );
    return response.data as List<dynamic>;
  }
}