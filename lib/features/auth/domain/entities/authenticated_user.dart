import 'package:equatable/equatable.dart';

import 'user_role.dart';

class AuthenticatedUser extends Equatable {
  const AuthenticatedUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  final String id;
  final String username;
  final String name;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;
  bool get isSeller => role == UserRole.seller;

  @override
  List<Object?> get props => [id, username, name, role];
}
