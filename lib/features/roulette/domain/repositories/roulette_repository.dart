import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/roulette_play.dart';

abstract interface class RouletteRepository {
  Future<Either<Failure, RouletteConfig>> getConfig(String salePointId);

  Future<Either<Failure, RoulettePlay>> play({
    required String salePointId,
    required List<String> numbers,
    required int amountPerNumber,
    required bool isTest,
  });

  Future<Either<Failure, List<RoulettePlay>>> history({
    required String salePointId,
    int limit,
  });
}
