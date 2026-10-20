import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/roulette_play.dart';
import '../../domain/repositories/roulette_repository.dart';
import '../datasources/roulette_remote_datasource.dart';

class RouletteRepositoryImpl implements RouletteRepository {
  const RouletteRepositoryImpl({required this.remote});

  final RouletteRemoteDatasource remote;

  @override
  Future<Either<Failure, RouletteConfig>> getConfig(String salePointId) async {
    try {
      return Right(await remote.getConfig(salePointId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoulettePlay>> play({
    required String salePointId,
    required List<RouletteBet> bets,
    required bool isTest,
  }) async {
    try {
      return Right(await remote.play(
        salePointId: salePointId,
        bets: bets,
        isTest: isTest,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoulettePlay>>> history({
    required String salePointId,
    int limit = 20,
  }) async {
    try {
      return Right(await remote.history(salePointId: salePointId, limit: limit));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
