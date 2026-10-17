import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../sale_points/presentation/state/active_sale_point_controller.dart';
import '../../domain/entities/roulette_play.dart';
import '../state/haptics_provider.dart';
import '../state/roulette_controller.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/lose_flash.dart';
import '../widgets/number_board.dart';
import '../widgets/roulette_wheel.dart';

/// Duración del giro. Larga a propósito: el resultado ya está decidido
/// desde que el backend responde, y lo único que queda es el suspenso.
const _spinDuration = Duration(milliseconds: 5200);

/// Fondo de la mesa. Violeta casi negro, para que el dorado del marco
/// y de la rueda tengan contra qué brillar.
const _kFelt = Color(0xFF14031F);

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
  late final AnimationController _lose;

  /// La curva se crea UNA vez. Creada dentro de `build` quedaba una
  /// instancia nueva por rebuild, todas suscritas a `_spin` y ninguna
  /// liberada — Flutter exige disponerlas explícitamente.
  late final CurvedAnimation _spinCurve;

  /// Índice donde frena la rueda. Se fija al recibir la respuesta.
  int _targetIndex = 0;

  /// Última casilla que pasó bajo el puntero, para no repetir el tic.
  int _lastTickedPocket = -1;

  final _scroll = ScrollController();

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
    // Arranca fuerte y desacelera largo sobre el final, que es donde se
    // genera la tensión.
    _lose = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _spinCurve = CurvedAnimation(parent: _spin, curve: Curves.easeOutQuart);
    _spinCurve.addListener(_tickHaptics);
  }

  /// Vibración por casilla: un tic liviano cada vez que una casilla nueva
  /// pasa bajo el puntero. Como la curva desacelera, los tics se van
  /// espaciando solos y se siente cómo la rueda pierde fuerza.
  void _tickHaptics() {
    final pocket = (_spinCurve.value * _totalPocketsPassed).floor();
    if (pocket == _lastTickedPocket) return;
    _lastTickedPocket = pocket;
    if (!_spin.isAnimating) return;
    if (!ref.read(rouletteHapticsProvider)) return;
    HapticFeedback.selectionClick();
  }

  /// Cuántas casillas pasan en todo el giro: 6 vueltas completas.
  static const _totalPocketsPassed = 6 * kRoulettePocketCount;

  @override
  void dispose() {
    _scroll.dispose();
    _spin.removeStatusListener(_onSpinStatus);
    _spinCurve
      ..removeListener(_tickHaptics)
      ..dispose();
    _entrance.dispose();
    _spin.dispose();
    _confetti.dispose();
    _lose.dispose();
    super.dispose();
  }

  /// Lleva la vista a la rueda. Se usa al girar y al volver a jugar: el
  /// botón vive al fondo del scroll, así que sin esto la animación —que es
  /// todo el juego— ocurría fuera de pantalla.
  void _scrollToWheel() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handlePlay() async {
    final salePoint = ref.read(activeSalePointProvider).selected;
    if (salePoint == null) return;

    _scrollToWheel();

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

    final hapticsOn = ref.read(rouletteHapticsProvider);
    if (ref.read(rouletteControllerProvider).play?.isWin ?? false) {
      if (hapticsOn) HapticFeedback.heavyImpact();
      _confetti.forward(from: 0);
    } else {
      if (hapticsOn) HapticFeedback.mediumImpact();
      _lose.forward(from: 0);
    }
  }

  void _handleReset() {
    ref.read(rouletteControllerProvider.notifier).reset();
    _spin.reset();
    _confetti.reset();
    _lose.reset();
    _lastTickedPocket = -1;
    setState(() => _targetIndex = 0);
    _scrollToWheel();
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

    // El admin habilita el modo prueba desde la web; el vendedor decide
    // tirada por tirada. Si el permiso se revoca con el switch tildado,
    // la tirada vuelve a ser real sola.
    final testAllowed = config?.testMode ?? false;
    if (!testAllowed && state.isTestMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(rouletteControllerProvider.notifier)
              .revokeTestModeIfNotAllowed(allowed: testAllowed);
        }
      });
    }

    return Scaffold(
      // La app corre en tema claro, pero esta pantalla se diseñó sobre
      // oscuro: usa texto blanco y superficies `white12`, que sobre el
      // surface claro del tema quedaban casi invisibles. El fondo propio
      // no es decorativo, es lo que la hace legible.
      backgroundColor: _kFelt,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Ruleta'),
        actions: [
          if (testAllowed)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.science_outlined,
                    size: 18,
                    color: state.isTestMode
                        ? const Color(0xFFF59E0B)
                        : Colors.white38,
                  ),
                  const SizedBox(width: 2),
                  const Text('Prueba',
                      style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Switch(
                    value: state.isTestMode,
                    activeThumbColor: const Color(0xFFF59E0B),
                    onChanged: state.phase == RoulettePhase.idle
                        ? (v) => ref
                            .read(rouletteControllerProvider.notifier)
                            .setTestMode(value: v)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Degradé del paño: más claro arriba, donde está la rueda.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.55),
                radius: 1.1,
                colors: [Color(0xFF2E1065), _kFelt],
              ),
            ),
            child: SizedBox.expand(),
          ),
          // Marco de fichas. Va DEBAJO del contenido y sin capturar toques:
          // es decoración de borde, no un elemento interactivo.
          const IgnorePointer(
            child: Opacity(
              opacity: 0.85,
              child: Image(
                image: AssetImage('assets/images/games/ruleta_marco.webp'),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // Franja permanente mientras dure el modo: que nadie cobre
              // ni pague por una tirada de prueba creyendo que fue real.
              if (state.isTestMode)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.science_outlined,
                          size: 18, color: Color(0xFFF59E0B)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'MODO PRUEBA · No le cobres al cliente: esta '
                          'tirada no factura ni paga premio.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFDE68A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _Staggered(
                controller: _entrance,
                order: 0,
                child: Center(
                  child: RouletteWheel(
                    controller: _spinCurve,
                    targetIndex: _targetIndex,
                    selected: state.selected,
                    size: MediaQuery.sizeOf(context).width * 0.78,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ShakeTransition(
                controller: _lose,
                child: _ResultBanner(state: state),
              ),
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
          LoseFlash(controller: _lose),
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
    // Interval se evalúa sobre el valor del controller en vez de envolverlo
    // en un CurvedAnimation: así no queda un objeto animado nuevo —y sin
    // liberar— por cada rebuild.
    final curve = Interval(
      start,
      (start + 0.5).clamp(0.0, 1.0),
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: controller,
      builder: (context, c) {
        final v = curve.transform(controller.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 26 * (1 - v)), child: c),
        );
      },
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
        scale: CurveTween(curve: Curves.easeOutBack).animate(anim),
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
                    : const Color(0xFFDC2626).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: play.isWin
                      ? AppTheme.accent
                      : const Color(0xFFDC2626),
                  width: 2,
                ),
              ),
              // Perder tiene que leerse como un resultado, no como un dato
              // suelto: antes decía solo "Salió el 17" en gris y no se
              // distinguía de no haber jugado.
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    play.isWin ? Icons.celebration : Icons.sentiment_dissatisfied,
                    size: 20,
                    color: play.isWin
                        ? AppTheme.accent
                        : const Color(0xFFFCA5A5),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      play.isWin
                          ? '¡Ganaste ${kCurrencyFormat.format(play.prize)}!  ·  Salió el ${play.winningNumber}'
                          : 'No ganaste  ·  Salió el ${play.winningNumber}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: play.isWin ? 17 : 16,
                        color: play.isWin
                            ? AppTheme.accent
                            : const Color(0xFFFCA5A5),
                      ),
                    ),
                  ),
                ],
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
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.white),
              cursorColor: AppTheme.accent,
              decoration: const InputDecoration(
                labelText: 'Monto',
                labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                prefixText: 'C\$',
                prefixStyle: TextStyle(color: Colors.white70),
                isDense: true,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.accent),
                ),
                disabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white12),
                ),
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
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
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
              // En prueba el botón es ámbar: la diferencia tiene que verse
              // en el mismo lugar donde se toma la decisión, no solo en un
              // cartel arriba que se puede pasar por alto.
              backgroundColor:
                  state.isTestMode ? const Color(0xFFF59E0B) : AppTheme.accent,
              foregroundColor: const Color(0xFF1F1300),
              disabledBackgroundColor: Colors.white12,
              // Sin esto el estado deshabilitado tomaba el gris del tema
              // claro y quedaba ilegible sobre el fondo oscuro.
              disabledForegroundColor: Colors.white38,
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
                        : state.isTestMode
                            ? 'Girar en PRUEBA · sin cobrar'
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
