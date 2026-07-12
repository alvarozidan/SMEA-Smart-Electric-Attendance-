import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
  : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  Future<void> saveAccessToken(String token) => 
    _storage.write(key: _keyAccessToken, value: token);

  Future<void> saveRefreshToken(String token) => 
    _storage.write(key: _keyRefreshToken, value: token);

    Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);
    Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

    Future<void> saveTokens({
      required String accessToken,
      required String refreshToken,
    }) async {
      await saveAccessToken(accessToken);
      await saveRefreshToken(refreshToken);
    }

    Future<void> clearTokens() async {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
    }
}