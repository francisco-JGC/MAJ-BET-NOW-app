import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lluvia de confeti para el momento de ganar.
///
/// Es un sistema de partículas propio en vez de un paquete: son ~80
/// rectángulos con gravedad y rotación, no justifica sumar una dependencia
/// a una app que ya está en producción.
class ConfettiOverlay extends StatelessWidget {
  const ConfettiOverlay({required this.controller, super.key});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(progress: controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  _Particle(math.Random r)
      : x = r.nextDouble(),
        // Arrancan apenas arriba del borde, escalonadas, para que no
        // entren todas en el mismo frame.
        delay = r.nextDouble() * 0.25,
        drift = (r.nextDouble() - 0.5) * 0.4,
        spin = (r.nextDouble() - 0.5) * 14,
        size = 6 + r.nextDouble() * 8,
        color = _palette[r.nextInt(_palette.length)],
        aspect = 0.4 + r.nextDouble() * 0.8;

  final double x;
  final double delay;
  final double drift;
  final double spin;
  final double size;
  final Color color;
  final double aspect;

  static const _palette = [
    Color(0xFFEAB308), // dorado
    Color(0xFF7C3AED), // violeta de marca
    Color(0xFFF472B6),
    Color(0xFF34D399),
    Color(0xFFFFFFFF),
    Color(0xFFEF4444),
  ];
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress})
      : _particles = List.generate(
          80,
          // Semilla fija: el confeti se ve igual en cada victoria, pero
          // disperso. Sin semilla, cada repintado reubicaría todo y
          // parecería ruido en vez de caída.
          (i) => _Particle(math.Random(i * 7919)),
        );

  final double progress;
  final List<_Particle> _particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      // Caída con aceleración + deriva lateral.
      final y = (t * t * 1.15 - 0.1) * size.height;
      final x = (p.x + p.drift * t) * size.width;
      // Se desvanecen sobre el final para que no corten de golpe.
      final opacity = t > 0.8 ? (1 - (t - 0.8) / 0.2) : 1.0;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * p.aspect,
        ),
        Paint()..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
