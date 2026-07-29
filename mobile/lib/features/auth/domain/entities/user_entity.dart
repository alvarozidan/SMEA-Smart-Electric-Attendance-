enum UserRole { admin, guru, pustakawan, orangTua }

class UserEntity {
  const UserEntity({required this.userId, required this.role});

  final int userId;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;
  bool get isGuru => role == UserRole.guru;
  bool get isPustakawan => role == UserRole.pustakawan;

  static UserRole roleFromString(String raw){
    switch(raw) {
      case 'admin':
        return UserRole.admin;
      case 'guru':
        return UserRole.guru;
      case 'pustakawan':
        return UserRole.pustakawan;
      case 'orang_tua':
        return UserRole.orangTua;
      default:
        throw FormatException('Role tidak dikenali: $raw');
    }
  }
}