import '../../domain/entities/authenticated_user.dart';
import '../../domain/entities/user_role.dart';

class AuthenticatedUserModel extends AuthenticatedUser {
  const AuthenticatedUserModel({
    required super.id,
    required super.username,
    required super.name,
    required super.role,
  });

  factory AuthenticatedUserModel.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      role: UserRole.fromKey(json['role'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'role': role.name,
      };
}
