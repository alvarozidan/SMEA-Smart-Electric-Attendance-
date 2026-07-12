enum UserRole { admin, guru, orangTua }

class UserEntity {
  const UserEntity({required this.userId, required this.role});

  final int userId;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;
  bool get isGuru => role == UserRole.guru;

  static UserRole roleFromString(String raw){
    switch(raw) {
      case 'admin':
        return UserRole.admin;
      case 'guru':
        return UserRole.guru;
      case 'orang_tua':
        return UserRole.orangTua;
      default:
        throw FormatException('Role tidak dikenali: $raw');
    }
  }
}