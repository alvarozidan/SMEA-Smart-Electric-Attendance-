import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/users_remote_datasource.dart';
import '../../data/repositories/user_management_repository_impl.dart';
import '../../domain/entities/managed_user_entity.dart';
import '../../domain/repositories/user_management_repository.dart';

final usersremoteDatasourceProvider = Provider<UsersRemoteDatasource>((ref) {
  return UsersRemoteDatasource(ref.watch(dioProvider));
});

final userManagementRepositoryProvider = Provider<UserManagementRepository>((ref) {
  return UserManagementRepositoryImpl(ref.watch(usersremoteDatasourceProvider));
});

final includeInactiveUsersProvider = StateProvider.autoDispose<bool>((ref) => false);

final managedUsersListProvider = FutureProvider.autoDispose<List<ManagedUserEntity>>((ref) {
  final includeInactive = ref.watch(includeInactiveUsersProvider);
  return ref.watch(userManagementRepositoryProvider).getAll(includeInActive: includeInactive);
});

final userFormControllerProvider =
  AsyncNotifierProvider.autoDispose<UserFormController, void>(UserFormController.new);

class UserFormController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(userManagementRepositoryProvider).create(
        name: name, 
        email: email, 
        password: 
        password, 
        role: role
      );
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(managedUsersListProvider);
    return !result.hasError;
  }

  Future<bool> updateUser(
    int id, {
      String? name,
      String? email,
      String? password,
      String? role,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(userManagementRepositoryProvider).update(
        id,
        name : name,
        email : email,
        password : password,
        role : role,
      );
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(managedUsersListProvider);
    return !result.hasError;
  }

  Future<bool> deactivateUser(int id ) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(userManagementRepositoryProvider).deactivate(id);
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(managedUsersListProvider);
    return !result.hasError;
  }

  Future<bool> reactiveUser(int id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(userManagementRepositoryProvider).reactivate(id);
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    return !result.hasError;
  }
}