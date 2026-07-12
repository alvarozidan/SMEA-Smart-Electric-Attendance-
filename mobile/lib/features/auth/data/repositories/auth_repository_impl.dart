import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDatasource remoteDatasource,
    required SecureStorageService storage,
  }) : _remote = remoteDatasource,
       _storage = storage;
  
  final AuthRemoteDatasource _remote;
  final SecureStorageService _storage;

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    final result = await _remote.login(email: email, password: password);

    await _storage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken 
      );

      return _decodeUser(result.accessToken);
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();

    try {
      if(refreshToken != null){
        await _remote.logout(refreshToken: refreshToken);
      }
    } catch(_){

    } finally {
      await _storage.clearTokens();
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final accessToken = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();

    if (accessToken == null || refreshToken == null) return null;

    if (JwtDecoder.isExpired(refreshToken)){
      await _storage.clearTokens();
      return null;
    }

    try {
      return _decodeUser(accessToken);
    } catch(_){
      await _storage.clearTokens();
      return null;
    }
  }

  UserEntity _decodeUser(String accessToken){
    final payload = JwtDecoder.decode(accessToken);
    final userId = payload['userId'] as int?;
    final roleRaw = payload['role'] as String?;

    if (userId == null || roleRaw == null){
      throw const FormatException('Payload JWT tidak sesuai kontrak');
    }

    return UserEntity(userId: userId, role: UserEntity.roleFromString(roleRaw));
  }
}