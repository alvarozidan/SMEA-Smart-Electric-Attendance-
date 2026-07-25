import '../../../auth/domain/entities/user_entity.dart';

class ManagedUserEntity {
  const ManagedUserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });

  final int id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;

}