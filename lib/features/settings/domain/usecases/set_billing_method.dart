import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/billing_method.dart';
import '../repositories/settings_repository.dart';

class SetBillingMethod {
  const SetBillingMethod({required this.repository});

  final SettingsRepository repository;

  Future<Either<Failure, Unit>> call(BillingMethod method) {
    return repository.setBillingMethod(method);
  }
}
