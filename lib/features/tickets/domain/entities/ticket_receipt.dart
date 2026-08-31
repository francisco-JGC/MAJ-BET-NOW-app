import 'package:equatable/equatable.dart';

class TicketReceipt extends Equatable {
  const TicketReceipt({
    required this.id,
    required this.folio,
    required this.drawAt,
    required this.total,
    required this.totalPrize,
    required this.count,
  });

  final String id;
  final String folio;
  final DateTime drawAt;
  final int total;
  final int totalPrize;
  final int count;

  @override
  List<Object?> get props => [id, folio, drawAt, total, totalPrize, count];
}
