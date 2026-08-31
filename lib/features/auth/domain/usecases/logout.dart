import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class Logout {
  const Logout({required this.repository});

  final AuthRepository repository;

  Future<Either<Failure, Unit>> call() {
    return repository.logout();
  }
}
