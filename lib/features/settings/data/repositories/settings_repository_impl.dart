import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/billing_method.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl({required this.local});

  final SettingsLocalDatasource local;

  @override
  Future<Either<Failure, BillingMethod>> getBillingMethod() async {
    try {
      final key = await local.getBillingMethodKey();
      return Right(BillingMethod.fromKey(key));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setBillingMethod(BillingMethod method) async {
    try {
      await local.setBillingMethodKey(method.name);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
