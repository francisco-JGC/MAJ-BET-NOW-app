import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/game.dart';
import '../../domain/repositories/games_repository.dart';
import '../datasources/games_local_datasource.dart';
import '../datasources/games_remote_datasource.dart';

class GamesRepositoryImpl implements GamesRepository {
  const GamesRepositoryImpl({required this.remote, required this.local});

  final GamesRemoteDatasource remote;
  final GamesLocalDatasource local;

  static const _localImages = <String, String>{
    'diaria':       'assets/images/games/diaria.webp',
    'juega3':       'assets/images/games/juega3.webp',
    'fechas':       'assets/images/games/fechas.webp',
    'combo':        'assets/images/games/combo.webp',
    'terminacion2': 'assets/images/games/terminacion2.webp',
    'tica':         'assets/images/games/tica.webp',
    'tresmonazo':   'assets/images/games/tresmonazo.webp',
    'hondurena':    'assets/images/games/hondurena.webp',
    'gana3':        'assets/images/games/gana3.webp',
    'primera':      'assets/images/games/primera.webp',
    'salvadorena':  'assets/images/games/salvadorena.webp',
    'juga4':        'assets/images/games/juga4.webp',
    'multisorteo':  'assets/images/games/multisorteo.webp',
  };

  @override
  Future<Either<Failure, List<Game>>> getAuthorizedGames() async {
    try {
      final fresh = await remote.fetchGames();
      await local.writeCache(fresh);
      return Right(_sorted(_withLocalImages(fresh)));
    } on ServerException catch (e) {
      return _fromCacheOr(Left(ServerFailure(e.message)));
    } on NetworkException catch (e) {
      return _fromCacheOr(Left(NetworkFailure(e.message)));
    } catch (e) {
      return _fromCacheOr(Left(UnexpectedFailure(e.toString())));
    }
  }

  Future<Either<Failure, List<Game>>> _fromCacheOr(
    Left<Failure, List<Game>> onEmpty,
  ) async {
    try {
      final cached = await local.readCached();
      if (cached.isNotEmpty) return Right(_sorted(_withLocalImages(cached)));
      final fallback = await local.readFallback();
      return Right(_sorted(fallback));
    } catch (_) {
      return onEmpty;
    }
  }

  List<Game> _withLocalImages(List<Game> games) {
    return games.map((g) {
      final localPath = _localImages[g.slug];
      if (localPath == null || g.imagePath != null) return g;
      return Game(
        id: g.id,
        slug: g.slug,
        name: g.name,
        type: g.type,
        exactMultiplier: g.exactMultiplier,
        easyMultiplier: g.easyMultiplier,
        pairEasyMultiplier: g.pairEasyMultiplier,
        imagePath: localPath,
        orderIndex: g.orderIndex,
        isActive: g.isActive,
      );
    }).toList();
  }

  List<Game> _sorted(List<Game> games) {
    return [...games]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
}
