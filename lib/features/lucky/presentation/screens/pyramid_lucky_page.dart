import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/lucky_daily.dart';
import '../state/lucky_provider.dart';
import '../widgets/lucky_common.dart';

class PyramidLuckyPage extends ConsumerStatefulWidget {
  const PyramidLuckyPage({super.key});

  @override
  ConsumerState<PyramidLuckyPage> createState() => _PyramidLuckyPageState();
}

class _PyramidLuckyPageState extends ConsumerState<PyramidLuckyPage> {
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
      luckyProvider(LuckyQuery(kind: LuckyKind.pyramid, date: _date)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Pirámide de la Suerte')),
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
          final payload = entry.payload as PyramidLuckyPayload;
          return SingleChildScrollView(
            child: Column(
              children: [
                LuckyDateHeader(date: _date, onTap: _pickDate),
                _PyramidView(payload: payload),
                RecommendedSection(numbers: payload.recommended),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PyramidView extends StatelessWidget {
  const _PyramidView({required this.payload});

  final PyramidLuckyPayload payload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, AppTheme.accentSoft],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
        child: Column(
          children: [
            for (final row in payload.rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row
                      .map<Widget>((n) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3),
                            child: _NumberDot(value: n),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NumberDot extends StatelessWidget {
  const _NumberDot({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accent, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
    );
  }
}
