import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ticket_summary.dart';
import '../repositories/tickets_repository.dart';

class VoidMyTicketParams {
  const VoidMyTicketParams({required this.id, required this.reason});

  final String id;
  final String reason;
}

class VoidMyTicket {
  const VoidMyTicket({required this.repository});

  final TicketsRepository repository;

  Future<Either<Failure, TicketSummary>> call(VoidMyTicketParams params) {
    return repository.voidTicket(id: params.id, reason: params.reason);
  }
}
