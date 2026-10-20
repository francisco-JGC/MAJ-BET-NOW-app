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
    this.amountPerNumber,
    this.phase = RoulettePhase.idle,
    this.play,
    this.error,
    this.isTestMode = false,
  });

  /// Casilla → monto. Cada número se queda con el monto que había en el
  /// campo al tocarlo, así se puede cargar C$50 a uno y C$10 a otro.
  final Map<String, int> selected;

  /// Monto que se aplicará al PRÓXIMO número que se toque. Nulo hasta que
  /// el vendedor lo escriba: el campo arranca vacío a propósito.
  final int? amountPerNumber;
  final RoulettePhase phase;
  final RoulettePlay? play;
  final String? error;

  /// Lo que eligió el vendedor para ESTA tirada. Solo tiene efecto si la
  /// sucursal tiene el modo habilitado — el servidor lo revalida.
  final bool isTestMode;

  int get totalAmount =>
      selected.values.fold(0, (sum, amount) => sum + amount);

  bool get hasAmount => (amountPerNumber ?? 0) >= 1;

  /// Para jugar alcanza con tener números cargados: el monto del campo
  /// solo hace falta para AGREGAR otro.
  bool get canPlay => selected.isNotEmpty && phase == RoulettePhase.idle;

  RouletteState copyWith({
    Map<String, int>? selected,
    int? amountPerNumber,
    bool clearAmount = false,
    RoulettePhase? phase,
    RoulettePlay? play,
    bool clearPlay = false,
    String? error,
    bool clearError = false,
    bool? isTestMode,
  }) {
    return RouletteState(
      selected: selected ?? this.selected,
      amountPerNumber:
          clearAmount ? null : amountPerNumber ?? this.amountPerNumber,
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
    // Con el resultado en pantalla, tocar un número arranca una tirada
    // nueva en vez de no hacer nada. Obligar a pasar por "Jugar de nuevo"
    // se sentía como si el tablero estuviera trabado.
    if (state.phase == RoulettePhase.revealed) {
      final amount = state.amountPerNumber;
      state = RouletteState(
        isTestMode: state.isTestMode,
        amountPerNumber: amount,
        selected: amount == null ? const {} : {number: amount},
      );
      return;
    }
    if (state.phase != RoulettePhase.idle) return;

    final next = Map<String, int>.from(state.selected);
    if (next.containsKey(number)) {
      next.remove(number);
      state = state.copyWith(selected: next, clearError: true);
      return;
    }

    // Sin monto en el campo no se puede agregar: el número quedaría sin
    // precio y no habría forma de saber cuánto cobrar.
    final amount = state.amountPerNumber;
    if (amount == null || amount < 1) {
      state = state.copyWith(
        error: 'Escribí el monto antes de elegir el número.',
      );
      return;
    }
    if (next.length >= maxSelectable) {
      state = state.copyWith(
        error: 'No podés apostar a todas las casillas: dejá al menos una afuera.',
      );
      return;
    }
    next[number] = amount;
    state = state.copyWith(selected: next, clearError: true);
  }

  void clearSelection() {
    if (state.phase != RoulettePhase.idle) return;
    state = state.copyWith(selected: const <String, int>{}, clearError: true);
  }

  void setTestMode({required bool value}) {
    if (state.phase != RoulettePhase.idle) return;
    state = state.copyWith(isTestMode: value);
  }

  /// Si el admin revoca el permiso con el modo prueba tildado, la tirada
  /// vuelve a ser real sola. Nunca al revés.
  void revokeTestModeIfNotAllowed({required bool allowed}) {
    if (!allowed && state.isTestMode) {
      state = state.copyWith(isTestMode: false);
    }
  }

  /// `null` vacía el campo — es un estado válido, no un error.
  void setAmount(int? amount) {
    if (state.phase != RoulettePhase.idle) return;
    if (amount == null) {
      state = state.copyWith(clearAmount: true);
      return;
    }
    if (amount < 1) return;
    state = state.copyWith(amountPerNumber: amount);
  }

  /// Pide la jugada al backend y pasa a `spinning`. El resultado ya viene
  /// decidido; la animación solo lo representa.
  Future<RoulettePlay?> play(String salePointId) async {
    if (!state.canPlay) return null;
    final bets = state.selected.entries
        .map((e) => RouletteBet(number: e.key, amount: e.value))
        .toList();
    state = state.copyWith(phase: RoulettePhase.spinning, clearError: true);

    final result = await getIt<RouletteRepository>().play(
      salePointId: salePointId,
      bets: bets,
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

  void reset() {
    state = RouletteState(isTestMode: state.isTestMode);
  }
}

final rouletteControllerProvider =
    NotifierProvider.autoDispose<RouletteController, RouletteState>(
  RouletteController.new,
);
