import 'package:dio/dio.dart';

import '../../../../core/constant/api_constant.dart';

class AttendanceRemoteDatasource {
  AttendanceRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<dynamic>> getAll(Map<String, dynamic> queryParameters) async {
    final response = await _dio.get(
      ApiConstants.attendance,
      queryParameters: queryParameters,
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> updateStatus(int id, String status) async {
    final response = await _dio.patch(
      ApiConstants.attendanceById(id),
      data: {'status': status},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<int>> downloadReport(Map<String, dynamic> queryParameters) async {
    final response = await _dio.get(
      ApiConstants.attendanceReport,
      queryParameters: queryParameters,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as List<int>;
  }
}