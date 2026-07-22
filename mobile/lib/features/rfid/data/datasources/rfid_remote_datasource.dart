import 'package:dio/dio.dart';

import '../../../../core/constant/api_constant.dart';

class RfidRemoteDatasource {
  RfidRemoteDatasource(this._dio);

  final Dio _dio;

  Future<void> register(Map<String, dynamic> body) async {
    await _dio.post(ApiConstants.rfidRegister, data: body);
  }

  Future<void> unbindRfid(String rfidUid) async {
    await _dio.delete(ApiConstants.rfidUnbind(rfidUid));
  }
}