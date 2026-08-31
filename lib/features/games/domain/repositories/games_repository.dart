import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/game.dart';

abstract interface class GamesRepository {
  Future<Either<Failure, List<Game>>> getAuthorizedGames();
}
