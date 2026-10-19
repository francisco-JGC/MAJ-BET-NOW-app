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
    final configAsync = salePoint == null
        ? null
        : ref.watch(rouletteConfigProvider(salePoint.id));
    final config = configAsync?.value;

    // Si la configuración no carga, hay que DECIRLO. Antes esto era un
    // `?? false` silencioso: ante un backend caído o sin desplegar, el
    // switch simplemente no aparecía y no había forma de saber por qué.
    final configFailed = configAsync?.hasError ?? false;

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
              if (configFailed)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: const Border.fromBorderSide(
                      BorderSide(color: Color(0xFFDC2626)),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_off, size: 18, color: Color(0xFFFCA5A5)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No se pudo cargar la configuración de la ruleta. '
                          'Las tiradas se registran como reales.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFCA5A5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
          ? const SizedBox(height: 92, key: ValueKey('empty'))
          : Container(
              key: ValueKey(play.id),
              height: 92,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: play.isWin
                    ? AppTheme.accent.withValues(alpha: 0.18)
                    : const Color(0xFFDC2626).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: play.isWin
                      ? AppTheme.accent
                      : const Color(0xFFDC2626),
                  width: play.isWin ? 2.5 : 2,
                ),
                boxShadow: play.isWin
                    ? [
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              // El monto ganado es la información que el vendedor tiene que
              // leer de un vistazo para pagar. Va solo, grande y en una
              // línea propia; el resto es contexto.
              child: play.isWin
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.celebration,
                                size: 18, color: AppTheme.accent),
                            const SizedBox(width: 6),
                            Text(
                              '¡GANASTE!  ·  Salió el ${play.winningNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.6,
                                color: AppTheme.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          child: Text(
                            kCurrencyFormat.format(play.prize),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 34,
                              height: 1.1,
                              color: Colors.white,
                              shadows: [
                                Shadow(blurRadius: 12, color: AppTheme.accent),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sentiment_dissatisfied,
                            size: 20, color: Color(0xFFFCA5A5)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'No ganaste  ·  Salió el ${play.winningNumber}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Color(0xFFFCA5A5),
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
    _amountCtrl = TextEditingController(
      text: widget.state.amountPerNumber?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(_BetBar old) {
    super.didUpdateWidget(old);
    // Solo se sincroniza cuando el monto cambió desde AFUERA (un chip o un
    // reset). Si viene de tipear, el texto ya es correcto y reescribirlo
    // movería el cursor.
    final incoming = widget.state.amountPerNumber?.toString() ?? '';
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
            width: 130,
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
                // Borrar todo deja el monto en null: el campo vacío es un
                // estado válido, y el botón de girar se deshabilita solo.
                ref
                    .read(rouletteControllerProvider.notifier)
                    .setAmount(v.trim().isEmpty ? null : int.tryParse(v));
              },
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${state.selected.length} núm · x$multiplier',
                  style: const TextStyle(fontSize: 11, color: Colors.white60)),
              const SizedBox(height: 2),
              Text(
                state.hasAmount
                    ? kCurrencyFormat.format(state.totalAmount)
                    : '—',
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
                        : !state.hasAmount
                            ? 'Ingresá el monto'
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
