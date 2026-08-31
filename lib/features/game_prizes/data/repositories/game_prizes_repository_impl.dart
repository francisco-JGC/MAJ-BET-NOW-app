import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/effective_game_prize.dart';
import '../../domain/repositories/game_prizes_repository.dart';
import '../datasources/game_prizes_remote_datasource.dart';

class GamePrizesRepositoryImpl implements GamePrizesRepository {
  const GamePrizesRepositoryImpl({required this.remote});

  final GamePrizesRemoteDatasource remote;

  @override
  Future<Either<Failure, List<EffectiveGamePrize>>> listBySalePoint(
    String salePointId,
  ) async {
    try {
      final list = await remote.listBySalePoint(salePointId);
      return Right(list);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
