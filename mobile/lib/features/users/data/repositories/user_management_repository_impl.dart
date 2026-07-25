import '../../domain/entities/managed_user_entity.dart';
import '../../domain/repositories/user_management_repository.dart';
import '../../data/datasources/users_remote_datasource.dart';
import '../models/managed_user_model.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  UserManagementRepositoryImpl(this._remote);

  final UsersRemoteDatasource _remote;

  @override
  Future<List<ManagedUserEntity>> getAll({ bool includeInActive = false }) async {
    final jsonList = await _remote.getAll(includeInactive: includeInActive);
    return ManagedUserModel.fromJsonList(jsonList);
  }

  @override
  Future<ManagedUserEntity> create({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final json = await _remote.create({
      'name' : name,
      'email' : email,
      'password' : password,
      'role' : role,
    });
    return ManagedUserModel.fromJson(json);
  }

  @override
  Future<ManagedUserEntity> update(
    int id, {
      String? name,
      String? email,
      String? password,
      String? role,
  }) async {
    final json = await _remote.update(
      id, {
        if (name != null) 'name' : name,
        if (email != null) 'email' : email,
        if (password != null && password.isNotEmpty) 'password' : password,
        if (role != null) 'role' : role,
    });
    return ManagedUserModel.fromJson(json);
  }

  @override
  Future<ManagedUserEntity> deactivate(int id) async {
    final json = await _remote.deactivate(id);
    return ManagedUserModel.fromJson(json);
  }

  @override
  Future<ManagedUserEntity> reactivate(int id) async {
    final json = await _remote.reactivate(id);
    return ManagedUserModel.fromJson(json);
  }
}