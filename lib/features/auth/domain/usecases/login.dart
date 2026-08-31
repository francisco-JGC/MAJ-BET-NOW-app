import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  const LoginParams({required this.username, required this.password});

  final String username;
  final String password;
}

class Login {
  const Login({required this.repository});

  final AuthRepository repository;

  Future<Either<Failure, AuthSession>> call(LoginParams params) {
    return repository.login(
      username: params.username,
      password: params.password,
    );
  }
}
