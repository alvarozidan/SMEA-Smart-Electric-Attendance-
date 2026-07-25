import '../../domain/entities/managed_user_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';

class ManagedUserModel {
  static ManagedUserEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int?;
    final name = json['name'] as String?;
    final email = json['email'] as String?;
    final roleRaw = json['role'] as String?;

    if (id == null || name == null || email == null || roleRaw == null) {
      throw const FormatException('Response /users tidak sesuai kontrak');
    }

    return ManagedUserEntity(
      id: id, 
      name: name, 
      email: email, 
      role: UserEntity.roleFromString(roleRaw), 
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static List<ManagedUserEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => ManagedUserModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}