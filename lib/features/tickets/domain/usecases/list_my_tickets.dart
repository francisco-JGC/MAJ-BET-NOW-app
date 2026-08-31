import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/list_tickets_query.dart';
import '../repositories/tickets_repository.dart';

class ListMyTickets {
  const ListMyTickets({required this.repository});

  final TicketsRepository repository;

  Future<Either<Failure, ListTicketsResult>> call(ListTicketsQuery query) {
    return repository.list(query);
  }
}
