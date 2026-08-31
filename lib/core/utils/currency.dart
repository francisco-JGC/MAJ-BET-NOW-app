import 'package:intl/intl.dart';

const String kCurrencySymbol = 'C\$';

final NumberFormat kCurrencyFormat = NumberFormat.currency(
  locale: 'en_US',
  symbol: '$kCurrencySymbol ',
  decimalDigits: 0,
);

final NumberFormat kAmountFormat = NumberFormat('#,##0', 'en_US');
