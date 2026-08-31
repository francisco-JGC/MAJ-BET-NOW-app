import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/draw_result.dart';
import '../../domain/entities/ticket_evaluation.dart';
import '../../domain/entities/winning_ticket.dart';
import '../../domain/repositories/results_repository.dart';
import '../datasources/results_remote_datasource.dart';

class ResultsRepositoryImpl implements ResultsRepository {
  const ResultsRepositoryImpl({required this.remote});

  final ResultsRemoteDatasource remote;

  @override
  Future<Either<Failure, List<DrawResult>>> listResults(
    ListDrawResultsQuery query,
  ) {
    return _guard(() => remote.listResults(query));
  }

  @override
  Future<Either<Failure, List<WinningTicket>>> listWinners(
    ListWinnersQuery query,
  ) {
    return _guard(() => remote.listWinners(query));
  }

  @override
  Future<Either<Failure, TicketEvaluation>> evaluateTicket(String ticketId) {
    return _guard(() => remote.evaluateTicket(ticketId));
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
