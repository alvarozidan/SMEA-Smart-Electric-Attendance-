import 'package:flutter/widgets.dart';

import '../entities/managed_user_entity.dart';

abstract class UserManagementRepository {
  Future<List<ManagedUserEntity>> getAll({ bool includeInActive });

  Future<ManagedUserEntity> create({
    required String name,
    required String email,
    required String password,
    required String role,
  });

  Future<ManagedUserEntity> update(
    int id, {
      String? name,
      String? email,
      String? password,
      String? role,
  });

  Future<ManagedUserEntity> deactivate(int id);
  Future<ManagedUserEntity> reactivate(int id);
}