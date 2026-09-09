import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// Two independent date pickers rendered side-by-side: "Desde" and "Hasta".
///
/// Keeps the same external API as the former combined range picker so all
/// call sites continue to work unchanged. Both dates default to today in
/// every provider — this widget just exposes them as two separate tappable
/// fields instead of a single range sheet.
///
/// Constraints enforced automatically:
///   • "Desde" picker's lastDate is pinned to the current [to] date.
///   • "Hasta" picker's firstDate is pinned to the current [from] date.
///   • If the user picks a [from] date past [to] (shouldn't happen due to
///     the constraint, but kept as a safety net), [to] is moved forward.
///   • [to] is always pinned to 23:59:59 so the range covers the full day.
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

  /// Kept for API compatibility — no longer rendered.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateField(
            label: 'Desde',
            date: from,
            firstDate: DateTime(DateTime.now().year - 2),
            lastDate: DateTime(to.year, to.month, to.day),
            onPicked: (picked) {
              final newFrom = DateTime(picked.year, picked.month, picked.day);
              final newTo = to.isBefore(newFrom)
                  ? DateTime(picked.year, picked.month, picked.day, 23, 59, 59)
                  : to;
              onChanged(newFrom, newTo);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DateField(
            label: 'Hasta',
            date: to,
            firstDate: DateTime(from.year, from.month, from.day),
            lastDate: DateTime(DateTime.now().year + 1),
            onPicked: (picked) {
              onChanged(
                from,
                DateTime(picked.year, picked.month, picked.day, 23, 59, 59),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onPicked,
    required this.firstDate,
    required this.lastDate,
  });

  final String label;
  final DateTime date;
  final void Function(DateTime) onPicked;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: firstDate,
            lastDate: lastDate,
          );
          if (picked == null) return;
          onPicked(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.35),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      fmt.format(date),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.expand_more_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
