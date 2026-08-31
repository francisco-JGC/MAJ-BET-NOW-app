import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/lucky_daily.dart';
import '../../domain/repositories/lucky_repository.dart';

class LuckyQuery {
  const LuckyQuery({required this.kind, required this.date});

  final LuckyKind kind;
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      other is LuckyQuery &&
      kind == other.kind &&
      date.year == other.date.year &&
      date.month == other.date.month &&
      date.day == other.date.day;

  @override
  int get hashCode => Object.hash(kind, date.year, date.month, date.day);
}

final luckyProvider = FutureProvider.autoDispose
    .family<LuckyDaily?, LuckyQuery>((ref, q) async {
  final repo = getIt<LuckyRepository>();
  final result = await repo.findForDate(kind: q.kind, date: q.date);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (item) => item,
  );
});
