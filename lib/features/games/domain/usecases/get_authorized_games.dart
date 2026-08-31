import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/game.dart';
import '../repositories/games_repository.dart';

class GetAuthorizedGames {
  const GetAuthorizedGames({required this.repository});

  final GamesRepository repository;

  Future<Either<Failure, List<Game>>> call() {
    return repository.getAuthorizedGames();
  }
}
