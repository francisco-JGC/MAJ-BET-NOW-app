import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/game.dart';
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
    if (games.isEmpty) {
      return const Center(child: Text('No hay juegos autorizados'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: games.length,
      itemBuilder: (context, i) {
        final game = games[i];
        return GameCard(
          game: game,
          onTap: () {
            if (!game.isActive) {
              _showInactiveSnack(context, game.name);
              return;
            }
            context.push('/juegos/${game.id}', extra: game);
          },
        );
      },
    );
  }

  static void _showInactiveSnack(BuildContext context, String gameName) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('$gameName no está disponible por los momentos.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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
