import 'package:dio/dio.dart';

import '../constant/api_constant.dart';
import '../error/app_exception.dart';
import '../storage/secure_storage_service.dart';

typedef OnRefreshFailed = Future<void> Function();

class DioClient {
  DioClient({
    required SecureStorageService storage,
    this.onRefreshFailed,
  }) : _storage = storage {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
      ),
    );
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
         ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  late final Dio _dio;
  late final Dio _refreshDio;
  final SecureStorageService _storage;
  final OnRefreshFailed? onRefreshFailed;

  Future<String?>? _pendingRefresh;

  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null){
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path == ApiConstants.refresh;

    if (!isUnauthorized || isRefreshCall){
      handler.next(_translate(err));
      return;
    }

    try {
      final newAccessToken = await _refreshAccessToken();
      if (newAccessToken == null){
        await _storage.clearTokens();
        await onRefreshFailed?.call();
        handler.next(UnauthorizedAppDioException(err));
        return;
      }

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
    } catch(_){
      await _storage.clearTokens();
      await onRefreshFailed?.call();
      handler.next(UnauthorizedAppDioException(err));
    }
  }

  Future<String?> _refreshAccessToken(){
    _pendingRefresh ??= _doRefresh();
    return _pendingRefresh!.whenComplete(() => _pendingRefresh = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return null;

    final response = await _refreshDio.post(
      ApiConstants.refresh,
      data: {'refreshToken' : refreshToken},
    );

    final newAccessToken = response.data['accessToken'] as String?;
    if (newAccessToken == null) return null;

    await _storage.saveAccessToken(newAccessToken);
    return newAccessToken;
  }

  DioException _translate(DioException err){
    final code = err.response?.statusCode;
    final AppException mapped = switch (code) {
      401 => UnauthorizedException(),
      403 => ForbiddenException(),
      404 => NotFoundException(),
      409 => ConflictException(_extractMessage(err) ?? 'Data konflik'),
      null => NetworkException(),
      _ => ServerException(),
    };
    return err.copyWith(error: mapped);
  }

  String? _extractMessage(DioException err){
    final data = err.response?.data;
    if (data is Map && data['message'] is String){
      return data['message'] as String;
    }
    return null;
  }
}

class UnauthorizedAppDioException extends DioException {
  UnauthorizedAppDioException(DioException original)
    : super(
      requestOptions: original.requestOptions,
      response: original.response,
      type: original.type,
      error: UnauthorizedException(),
    );
}