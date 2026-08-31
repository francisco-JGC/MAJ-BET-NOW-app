import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/ticket_detail.dart';
import '../../domain/repositories/tickets_repository.dart';

final ticketDetailProvider =
    FutureProvider.family.autoDispose<TicketDetail, String>((ref, id) async {
  final repo = getIt<TicketsRepository>();
  final result = await repo.findById(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (detail) => detail,
  );
});
