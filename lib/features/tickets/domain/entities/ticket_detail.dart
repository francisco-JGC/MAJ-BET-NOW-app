import 'package:equatable/equatable.dart';

import 'ticket_summary.dart';

class TicketLineDetail extends Equatable {
  const TicketLineDetail({
    required this.label,
    required this.amount,
    required this.prize,
    required this.orderIndex,
    this.subGameId,
    this.subGameName,
  });

  final String label;
  final int amount;
  final int prize;
  final int orderIndex;
  final String? subGameId;
  final String? subGameName;

  @override
  List<Object?> get props =>
      [label, amount, prize, orderIndex, subGameId, subGameName];
}

class TicketDetail extends Equatable {
  const TicketDetail({
    required this.summary,
    required this.lines,
  });

  final TicketSummary summary;
  final List<TicketLineDetail> lines;

  @override
  List<Object?> get props => [summary, lines];
}
