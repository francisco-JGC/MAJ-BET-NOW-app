import 'package:intl/intl.dart';

final DateFormat _time12h = DateFormat('h:mm a', 'en_US');

/// Formats [dateTime] as "3:00 pm" (12-hour, lowercase am/pm).
String formatTime12h(DateTime dateTime) {
  return _time12h.format(dateTime.toLocal()).toLowerCase();
}
