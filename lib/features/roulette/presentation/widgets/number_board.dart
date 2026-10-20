import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/roulette_play.dart';

/// Tablero de selección, en el orden del paño de una mesa real: 0 y 00
/// arriba, y abajo tres columnas del 1 al 36.
class NumberBoard extends StatelessWidget {
  const NumberBoard({
    required this.selected,
    required this.onToggle,
    required this.enabled,
    this.winning,
    super.key,
  });

  /// Casilla → monto apostado.
  final Map<String, int> selected;
  final ValueChanged<String> onToggle;
  final bool enabled;

  /// Casilla ganadora, para resaltarla cuando frena la rueda.
  final String? winning;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Cell(
                n: '0',
                state: _stateOf('0'),
                amount: selected['0'],
                onTap: _tap,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _Cell(
                n: '00',
                state: _stateOf('00'),
                amount: selected['00'],
                onTap: _tap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.15,
          ),
          itemCount: 36,
          itemBuilder: (context, i) {
            final n = '${i + 1}';
            return _Cell(
              n: n,
              state: _stateOf(n),
              amount: selected[n],
              onTap: _tap,
            );
          },
        ),
      ],
    );
  }

  void _tap(String n) {
    if (enabled) onToggle(n);
  }

  _CellState _stateOf(String n) {
    if (winning == n) return _CellState.winner;
    if (selected.containsKey(n)) return _CellState.selected;
    return enabled ? _CellState.idle : _CellState.locked;
  }
}

enum _CellState { idle, selected, winner, locked }

class _Cell extends StatelessWidget {
  const _Cell({
    required this.n,
    required this.state,
    required this.amount,
    required this.onTap,
  });

  final String n;
  final _CellState state;

  /// Monto apostado a esta casilla, si se eligió.
  final int? amount;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final base = isGreenPocket(n)
        ? const Color(0xFF047857)
        : isRedPocket(n)
            ? const Color(0xFFB91C1C)
            : const Color(0xFF18181B);

    final isWinner = state == _CellState.winner;
    final isSelected = state == _CellState.selected;

    return GestureDetector(
      onTap: () => onTap(n),
      // AnimatedContainer y no Container: al tocar, el color y el borde
      // viajan en vez de saltar. Es lo que hace que elegir números se
      // sienta táctil.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isWinner ? AppTheme.accent : base,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.accent
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected || isWinner
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Opacity(
          opacity: state == _CellState.locked ? 0.55 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  color: isWinner ? const Color(0xFF1F1300) : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: isSelected || isWinner ? 16 : 14,
                  height: 1.05,
                ),
                child: Text(n),
              ),
              // El monto va en la casilla y no en una lista aparte: con
              // montos distintos por número, hay que poder leer de un
              // vistazo cuánto lleva cada uno.
              if (amount != null)
                Text(
                  '$amount',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: isWinner
                        ? const Color(0xFF1F1300)
                        : AppTheme.accent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
