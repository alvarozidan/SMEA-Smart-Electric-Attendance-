import 'package:dio/dio.dart';

import '../../../../core/constant/api_constant.dart';

class ClasessRemoteDatasource {
  ClasessRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<dynamic>> getAll() async {
    final response = await _dio.get(ApiConstants.classes);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.classes, data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    final response = await _dio.put(ApiConstants.classById(id), data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTeacherOptions() async {
    final response = await _dio.post(ApiConstants.users, queryParameters: {'role' : 'guru'});
    return response.data as List<dynamic>;
  }
  
}
