import '../../domain/entities/user_option.dart';

class UserOptionModel {
  static UserOption fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int?;
    final name = json['name'] as String?;
    final email = json['email'] as String?;

    if (id == null || name == null || email == null) {
      throw const FormatException('Response /users tidak sesuai kontrak');
    }

    return UserOption(id: id, name: name, email: email);
  }

  static List<UserOption> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => UserOptionModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}