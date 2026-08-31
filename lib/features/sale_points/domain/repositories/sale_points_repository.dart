import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/sale_point.dart';

abstract interface class SalePointsRepository {
  Future<Either<Failure, List<SalePoint>>> fetchMine();
  Future<String?> readSelectedId();
  Future<void> saveSelectedId(String id);
  Future<void> clearSelectedId();
}
