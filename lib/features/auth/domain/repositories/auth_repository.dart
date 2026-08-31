import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, AuthSession>> login({
    required String username,
    required String password,
  });

  Future<Either<Failure, AuthSession?>> loadSession();

  Future<Either<Failure, Unit>> logout();
}
