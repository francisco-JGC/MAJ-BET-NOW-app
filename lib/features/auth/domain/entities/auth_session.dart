import 'package:equatable/equatable.dart';

import 'authenticated_user.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  /// Short-lived JWT attached as `Authorization: Bearer` on every request.
  final String accessToken;

  /// Long-lived JWT used only against `POST /auth/refresh`.
  final String refreshToken;

  final AuthenticatedUser user;

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}
