import 'package:dio/dio.dart';

import '../../../../core/constant/api_constant.dart';

class ClasessRemoteDatasource {
  ClasessRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<dynamic>> getAll() async {
    final response = await _dio.get(ApiConstants.classes);
    return response.data as List<dynamic>;
  }
}