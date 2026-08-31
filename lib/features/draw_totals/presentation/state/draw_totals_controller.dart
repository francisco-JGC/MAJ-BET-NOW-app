import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../sale_points/presentation/state/active_sale_point_controller.dart';
import '../../../tickets/domain/entities/tickets_by_draw.dart';
import '../../../tickets/domain/repositories/tickets_repository.dart';

class DrawTotalsFilters extends Equatable {
  const DrawTotalsFilters({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [from, to];
}

class DrawTotalsFiltersNotifier extends Notifier<DrawTotalsFilters> {
  @override
  DrawTotalsFilters build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return DrawTotalsFilters(from: today, to: endOfDay);
  }

  void setRange(DateTime from, DateTime to) {
    state = DrawTotalsFilters(from: from, to: to);
  }
}

final drawTotalsFiltersProvider = NotifierProvider<
    DrawTotalsFiltersNotifier, DrawTotalsFilters>(
  DrawTotalsFiltersNotifier.new,
);

class DrawTotalsController
    extends AsyncNotifier<List<TicketsByDrawItem>> {
  late final _tickets = getIt<TicketsRepository>();

  @override
  Future<List<TicketsByDrawItem>> build() async {
    ref.listen(drawTotalsFiltersProvider, (previous, next) {
      if (previous != next) refresh();
    });
    return _fetch();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<TicketsByDrawItem>> _fetch() async {
    final salePoint = ref.read(activeSalePointProvider).selected;
    if (salePoint == null) return const [];
    final filters = ref.read(drawTotalsFiltersProvider);
    final result = await _tickets.byDraw(TicketsByDrawQuery(
      salePointId: salePoint.id,
      from: filters.from,
      to: filters.to,
    ));
    return result.fold(
      (failure) => throw Exception(failure.message),
      (items) => items,
    );
  }
}

final drawTotalsControllerProvider = AsyncNotifierProvider<
    DrawTotalsController, List<TicketsByDrawItem>>(
  DrawTotalsController.new,
);
