import 'package:dio/dio.dart';

import '../../../../core/constant/api_constant.dart';

class UsersRemoteDatasource {
  UsersRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<dynamic>> getAll({ bool includeInactive = false}) async {
    final response = await _dio.get(
      ApiConstants.users,
      queryParameters:  {if (includeInactive) 'includeInactive' : 'true'},
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final response = await _dio.post(
      ApiConstants.users, data: body
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    final response = await _dio.patch(
      ApiConstants.userById(id), data: body
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deactivate(int id) async {
    final response = await _dio.delete(
      ApiConstants.userById(id)
    );
    return response.data['user'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reactivate(int id) async{
    final response = await _dio.post(
      ApiConstants.userReactivate(id)
    );
    return response.data['user'] as Map<String, dynamic>;
  }
}