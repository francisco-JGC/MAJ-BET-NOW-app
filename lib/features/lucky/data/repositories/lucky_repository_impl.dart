import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/lucky_daily.dart';
import '../../domain/repositories/lucky_repository.dart';
import '../datasources/lucky_remote_datasource.dart';

class LuckyRepositoryImpl implements LuckyRepository {
  const LuckyRepositoryImpl({required this.remote});

  final LuckyRemoteDatasource remote;

  @override
  Future<Either<Failure, LuckyDaily?>> findForDate({
    required LuckyKind kind,
    required DateTime date,
  }) async {
    try {
      return Right(await remote.findForDate(kind, date));
    } on NotFoundException {
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LuckyDaily>>> history({
    required LuckyKind kind,
    int limit = 30,
  }) {
    return _guard(() => remote.history(kind, limit));
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
