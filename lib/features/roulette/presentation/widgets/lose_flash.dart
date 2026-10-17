import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Destello rojo en los bordes al perder.
///
/// Es la contraparte del confeti: antes ganar tenía una celebración y
/// perder no tenía nada, así que la tirada perdida se sentía como si la
/// app no hubiera respondido. Un vignette corto evita eso sin castigar al
/// jugador con algo estridente.
class LoseFlash extends StatelessWidget {
  const LoseFlash({required this.controller, super.key});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => CustomPaint(
          painter: _VignettePainter(progress: controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _VignettePainter extends CustomPainter {
  _VignettePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    // Sube rápido y baja lento: el golpe se siente, el resto se disuelve.
    final intensity = progress < 0.25
        ? progress / 0.25
        : 1 - ((progress - 0.25) / 0.75);

    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [
            Colors.transparent,
            const Color(0xFFDC2626).withValues(alpha: 0.42 * intensity),
          ],
          stops: const [0.55, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_VignettePainter old) => old.progress != progress;
}

/// Sacudida horizontal amortiguada, para el cartel de resultado.
///
/// La amplitud decae con el progreso: arranca marcada y se va apagando,
/// como algo que realmente se sacudió y se frena solo.
class ShakeTransition extends StatelessWidget {
  const ShakeTransition({
    required this.controller,
    required this.child,
    this.amplitude = 11,
    this.oscillations = 3,
    super.key,
  });

  final Animation<double> controller;
  final Widget child;
  final double amplitude;
  final int oscillations;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, c) {
        final t = controller.value;
        if (t == 0 || t >= 1) return c!;
        final decay = 1 - t;
        final dx = math.sin(t * math.pi * 2 * oscillations) * amplitude * decay;
        return Transform.translate(offset: Offset(dx, 0), child: c);
      },
      child: child,
    );
  }
}
