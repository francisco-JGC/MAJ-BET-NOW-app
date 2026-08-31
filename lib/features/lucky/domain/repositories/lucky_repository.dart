import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/lucky_daily.dart';

abstract interface class LuckyRepository {
  /// Returns [Right(null)] when there is no entry for the given date.
  Future<Either<Failure, LuckyDaily?>> findForDate({
    required LuckyKind kind,
    required DateTime date,
  });

  Future<Either<Failure, List<LuckyDaily>>> history({
    required LuckyKind kind,
    int limit = 30,
  });
}
