import 'package:equatable/equatable.dart';

import '../../../../core/utils/prize.dart';

const List<String> kMonthAbbreviations = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

class DateBet extends Equatable {
  const DateBet({
    required this.day,
    required this.month,
    required this.amount,
  });

  final int day;
  final int month;
  final int amount;

  int get prize => amount * kDateMultiplier;

  String get dayLabel => day.toString().padLeft(2, '0');
  String get monthLabel => kMonthAbbreviations[month - 1];

  /// API label sent to the backend (lowercase, space separator): "01 ene"
  String get label => '$dayLabel $monthLabel';

  /// Display label for tickets (capitalized month): "01 Ene"
  String get printLabel {
    final m = monthLabel;
    return '$dayLabel ${m[0].toUpperCase()}${m.substring(1)}';
  }

  @override
  List<Object?> get props => [day, month, amount];
}
