import 'package:flutter_test/flutter_test.dart';
import 'package:majbetnow_app/features/games/data/datasources/games_local_datasource.dart';
import 'package:majbetnow_app/features/games/data/datasources/games_remote_datasource.dart';
import 'package:majbetnow_app/features/games/data/models/game_model.dart';
import 'package:majbetnow_app/features/games/data/repositories/games_repository_impl.dart';
import 'package:majbetnow_app/features/games/domain/entities/game_type.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements GamesRemoteDatasource {}

class _MockLocal extends Mock implements GamesLocalDatasource {}

const _sample = GameModel(
  id: 'uuid-1',
  slug: 'diaria',
  name: 'Diaria',
  type: GameType.regular,
  exactMultiplier: 80,
  orderIndex: 1,
);

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late GamesRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    repository = GamesRepositoryImpl(remote: remote, local: local);
  });

  test('remote success writes cache and returns sorted games', () async {
    when(() => remote.fetchGames()).thenAnswer((_) async => const [_sample]);
    when(() => local.writeCache(any())).thenAnswer((_) async {});

    final result = await repository.getAuthorizedGames();

    expect(result.isRight(), isTrue);
    result.match(
      (_) => fail('expected Right'),
      (games) => expect(games.map((g) => g.slug), ['diaria']),
    );
    verify(() => local.writeCache(any())).called(1);
  });

  test('remote failure falls back to cache when available', () async {
    when(() => remote.fetchGames()).thenThrow(Exception('offline'));
    when(() => local.readCached()).thenAnswer((_) async => const [_sample]);

    final result = await repository.getAuthorizedGames();

    expect(result.isRight(), isTrue);
    result.match(
      (_) => fail('expected Right'),
      (games) => expect(games.length, 1),
    );
    verifyNever(() => local.readFallback());
  });

  test('remote and cache empty falls back to static list', () async {
    when(() => remote.fetchGames()).thenThrow(Exception('offline'));
    when(() => local.readCached()).thenAnswer((_) async => const []);
    when(() => local.readFallback()).thenAnswer((_) async => const [_sample]);

    final result = await repository.getAuthorizedGames();

    expect(result.isRight(), isTrue);
    result.match(
      (_) => fail('expected Right'),
      (games) => expect(games.map((g) => g.slug), ['diaria']),
    );
  });
}
