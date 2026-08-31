import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/effective_game_prize.dart';

abstract interface class GamePrizesRepository {
  Future<Either<Failure, List<EffectiveGamePrize>>> listBySalePoint(
    String salePointId,
  );
}
