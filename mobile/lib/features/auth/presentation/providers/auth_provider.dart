import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_datasource.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

final SecureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(SecureStorageProvider);
  return DioClient(
    storage: storage,
    onRefreshFailed: () async {
      ref.invalidate(authNotifierProvider);
    },
    );
});

final dioProvider = Provider((ref) => ref.watch(dioClientProvider).dio);

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDatasource: ref.watch(authRemoteDatasourceProvider),
    storage: ref.watch(SecureStorageProvider),
     );
});

final loginUsecaseProvider = Provider((ref) {
  return LoginUsecase(ref.watch(authRepositoryProvider));
});

final logoutUsecaseProvider = Provider((ref) {
  return LogoutUsecase(ref.watch(authRepositoryProvider));
});

final authNotifierProvider =
  AsyncNotifierProvider<AuthNotifier, UserEntity?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<UserEntity?> {
  @override
  Future<UserEntity?> build() async {
    final repository = ref.watch(authRepositoryProvider);
    return repository.getCurrentUser();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    final usecase = ref.read(loginUsecaseProvider);
    state = await AsyncValue.guard(() => usecase(email: email, password: password));
  }

  Future<void> logout() async {
    final usecase = ref.read(logoutUsecaseProvider);
    await usecase();
    state = const AsyncData(null);
  }
}