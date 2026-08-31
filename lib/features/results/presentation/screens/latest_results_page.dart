import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/date_range_field.dart';
import '../../../games/domain/entities/game.dart';
import '../../../games/presentation/state/games_controller.dart';
import '../../domain/entities/draw_result.dart';
import '../state/latest_results_controller.dart';

class LatestResultsPage extends ConsumerWidget {
  const LatestResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(latestResultsControllerProvider);
    final games = ref.watch(gamesControllerProvider).value ?? const [];
    final gamesById = {for (final g in games) g.id: g};
    final filters = ref.watch(latestResultsFiltersProvider);

    final now = DateTime.now();
    final defaultFrom = DateTime(now.year, now.month, now.day);
    final defaultTo = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Últimos Resultados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: () => ref
                .read(latestResultsControllerProvider.notifier)
                .refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DateRangeField(
              from: filters.from ?? defaultFrom,
              to: filters.to ?? defaultTo,
              onChanged: (from, to) => ref
                  .read(latestResultsFiltersProvider.notifier)
                  .update(from: from, to: to),
            ),
          ),
          _GameFilterBar(games: games, filters: filters),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorView(
                message: err.toString(),
                onRetry: () => ref
                    .read(latestResultsControllerProvider.notifier)
                    .refresh(),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(latestResultsControllerProvider.notifier)
                          .refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _ResultCard(
                          result: items[i],
                          game: gamesById[items[i].gameId],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameFilterBar extends ConsumerWidget {
  const _GameFilterBar({required this.games, required this.filters});

  final List<Game> games;
  final LatestResultsFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = filters.gameId == null
        ? null
        : games
            .where((g) => g.id == filters.gameId)
            .fold<Game?>(null, (acc, g) => acc ?? g);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openGamePicker(context, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.videogame_asset_outlined,
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  'Juego:',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    selected?.name ?? 'Todos',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (selected != null)
                  InkWell(
                    onTap: () => ref
                        .read(latestResultsFiltersProvider.notifier)
                        .update(clearGame: true),
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 16),
                    ),
                  ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openGamePicker(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<_GamePick>(
      context: context,
      showDragHandle: true,
      builder: (_) => _GamePickerSheet(
        games: games,
        currentId: filters.gameId,
      ),
    );
    if (picked == null) return;
    if (picked.clear) {
      ref.read(latestResultsFiltersProvider.notifier).update(clearGame: true);
    } else if (picked.gameId != null) {
      ref
          .read(latestResultsFiltersProvider.notifier)
          .update(gameId: picked.gameId);
    }
  }
}

class _GamePick {
  const _GamePick({this.gameId, this.clear = false});
  final String? gameId;
  final bool clear;
}

class _GamePickerSheet extends StatelessWidget {
  const _GamePickerSheet({required this.games, required this.currentId});

  final List<Game> games;
  final String? currentId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Filtrar por juego',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.public,
                color: currentId == null ? AppTheme.primary : Colors.grey,
              ),
              title: const Text('Todos los juegos'),
              trailing: currentId == null
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () =>
                  Navigator.of(context).pop(const _GamePick(clear: true)),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: games.length,
                itemBuilder: (context, i) {
                  final g = games[i];
                  final selected = g.id == currentId;
                  return ListTile(
                    leading: Icon(
                      Icons.videogame_asset_outlined,
                      color: selected ? AppTheme.primary : Colors.grey.shade500,
                    ),
                    title: Text(g.name),
                    trailing: selected
                        ? const Icon(Icons.check, color: AppTheme.primary)
                        : null,
                    onTap: () =>
                        Navigator.of(context).pop(_GamePick(gameId: g.id)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.game});

  final DrawResult result;
  final Game? game;

  @override
  Widget build(BuildContext context) {
    final dayFmt = DateFormat('EEE, d MMMM', 'es');
    final dayLabel = dayFmt.format(result.drawAt.toLocal());
    final timeLabel = formatTime12h(result.drawAt).toUpperCase();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              gameName: game?.name ?? '—',
              winningNumber: result.winningNumber,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MetaRow(
                    icon: Icons.access_time_rounded,
                    label: 'Sorteo',
                    value: timeLabel,
                  ),
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.calendar_month_outlined,
                    label: 'Fecha',
                    value: dayLabel,
                  ),
                ],
              ),
            ),
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.gameName, required this.winningNumber});

  final String gameName;
  final String winningNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              gameName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              winningNumber,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_outlined, size: 44, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No hay resultados en el rango seleccionado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
