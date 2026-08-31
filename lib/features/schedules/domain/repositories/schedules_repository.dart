import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/draw_schedule.dart';

abstract interface class SchedulesRepository {
  Future<Either<Failure, List<DrawSchedule>>> listByGame(String gameId);
}
