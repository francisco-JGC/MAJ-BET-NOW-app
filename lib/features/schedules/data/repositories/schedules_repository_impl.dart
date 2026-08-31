import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/draw_schedule.dart';
import '../../domain/repositories/schedules_repository.dart';
import '../datasources/schedules_remote_datasource.dart';

class SchedulesRepositoryImpl implements SchedulesRepository {
  const SchedulesRepositoryImpl({required this.remote});

  final SchedulesRemoteDatasource remote;

  @override
  Future<Either<Failure, List<DrawSchedule>>> listByGame(String gameId) async {
    try {
      final items = await remote.listByGame(gameId);
      return Right(items);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
