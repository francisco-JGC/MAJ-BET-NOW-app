import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/game.dart';
import '../../domain/usecases/get_authorized_games.dart';

class GamesController extends AsyncNotifier<List<Game>> {
  late final _getAuthorizedGames = getIt<GetAuthorizedGames>();

  @override
  Future<List<Game>> build() async {
    final result = await _getAuthorizedGames();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (games) => games,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

final gamesControllerProvider =
    AsyncNotifierProvider<GamesController, List<Game>>(GamesController.new);
