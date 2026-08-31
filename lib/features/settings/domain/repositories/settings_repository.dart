import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/billing_method.dart';

abstract interface class SettingsRepository {
  Future<Either<Failure, BillingMethod>> getBillingMethod();
  Future<Either<Failure, Unit>> setBillingMethod(BillingMethod method);
}
