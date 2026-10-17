import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/roulette_play.dart';
import '../../domain/repositories/roulette_repository.dart';

/// Config vigente de la sucursal. Solo se usa para mostrar el multiplicador
/// en pantalla — el premio real lo calcula el backend.
final rouletteConfigProvider =
    FutureProvider.autoDispose.family<RouletteConfig, String>((ref, salePointId) async {
  final result = await getIt<RouletteRepository>().getConfig(salePointId);
  return result.fold((f) => throw Exception(f.message), (c) => c);
});

final rouletteHistoryProvider =
    FutureProvider.autoDispose.family<List<RoulettePlay>, String>((ref, salePointId) async {
  final result = await getIt<RouletteRepository>().history(salePointId: salePointId);
  return result.fold((f) => throw Exception(f.message), (h) => h);
});

enum RoulettePhase { idle, spinning, revealed }

class RouletteState {
  const RouletteState({
    this.selected = const {},
    this.amountPerNumber = 10,
    this.phase = RoulettePhase.idle,
    this.play,
    this.error,
    this.isTestMode = false,
  });

  final Set<String> selected;
  final int amountPerNumber;
  final RoulettePhase phase;
  final RoulettePlay? play;
  final String? error;

  /// Modo prueba: la jugada se registra marcada y no cuenta como venta
  /// ni aparece en el historial operativo.
  final bool isTestMode;

  int get totalAmount => amountPerNumber * selected.length;
  bool get canPlay => selected.isNotEmpty && phase == RoulettePhase.idle;

  RouletteState copyWith({
    Set<String>? selected,
    int? amountPerNumber,
    RoulettePhase? phase,
    RoulettePlay? play,
    bool clearPlay = false,
    String? error,
    bool clearError = false,
    bool? isTestMode,
  }) {
    return RouletteState(
      selected: selected ?? this.selected,
      amountPerNumber: amountPerNumber ?? this.amountPerNumber,
      phase: phase ?? this.phase,
      play: clearPlay ? null : play ?? this.play,
      error: clearError ? null : error ?? this.error,
      isTestMode: isTestMode ?? this.isTestMode,
    );
  }
}

class RouletteController extends Notifier<RouletteState> {
  @override
  RouletteState build() => const RouletteState();

  /// Apostar a las 38 casillas no es una jugada: con cualquier
  /// multiplicador menor a 38 se perdería siempre. El backend lo rechaza,
  /// pero frenarlo acá evita el viaje y permite explicarlo en vez de
  /// mostrar un error de servidor.
  static final maxSelectable = kRoulettePockets.length - 1; // 37

  void toggle(String number) {
    if (state.phase != RoulettePhase.idle) return;
    final next = Set<String>.from(state.selected);
    if (next.contains(number)) {
      next.remove(number);
    } else {
      if (next.length >= maxSelectable) {
        state = state.copyWith(
          error: 'No podés apostar a todas las casillas: dejá al menos una afuera.',
        );
        return;
      }
      next.add(number);
    }
    state = state.copyWith(selected: next, clearError: true);
  }

  void clearSelection() {
    if (state.phase != RoulettePhase.idle) return;
    state = state.copyWith(selected: const {}, clearError: true);
  }

  void setTestMode(bool value) {
    if (state.phase != RoulettePhase.idle) return;
    state = state.copyWith(isTestMode: value);
  }

  void setAmount(int amount) {
    if (state.phase != RoulettePhase.idle || amount < 1) return;
    state = state.copyWith(amountPerNumber: amount);
  }

  /// Pide la jugada al backend y pasa a `spinning`. El resultado ya viene
  /// decidido; la animación solo lo representa.
  Future<RoulettePlay?> play(String salePointId) async {
    if (!state.canPlay) return null;
    state = state.copyWith(phase: RoulettePhase.spinning, clearError: true);

    final result = await getIt<RouletteRepository>().play(
      salePointId: salePointId,
      numbers: state.selected.toList(),
      amountPerNumber: state.amountPerNumber,
      isTest: state.isTestMode,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          phase: RoulettePhase.idle,
          error: failure.message,
        );
        return null;
      },
      (play) {
        state = state.copyWith(play: play);
        return play;
      },
    );
  }

  /// La llama la pantalla cuando la rueda terminó de girar.
  void reveal() => state = state.copyWith(phase: RoulettePhase.revealed);

  /// Conserva el modo prueba a propósito: salir de prueba debe ser una
  /// decisión explícita, no algo que pase solo al jugar de nuevo.
  void reset() {
    state = RouletteState(isTestMode: state.isTestMode);
  }
}

final rouletteControllerProvider =
    NotifierProvider.autoDispose<RouletteController, RouletteState>(
  RouletteController.new,
);
