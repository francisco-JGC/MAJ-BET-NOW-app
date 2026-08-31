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

  @override
  Future<Either<Failure, List<Game>>> getAuthorizedGames() async {
    try {
      final fresh = await remote.fetchGames();
      await local.writeCache(fresh);
      return Right(_sorted(fresh));
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
      if (cached.isNotEmpty) return Right(_sorted(cached));
      final fallback = await local.readFallback();
      return Right(_sorted(fallback));
    } catch (_) {
      return onEmpty;
    }
  }

  List<Game> _sorted(List<Game> games) {
    return [...games]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
}
