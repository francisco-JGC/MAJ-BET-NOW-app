import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/date_range_field.dart';
import '../../../../core/widgets/game_draw_filter_bar.dart';
import '../../../games/domain/entities/game.dart';
import '../../../games/presentation/state/games_controller.dart';
import '../../domain/entities/winning_ticket.dart';
import '../../domain/repositories/results_repository.dart';
import '../state/winners_controller.dart';

class WinnersPage extends ConsumerWidget {
  const WinnersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(winnersControllerProvider);
    final games = ref.watch(gamesControllerProvider).value ?? const [];
    final gamesById = {for (final g in games) g.id: g};
    final filters = ref.watch(winnersFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boletos ganadores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: () =>
                ref.read(winnersControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Verificar boleto'),
        onPressed: () =>
            context.push('/reportes/boletos-ganadores/verificar'),
      ),
      bottomNavigationBar: _TotalsBar(tickets: state.value ?? const []),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Builder(builder: (context) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final endOfDay = DateTime(
                now.year,
                now.month,
                now.day,
                23,
                59,
                59,
              );
              return DateRangeField(
                from: filters.from ?? today,
                to: filters.to ?? endOfDay,
                onChanged: (from, to) => ref
                    .read(winnersFiltersProvider.notifier)
                    .set(from: from, to: to),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: GameDrawFilterBar(
              games: games,
              selectedGameId: filters.gameId,
              selectedDrawTime: filters.drawTime,
              onGameChanged: (id) => ref
                  .read(winnersFiltersProvider.notifier)
                  .setGame(id),
              onDrawTimeChanged: (t) => ref
                  .read(winnersFiltersProvider.notifier)
                  .setDrawTime(t),
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorView(
                message: err.toString(),
                onRetry: () =>
                    ref.read(winnersControllerProvider.notifier).refresh(),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(winnersControllerProvider.notifier)
                          .refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _WinnerTile(
                          ticket: items[i],
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

class _TotalsBar extends StatelessWidget {
  const _TotalsBar({required this.tickets});

  final List<WinningTicket> tickets;

  @override
  Widget build(BuildContext context) {
    var totalWon = 0;
    for (final t in tickets) {
      totalWon += t.totalPrize;
    }
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: _TotalCell(
          label: 'Total ganado por clientes',
          value: totalWon,
          color: Colors.purple.shade800,
        ),
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  const _TotalCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
        Text(
          kCurrencyFormat.format(value),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _WinnerTile extends ConsumerWidget {
  const _WinnerTile({required this.ticket, required this.game});

  final WinningTicket ticket;
  final Game? game;

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _WinnerDetailSheet(ticket: ticket, game: game),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetailSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      game?.name ?? '—',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Text(
                      kCurrencyFormat.format(ticket.totalPrize),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.purple.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '#${ticket.folio}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'Sorteo: ${dateFmt.format(ticket.drawAt.toLocal())} '
                '${formatTime12h(ticket.drawAt)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade700),
              ),
              if (ticket.client != null && ticket.client!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Cliente: ${ticket.client}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 8),
              for (final line in ticket.lines.where((l) => l.isWinner))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: Colors.green.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          [
                            if (line.subGameName != null)
                              '${line.subGameName} — ',
                            line.label,
                            ' → ganador ${line.winningNumber ?? ''}',
                          ].join(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        kCurrencyFormat.format(line.wonPrize),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinnerDetailSheet extends StatefulWidget {
  const _WinnerDetailSheet({required this.ticket, required this.game});

  final WinningTicket ticket;
  final Game? game;

  @override
  State<_WinnerDetailSheet> createState() => _WinnerDetailSheetState();
}

class _WinnerDetailSheetState extends State<_WinnerDetailSheet> {
  bool _paid = false;
  bool _paying = false;
  String? _error;

  Future<void> _pay() async {
    setState(() {
      _paying = true;
      _error = null;
    });
    final either =
        await getIt<ResultsRepository>().markAsPaid(widget.ticket.id);
    if (!mounted) return;
    either.match(
      (failure) => setState(() {
        _paying = false;
        _error = failure.message;
      }),
      (_) => setState(() {
        _paying = false;
        _paid = true;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winningLines =
        widget.ticket.lines.where((l) => l.isWinner).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.game?.name ?? '—',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Folio #${widget.ticket.folio}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Text(
                    kCurrencyFormat.format(widget.ticket.totalPrize),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.purple.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Winning lines
            Text(
              'Jugadas ganadoras',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            for (final line in winningLines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        [
                          if (line.subGameName != null)
                            '${line.subGameName} — ',
                          line.label,
                          if (line.winningNumber != null)
                            ' (sorteo: ${line.winningNumber})',
                        ].join(),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      kCurrencyFormat.format(line.wonPrize),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            // Error
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
              const SizedBox(height: 8),
            ],
            // Pay button
            if (_paid)
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Boleto marcado como pagado',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: _paying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.payments_outlined),
                  label: Text(_paying ? 'Procesando…' : 'Pagar boleto'),
                  onPressed: _paying ? null : _pay,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Sin boletos ganadores en este rango',
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
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
