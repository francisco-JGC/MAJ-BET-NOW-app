import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/sale_point.dart';
import '../../domain/repositories/sale_points_repository.dart';
import 'active_sale_point_state.dart';

class ActiveSalePointController extends Notifier<ActiveSalePointState> {
  late final _repository = getIt<SalePointsRepository>();

  @override
  ActiveSalePointState build() => const ActiveSalePointState.idle();

  Future<void> loadForCurrentUser() async {
    state = state.copyWith(
      status: ActiveSalePointStatus.loading,
      clearError: true,
    );

    final result = await _repository.fetchMine();
    await result.match(
      (failure) async {
        state = state.copyWith(
          status: ActiveSalePointStatus.error,
          errorMessage: failure.message,
        );
      },
      (points) async {
        final active = points.where((p) => p.isActive).toList();

        if (active.isEmpty) {
          state = state.copyWith(
            status: ActiveSalePointStatus.empty,
            available: const [],
            clearSelected: true,
          );
          await _repository.clearSelectedId();
          return;
        }

        if (active.length == 1) {
          final only = active.first;
          await _repository.saveSelectedId(only.id);
          state = state.copyWith(
            status: ActiveSalePointStatus.ready,
            available: active,
            selected: only,
          );
          return;
        }

        final storedId = await _repository.readSelectedId();
        final stored = storedId == null
            ? null
            : active.where((p) => p.id == storedId).firstOrNull;
        if (stored != null) {
          state = state.copyWith(
            status: ActiveSalePointStatus.ready,
            available: active,
            selected: stored,
          );
          return;
        }

        state = state.copyWith(
          status: ActiveSalePointStatus.needsSelection,
          available: active,
          clearSelected: true,
        );
      },
    );
  }

  Future<void> select(SalePoint point) async {
    await _repository.saveSelectedId(point.id);
    state = state.copyWith(
      status: ActiveSalePointStatus.ready,
      selected: point,
    );
  }

  Future<void> clear() async {
    await _repository.clearSelectedId();
    state = const ActiveSalePointState.idle();
  }
}

final activeSalePointProvider =
    NotifierProvider<ActiveSalePointController, ActiveSalePointState>(
  ActiveSalePointController.new,
);

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
