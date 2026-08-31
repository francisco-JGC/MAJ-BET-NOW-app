import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:majbetnow_app/core/errors/failures.dart';
import 'package:majbetnow_app/features/games/domain/entities/game.dart';
import 'package:majbetnow_app/features/games/domain/entities/game_type.dart';
import 'package:majbetnow_app/features/games/domain/repositories/games_repository.dart';
import 'package:majbetnow_app/features/games/domain/usecases/get_authorized_games.dart';
import 'package:mocktail/mocktail.dart';

class _MockGamesRepository extends Mock implements GamesRepository {}

void main() {
  late _MockGamesRepository repository;
  late GetAuthorizedGames usecase;

  setUp(() {
    repository = _MockGamesRepository();
    usecase = GetAuthorizedGames(repository: repository);
  });

  test('returns games from repository when it succeeds', () async {
    const games = [
      Game(
        id: 'uuid-1',
        slug: 'diaria',
        name: 'Diaria',
        type: GameType.regular,
        exactMultiplier: 80,
      ),
    ];
    when(() => repository.getAuthorizedGames())
        .thenAnswer((_) async => const Right(games));

    final result = await usecase();

    expect(result, const Right<Failure, List<Game>>(games));
    verify(() => repository.getAuthorizedGames()).called(1);
  });

  test('returns failure when repository fails', () async {
    const failure = UnexpectedFailure('boom');
    when(() => repository.getAuthorizedGames())
        .thenAnswer((_) async => const Left(failure));

    final result = await usecase();

    expect(result, const Left<Failure, List<Game>>(failure));
  });
}
