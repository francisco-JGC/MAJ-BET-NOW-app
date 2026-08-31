import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/business_time.dart';
import '../../domain/entities/draw_schedule.dart';
import '../../domain/repositories/schedules_repository.dart';

const _postDrawGraceMinutes = 3;

class AvailableDraw extends Equatable {
  const AvailableDraw({
    required this.drawAt,
    required this.cutoffMinutes,
    required this.lockStart,
    required this.lockEnd,
  });

  final DateTime drawAt;
  final int cutoffMinutes;
  final DateTime lockStart;
  final DateTime lockEnd;

  @override
  List<Object?> get props => [drawAt, cutoffMinutes, lockStart, lockEnd];
}

final availableDrawsProvider = FutureProvider.autoDispose
    .family<List<AvailableDraw>, String>((ref, gameId) async {
  final repo = getIt<SchedulesRepository>();
  final result = await repo.listByGame(gameId);
  final schedules = result.fold<List<DrawSchedule>>(
    (_) => const [],
    (items) => items.where((s) => s.isActive).toList(),
  );
  if (schedules.isEmpty) return const [];

  final now = DateTime.now().toUtc();
  final biz = BusinessTime.nowInBusinessTz();
  final weekday = biz.weekday % 7;
  final windows = <AvailableDraw>[];

  for (final s in schedules) {
    if (!s.appliesTo(weekday)) continue;
    final t = s.parsedTime;
    final drawAt = BusinessTime.toUtc(
      year: biz.year,
      month: biz.month,
      day: biz.day,
      hour: t.hour,
      minute: t.minute,
    );
    final lockStart = drawAt.subtract(Duration(minutes: s.cutoffMinutes));
    final lockEnd = drawAt.add(const Duration(minutes: _postDrawGraceMinutes));
    // Skip draws that already started their lock window: user can't sell.
    if (!now.isBefore(lockStart)) continue;
    windows.add(AvailableDraw(
      drawAt: drawAt,
      cutoffMinutes: s.cutoffMinutes,
      lockStart: lockStart,
      lockEnd: lockEnd,
    ));
  }

  windows.sort((a, b) => a.drawAt.compareTo(b.drawAt));
  return windows;
});
