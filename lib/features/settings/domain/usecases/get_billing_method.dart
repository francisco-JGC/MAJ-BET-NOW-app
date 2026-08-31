import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/billing_method.dart';
import '../repositories/settings_repository.dart';

class GetBillingMethod {
  const GetBillingMethod({required this.repository});

  final SettingsRepository repository;

  Future<Either<Failure, BillingMethod>> call() {
    return repository.getBillingMethod();
  }
}
