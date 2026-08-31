import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// Consistent date-range picker across every report screen.
///
/// Renders as a rounded card with a primary-tinted calendar icon on the left,
/// the current range formatted `dd/MM/yyyy  /  dd/MM/yyyy` (or just one date
/// when both bounds land on the same day), and a tune icon on the right that
/// hints at "tap to change". Tapping anywhere opens the platform's date
/// range picker, then calls `onChanged` with the new [from] / [to] pair
/// (end pinned to 23:59:59 so the range covers the full day).
class DateRangeField extends StatelessWidget {
  const DateRangeField({
    required this.from,
    required this.to,
    required this.onChanged,
    this.label = 'Rango de fechas',
    super.key,
  });

  final DateTime from;
  final DateTime to;
  final void Function(DateTime from, DateTime to) onChanged;
  final String label;

  bool get _sameDay =>
      from.year == to.year && from.month == to.month && from.day == to.day;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final text = _sameDay
        ? fmt.format(from)
        : '${fmt.format(from)}  /  ${fmt.format(to)}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _pickRange(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _sameDay ? 'Fecha' : label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.tune, color: AppTheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(start: from, end: to),
    );
    if (picked == null) return;
    onChanged(
      picked.start,
      DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      ),
    );
  }
}
