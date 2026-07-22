import 'package:dio/dio.dart';

import '../../../../core/constant/api_constant.dart';

class DeviceRemoteDatasource {
  DeviceRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<dynamic>> getAll() async {
    final response = await _dio.get(ApiConstants.devices);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> toggleRegistrationMode(int deviceId, bool enabled) async {
    final response = await _dio.post(
      ApiConstants.rfidModeRegister,
      data: {'deviceId': deviceId, 'enabled': enabled},
    );
    return response.data as Map<String, dynamic>;
  }
}