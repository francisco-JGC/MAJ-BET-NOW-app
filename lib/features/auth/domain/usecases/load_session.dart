import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class LoadSession {
  const LoadSession({required this.repository});

  final AuthRepository repository;

  Future<Either<Failure, AuthSession?>> call() {
    return repository.loadSession();
  }
}
