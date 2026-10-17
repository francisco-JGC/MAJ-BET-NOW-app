import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/roulette_play.dart';

/// Rueda de ruleta dibujada a mano con [CustomPainter].
///
/// Se pinta en vez de usar una imagen porque tiene que DETENERSE en una
/// casilla concreta: la que el backend ya decidió. Con un sprite animado
/// habría que falsear el alineado; acá el ángulo final se calcula.
///
/// La animación es intencionalmente larga (~5s) y con desaceleración
/// fuerte al final: el suspenso es el juego. El resultado ya está decidido
/// desde el primer frame — la rueda solo lo cuenta.
class RouletteWheel extends StatefulWidget {
  const RouletteWheel({
    required this.controller,
    required this.targetIndex,
    required this.selected,
    this.size = 300,
    super.key,
  });

  /// 0 → quieta; 1 → giro completo terminado en [targetIndex].
  final Animation<double> controller;

  /// Índice en [kRoulettePockets] donde tiene que frenar.
  final int targetIndex;

  /// Casillas elegidas, para resaltarlas mientras no gira.
  final Set<String> selected;

  final double size;

  @override
  State<RouletteWheel> createState() => _RouletteWheelState();
}

class _RouletteWheelState extends State<RouletteWheel> {
  /// Vueltas completas antes de frenar. Suficientes para que se vea
  /// "lanzada" sin aburrir.
  static const _fullTurns = 6;

  @override
  Widget build(BuildContext context) {
    final sector = 2 * math.pi / kRoulettePockets.length;
    // La casilla objetivo tiene que quedar bajo el puntero (arriba, -90°).
    final target = _fullTurns * 2 * math.pi - widget.targetIndex * sector;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final t = widget.controller.value;
          final angle = target * t;
          // La bola orbita al revés y va cayendo hacia el centro, como en
          // una ruleta real: primero corre por el borde, después se mete.
          final ballAngle = -angle * 1.8;
          final ballInset = Curves.easeInCubic.transform(t.clamp(0.0, 1.0));
          // Mezcla hacia la casilla ganadora durante el último 18% del
          // giro. Sin esto la bola daba un salto visible en el último
          // frame, al pasar de "orbitando" a "apoyada".
          final settleT =
              Curves.easeInOut.transform(((t - 0.82) / 0.18).clamp(0.0, 1.0));

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: angle,
                child: CustomPaint(
                  size: Size.square(widget.size),
                  painter: _WheelPainter(
                    selected: widget.selected,
                    // Se apaga al girar y vuelve al frenar.
                    highlight: t == 0 || t >= 1,
                  ),
                ),
              ),
              CustomPaint(
                size: Size.square(widget.size),
                painter: _BallPainter(
                  angle: ballAngle,
                  settleT: settleT,
                  inset: ballInset,
                  wheelAngle: angle,
                  targetIndex: widget.targetIndex,
                ),
              ),
              _Pointer(size: widget.size),
            ],
          );
        },
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.selected, required this.highlight});

  final Set<String> selected;
  final bool highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final sector = 2 * math.pi / kRoulettePockets.length;

    // Aro exterior dorado con degradé, para que no se vea plano.
    final rim = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFCD34D), Color(0xFF92400E), Color(0xFFFCD34D),
          Color(0xFF92400E), Color(0xFFFCD34D),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, rim);

    final inner = radius * 0.90;
    final hub = radius * 0.34;

    for (var i = 0; i < kRoulettePockets.length; i++) {
      final pocket = kRoulettePockets[i];
      // -90° para que el índice 0 quede arriba, bajo el puntero.
      final start = -math.pi / 2 - sector / 2 + i * sector;

      final base = isGreenPocket(pocket)
          ? const Color(0xFF047857)
          : isRedPocket(pocket)
              ? const Color(0xFFB91C1C)
              : const Color(0xFF18181B);

      final isPicked = highlight && selected.contains(pocket);
      final paint = Paint()
        ..color = isPicked ? AppTheme.accent : base
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: inner),
        start,
        sector,
        true,
        paint,
      );

      // Separador fino entre casillas: sin esto el disco se ve como un
      // degradé continuo y se pierde la sensación de casillas.
      final divider = Paint()
        ..color = const Color(0xFFFCD34D).withValues(alpha: 0.55)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        center,
        center + Offset(math.cos(start), math.sin(start)) * inner,
        divider,
      );

      _paintNumber(canvas, center, inner, start + sector / 2, pocket, isPicked);
    }

    // Cubo central con brillo.
    canvas.drawCircle(
      center,
      hub,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFDE68A), Color(0xFF92400E)],
        ).createShader(Rect.fromCircle(center: center, radius: hub)),
    );
    canvas.drawCircle(
      center,
      hub * 0.45,
      Paint()..color = AppTheme.primaryDark,
    );
  }

  void _paintNumber(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    String text,
    bool picked,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: picked ? const Color(0xFF1F1300) : Colors.white,
          fontSize: radius * 0.095,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle + math.pi / 2);
    // Los números miran hacia afuera, como en una ruleta real.
    canvas.translate(0, -radius * 0.78);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.highlight != highlight || !setEquals(old.selected, selected);
}

class _BallPainter extends CustomPainter {
  _BallPainter({
    required this.angle,
    required this.settleT,
    required this.inset,
    required this.wheelAngle,
    required this.targetIndex,
  });

  final double angle;

  /// 0 = orbitando libre; 1 = apoyada en la casilla ganadora.
  final double settleT;
  final double inset;
  final double wheelAngle;
  final int targetIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    // Arranca pegada al borde y termina en el anillo de casillas.
    final orbit = radius * (0.82 - 0.16 * inset);

    // Posición final: justo encima de la casilla ganadora, que a esta
    // altura del giro ya quedó bajo el puntero.
    final sector = 2 * math.pi / kRoulettePockets.length;
    final restAngle = -math.pi / 2 + targetIndex * sector + wheelAngle;
    final freeAngle = angle - math.pi / 2;

    // Interpolamos por el camino más corto para que no pegue una vuelta
    // de más justo al acomodarse.
    var delta = (restAngle - freeAngle) % (2 * math.pi);
    if (delta > math.pi) delta -= 2 * math.pi;
    final a = freeAngle + delta * settleT;

    final pos = center + Offset(math.cos(a), math.sin(a)) * orbit;

    canvas.drawCircle(
      pos.translate(0, 2),
      radius * 0.035,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      pos,
      radius * 0.035,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Color(0xFFD4D4D8)],
        ).createShader(
          Rect.fromCircle(center: pos, radius: radius * 0.035),
        ),
    );
  }

  @override
  bool shouldRepaint(_BallPainter old) => true;
}

class _Pointer extends StatelessWidget {
  const _Pointer({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      child: CustomPaint(
        size: Size(size * 0.09, size * 0.09),
        painter: _PointerPainter(),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, Paint()..color = AppTheme.accent);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => false;
}
