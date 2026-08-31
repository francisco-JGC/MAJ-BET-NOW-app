import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/lucky_daily.dart';
import '../state/lucky_provider.dart';
import '../widgets/lucky_common.dart';

class CrossLuckyPage extends ConsumerStatefulWidget {
  const CrossLuckyPage({super.key});

  @override
  ConsumerState<CrossLuckyPage> createState() => _CrossLuckyPageState();
}

class _CrossLuckyPageState extends ConsumerState<CrossLuckyPage> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      luckyProvider(LuckyQuery(kind: LuckyKind.cross, date: _date)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Cruz de la Suerte')),
      body: async.when(
        loading: () => Column(
          children: [
            LuckyDateHeader(date: _date, onTap: _pickDate),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
        error: (err, _) => Column(
          children: [
            LuckyDateHeader(date: _date, onTap: _pickDate),
            Expanded(child: LuckyErrorView(message: err.toString())),
          ],
        ),
        data: (entry) {
          if (entry == null) {
            return Column(
              children: [
                LuckyDateHeader(date: _date, onTap: _pickDate),
                const Expanded(child: LuckyEmptyView()),
              ],
            );
          }
          final payload = entry.payload as CrossLuckyPayload;
          return SingleChildScrollView(
            child: Column(
              children: [
                LuckyDateHeader(date: _date, onTap: _pickDate),
                _CrossView(payload: payload),
                RecommendedSection(numbers: payload.recommended),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CrossView extends StatelessWidget {
  const _CrossView({required this.payload});

  final CrossLuckyPayload payload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, AppTheme.accentSoft],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                painter: _CrossPainter(),
                child: _CrossNumbers(payload: payload),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      colors: [Colors.red.shade400, Colors.red.shade800],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final inset = size.width * 0.14;
    canvas.drawLine(
      Offset(inset, inset),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrossNumbers extends StatelessWidget {
  const _CrossNumbers({required this.payload});

  final CrossLuckyPayload payload;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: 0, left: 0, child: _NumberBadge(value: payload.corners.tl, size: _BadgeSize.large)),
        Positioned(top: 0, right: 0, child: _NumberBadge(value: payload.corners.tr, size: _BadgeSize.large)),
        Positioned(bottom: 0, left: 0, child: _NumberBadge(value: payload.corners.bl, size: _BadgeSize.large)),
        Positioned(bottom: 0, right: 0, child: _NumberBadge(value: payload.corners.br, size: _BadgeSize.large)),
        Align(alignment: const Alignment(0, -0.55), child: _NumberBadge(value: payload.inner.n, size: _BadgeSize.medium)),
        Align(alignment: const Alignment(0.55, 0), child: _NumberBadge(value: payload.inner.e, size: _BadgeSize.medium)),
        Align(alignment: const Alignment(0, 0.55), child: _NumberBadge(value: payload.inner.s, size: _BadgeSize.medium)),
        Align(alignment: const Alignment(-0.55, 0), child: _NumberBadge(value: payload.inner.w, size: _BadgeSize.medium)),
      ],
    );
  }
}

enum _BadgeSize { medium, large }

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.value, required this.size});

  final int value;
  final _BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final side = size == _BadgeSize.large ? 52.0 : 44.0;
    final font = size == _BadgeSize.large ? 26.0 : 22.0;
    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: font,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
