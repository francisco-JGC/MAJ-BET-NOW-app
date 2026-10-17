import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/game.dart';
import '../../domain/entities/game_type.dart';
import '../state/games_controller.dart';
import '../widgets/game_card.dart';

class GamesPage extends ConsumerWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gamesControllerProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: error.toString(),
        onRetry: () => ref.read(gamesControllerProvider.notifier).refresh(),
      ),
      data: (games) => _GamesGrid(games: games),
    );
  }
}

class _GamesGrid extends StatelessWidget {
  const _GamesGrid({required this.games});

  final List<Game> games;

  @override
  Widget build(BuildContext context) {
    // La ruleta se excluye de "Juegos": ya es un juego real del catálogo
    // (emite factura como cualquier otro), pero su lugar en la grilla es
    // la sección Minijuegos, con su propia tarjeta y su propia pantalla.
    final active = games
        .where((g) => g.isActive && g.type != GameType.roulette)
        .toList();
    if (active.isEmpty) {
      return const Center(child: Text('No hay juegos autorizados'));
    }

    // Dos secciones, no una lista con la ruleta pegada al final: los
    // juegos normales tienen sorteo, horario y boleto; los minijuegos se
    // juegan y se resuelven al instante. Mezclarlos en la misma grilla
    // hacía parecer que la ruleta era un juego más con las mismas reglas.
    return CustomScrollView(
      slivers: [
        const _SectionHeader(title: 'Juegos'),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid.builder(
            gridDelegate: _gridDelegate,
            itemCount: active.length,
            itemBuilder: (context, i) {
              final game = active[i];
              return GameCard(
                game: game,
                onTap: () => context.push('/juegos/${game.id}', extra: game),
              );
            },
          ),
        ),
        const _SectionHeader(title: 'Minijuegos'),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 20),
          sliver: SliverGrid(
            gridDelegate: _gridDelegate,
            delegate: SliverChildListDelegate.fixed([_RouletteCard()]),
          ),
        ),
      ],
    );
  }

  // 2 columnas: tiles más grandes, mejor legibilidad del logo del juego.
  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.05,
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.black38),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

/// Acceso a la ruleta. Mantiene el lenguaje visual de [GameCard] —misma
/// esquina, misma superposición oscura, mismo tipo de título— para que no
/// se lea como un cuerpo extraño en la grilla.
class _RouletteCard extends StatelessWidget {
  const _RouletteCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/ruleta'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/games/ruleta.webp',
                fit: BoxFit.cover,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              const Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'Ruleta',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Divider(height: 1)),
          ],
        ),
      ),
    );
  }
}
