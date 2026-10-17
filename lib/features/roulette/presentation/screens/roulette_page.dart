import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../sale_points/presentation/state/active_sale_point_controller.dart';
import '../../domain/entities/roulette_play.dart';
import '../state/roulette_controller.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/number_board.dart';
import '../widgets/roulette_wheel.dart';

/// Duración del giro. Larga a propósito: el resultado ya está decidido
/// desde que el backend responde, y lo único que queda es el suspenso.
const _spinDuration = Duration(milliseconds: 5200);

class RoulettePage extends ConsumerStatefulWidget {
  const RoulettePage({super.key});

  @override
  ConsumerState<RoulettePage> createState() => _RoulettePageState();
}

class _RoulettePageState extends ConsumerState<RoulettePage>
    with TickerProviderStateMixin {
  /// Entrada de la escena: la imagen, la rueda y el tablero aparecen
  /// escalonados en vez de todos juntos.
  late final AnimationController _entrance;
  late final AnimationController _spin;
  late final AnimationController _confetti;

  /// Índice donde frena la rueda. Se fija al recibir la respuesta.
  int _targetIndex = 0;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _spin = AnimationController(vsync: this, duration: _spinDuration)
      ..addStatusListener(_onSpinStatus);
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
  }

  @override
  void dispose() {
    _spin.removeStatusListener(_onSpinStatus);
    _entrance.dispose();
    _spin.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _handlePlay() async {
    final salePoint = ref.read(activeSalePointProvider).selected;
    if (salePoint == null) return;

    final play = await ref
        .read(rouletteControllerProvider.notifier)
        .play(salePoint.id);
    if (play == null || !mounted) return;

    setState(() {
      _targetIndex = kRoulettePockets.indexOf(play.winningNumber);
      if (_targetIndex < 0) _targetIndex = 0;
    });

    // El reveal lo dispara `_onSpinStatus` al completarse la animación.
    // Antes esto esperaba un Future.delayed del mismo largo que el giro,
    // lo que obligaba a mantener dos valores sincronizados a mano: cambiar
    // la duración o la curva en un lado desalineaba el otro en silencio.
    unawaited(_spin.forward(from: 0));
  }

  /// Único lugar donde se destapa el resultado. Al colgar del estado de la
  /// animación, es imposible que se adelante o se atrase respecto a la
  /// rueda, dure lo que dure el giro.
  void _onSpinStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;

    final notifier = ref.read(rouletteControllerProvider.notifier);
    notifier.reveal();

    if (ref.read(rouletteControllerProvider).play?.isWin ?? false) {
      _confetti.forward(from: 0);
    }
  }

  void _handleReset() {
    ref.read(rouletteControllerProvider.notifier).reset();
    _spin.reset();
    _confetti.reset();
  }

  @override
  Widget build(BuildContext context) {
    // Los errores se muestran como alerta flotante, no como texto fijo en
    // la lista: antes una excepción del backend quedaba impresa cruda en
    // pantalla y empujaba el layout.
    ref.listen(rouletteControllerProvider.select((s) => s.error), (_, error) {
      if (error == null || !mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFB91C1C),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
    });

    final state = ref.watch(rouletteControllerProvider);
    final salePoint = ref.watch(activeSalePointProvider).selected;
    final config = salePoint == null
        ? null
        : ref.watch(rouletteConfigProvider(salePoint.id)).value;

    // Curva de giro: arranca fuerte y desacelera largo al final, que es
    // donde se genera la tensión.
    final spinCurve = CurvedAnimation(parent: _spin, curve: Curves.easeOutQuart);

    return Scaffold(
      appBar: AppBar(title: const Text('Ruleta')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _Staggered(
                controller: _entrance,
                order: 0,
                child: Center(
                  child: RouletteWheel(
                    controller: spinCurve,
                    targetIndex: _targetIndex,
                    selected: state.selected,
                    size: MediaQuery.sizeOf(context).width * 0.78,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _ResultBanner(state: state),
              const SizedBox(height: 10),
              _Staggered(
                controller: _entrance,
                order: 1,
                child: _BetBar(
                  state: state,
                  multiplier: config?.prizeMultiplier ?? 35,
                ),
              ),
              const SizedBox(height: 14),
              _Staggered(
                controller: _entrance,
                order: 2,
                child: NumberBoard(
                  selected: state.selected,
                  enabled: state.phase == RoulettePhase.idle,
                  winning: state.phase == RoulettePhase.revealed
                      ? state.play?.winningNumber
                      : null,
                  onToggle: (n) =>
                      ref.read(rouletteControllerProvider.notifier).toggle(n),
                ),
              ),
              const SizedBox(height: 18),
              _ActionBar(
                state: state,
                onPlay: _handlePlay,
                onReset: _handleReset,
                onClear: () =>
                    ref.read(rouletteControllerProvider.notifier).clearSelection(),
              ),
            ],
          ),
          ConfettiOverlay(controller: _confetti),
        ],
      ),
    );
  }
}

