import 'package:dio/dio.dart';

import '../../../../core/constant/api_constant.dart';
import '../models/auth_response_model.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._dio);

  final Dio _dio;

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'email' : email, 'password' : password},
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout({required String refreshToken}) async {
    await _dio.post(
      ApiConstants.logout,
      data: {'refreshToken' : refreshToken},
    );
  }
}