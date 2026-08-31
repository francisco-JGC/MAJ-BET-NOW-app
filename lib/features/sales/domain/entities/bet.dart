import 'package:equatable/equatable.dart';

import '../../../../core/utils/prize.dart';

class Bet extends Equatable {
  const Bet({required this.number, required this.amount});

  final int number;
  final int amount;

  String get numberLabel => number.toString().padLeft(2, '0');
  int get prize => prizeFor(amount);

  @override
  List<Object?> get props => [number, amount];
}
