import 'package:equatable/equatable.dart';

import '../../../../core/utils/prize.dart';

class ComboBet extends Equatable {
  const ComboBet({required this.number, required this.amount});

  final int number;
  final int amount;

  String get numberLabel => number.toString().padLeft(4, '0');
  int get prize => amount * kComboMultiplier;

  @override
  List<Object?> get props => [number, amount];
}
