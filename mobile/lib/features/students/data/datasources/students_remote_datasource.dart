import 'package:dio/dio.dart';

import '../../../../core/constant/api_constant.dart';

class StudentsRemoteDatasource {
  StudentsRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<dynamic>> getAll() async {
    final response = await _dio.get(ApiConstants.students);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.students, data: body);
    return response.data as Map<String, dynamic>;
  }

  Future <Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    final response = await _dio.put(ApiConstants.studentById(id), data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.studentById(id));
  }
}