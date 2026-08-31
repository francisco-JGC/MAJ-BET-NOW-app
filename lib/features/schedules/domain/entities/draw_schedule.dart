import 'package:equatable/equatable.dart';

class DrawSchedule extends Equatable {
  const DrawSchedule({
    required this.id,
    required this.gameId,
    required this.dayOfWeek,
    required this.drawTime,
    required this.cutoffMinutes,
    required this.isActive,
  });

  final String id;
  final String gameId;
  final int? dayOfWeek;
  final String drawTime;
  final int cutoffMinutes;
  final bool isActive;

  bool appliesTo(int weekday) {
    if (!isActive) return false;
    return dayOfWeek == null || dayOfWeek == weekday;
  }

  ({int hour, int minute}) get parsedTime {
    final parts = drawTime.split(':');
    return (hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  List<Object?> get props =>
      [id, gameId, dayOfWeek, drawTime, cutoffMinutes, isActive];
}
