import 'package:equatable/equatable.dart';

import '../../domain/entities/date_bet.dart';

class DateCartState extends Equatable {
  const DateCartState({this.bets = const [], this.client});

  final List<DateBet> bets;
  final String? client;

  bool get isEmpty => bets.isEmpty;
  bool get isNotEmpty => bets.isNotEmpty;
  int get total => bets.fold(0, (sum, b) => sum + b.amount);
  int get totalPrize => bets.fold(0, (sum, b) => sum + b.prize);
  int get count => bets.length;

  @override
  List<Object?> get props => [bets, client];
}