/// Aparición escalonada: cada hijo entra con un desfase según [order],
/// deslizándose hacia arriba y apareciendo.
class _Staggered extends StatelessWidget {
  const _Staggered({
    required this.controller,
    required this.order,
    required this.child,
  });

  final AnimationController controller;
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (order * 0.12).clamp(0.0, 0.6);
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 26 * (1 - anim.value)),
          child: c,
        ),
      ),
      child: child,
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.state});

  final RouletteState state;

  @override
  Widget build(BuildContext context) {
    final play = state.play;
    final revealed = state.phase == RoulettePhase.revealed && play != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: !revealed
          ? const SizedBox(height: 56, key: ValueKey('empty'))
          : Container(
              key: ValueKey(play.id),
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: play.isWin
                    ? AppTheme.accent.withValues(alpha: 0.18)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: play.isWin ? AppTheme.accent : Colors.white24,
                  width: play.isWin ? 2 : 1,
                ),
              ),
              child: Text(
                play.isWin
                    ? '¡Ganaste ${kCurrencyFormat.format(play.prize)}!  ·  Salió el ${play.winningNumber}'
                    : 'Salió el ${play.winningNumber}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: play.isWin ? 17 : 15,
                  color: play.isWin ? AppTheme.accent : Colors.white70,
                ),
              ),
            ),
    );
  }
}

class _BetBar extends ConsumerStatefulWidget {
  const _BetBar({required this.state, required this.multiplier});

  final RouletteState state;
  final int multiplier;

  @override
  ConsumerState<_BetBar> createState() => _BetBarState();
}

class _BetBarState extends ConsumerState<_BetBar> {
  /// El controller vive en el State y no en `build`: creado en cada
  /// rebuild, el cursor saltaba al principio con cada tecla.
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl =
        TextEditingController(text: '${widget.state.amountPerNumber}');
  }

  @override
  void didUpdateWidget(_BetBar old) {
    super.didUpdateWidget(old);
    // Solo se sincroniza cuando el monto cambió desde AFUERA (un chip o un
    // reset). Si viene de tipear, el texto ya es correcto y reescribirlo
    // movería el cursor.
    final incoming = '${widget.state.amountPerNumber}';
    if (incoming != _amountCtrl.text &&
        int.tryParse(_amountCtrl.text) != widget.state.amountPerNumber) {
      _amountCtrl.text = incoming;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final multiplier = widget.multiplier;
    final enabled = state.phase == RoulettePhase.idle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Campo editable: los chips son atajos, pero el vendedor tiene
          // que poder escribir cualquier monto.
          SizedBox(
            width: 92,
            child: TextField(
              controller: _amountCtrl,
              enabled: enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: 'C\$',
                isDense: true,
              ),
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > 0) {
                  ref
                      .read(rouletteControllerProvider.notifier)
                      .setAmount(parsed);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          for (final step in [10, 25, 50])
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _Chip(
                label: '$step',
                onTap: enabled
                    ? () => ref
                        .read(rouletteControllerProvider.notifier)
                        .setAmount(step)
                    : null,
                active: state.amountPerNumber == step,
              ),
            ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${state.selected.length} núm · x$multiplier',
                  style: const TextStyle(fontSize: 11, color: Colors.white60)),
              const SizedBox(height: 2),
              Text(
                kCurrencyFormat.format(state.totalAmount),
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppTheme.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, required this.active});

  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppTheme.accent : Colors.white12,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: active ? const Color(0xFF1F1300) : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.state,
    required this.onPlay,
    required this.onReset,
    required this.onClear,
  });

  final RouletteState state;
  final VoidCallback onPlay;
  final VoidCallback onReset;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (state.phase == RoulettePhase.revealed) {
      return FilledButton.icon(
        onPressed: onReset,
        icon: const Icon(Icons.refresh),
        label: const Text('Jugar de nuevo'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppTheme.primary,
        ),
      );
    }

    final spinning = state.phase == RoulettePhase.spinning;
    return Row(
      children: [
        if (state.selected.isNotEmpty && !spinning) ...[
          OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(52, 52),
              padding: EdgeInsets.zero,
            ),
            child: const Icon(Icons.close),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: FilledButton(
            onPressed: state.canPlay ? onPlay : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppTheme.accent,
              foregroundColor: const Color(0xFF1F1300),
              disabledBackgroundColor: Colors.white12,
            ),
            child: spinning
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(
                    state.selected.isEmpty
                        ? 'Elegí tus números'
                        : 'Girar · ${kCurrencyFormat.format(state.totalAmount)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }
}
