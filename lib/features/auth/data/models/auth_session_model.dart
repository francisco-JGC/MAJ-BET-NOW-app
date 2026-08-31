import '../../domain/entities/auth_session.dart';
import 'authenticated_user_model.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.accessToken,
    required super.refreshToken,
    required AuthenticatedUserModel super.user,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      accessToken: json['accessToken'] as String,
      // Legacy sessions saved before refresh tokens existed have no
      // refreshToken key — treat as empty so the interceptor falls through
      // to a hard logout on the next 401 instead of crashing on the cast.
      refreshToken: json['refreshToken'] as String? ?? '',
      user: AuthenticatedUserModel.fromJson(
        json['user'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'user': (user as AuthenticatedUserModel).toJson(),
      };
}
