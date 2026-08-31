import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/create_ticket_request.dart';
import '../entities/ticket_receipt.dart';
import '../repositories/tickets_repository.dart';

class CreateTicket {
  const CreateTicket({required this.repository});

  final TicketsRepository repository;

  Future<Either<Failure, TicketReceipt>> call(CreateTicketRequest request) {
    return repository.create(request);
  }
}
