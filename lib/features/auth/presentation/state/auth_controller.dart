import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/session_events.dart';
import '../../domain/usecases/load_session.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import 'auth_state.dart';

class AuthController extends Notifier<AuthState> {
  late final _login = getIt<Login>();
  late final _logout = getIt<Logout>();
  late final _loadSession = getIt<LoadSession>();

  StreamSubscription<void>? _expirySub;

  @override
  AuthState build() {
    final events = getIt<SessionEvents>();
    _expirySub = events.onExpired.listen((_) => expireSession());
    ref.onDispose(() => _expirySub?.cancel());
    Future.microtask(_bootstrap);
    return const AuthState.loading();
  }

  Future<void> _bootstrap() async {
    final result = await _loadSession();
    result.match(
      (_) => state = const AuthState.unauthenticated(),
      (session) => state = session == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(session),
    );
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await _login(
      LoginParams(username: username, password: password),
    );
    result.match(
      (failure) => state = AuthState.unauthenticated(
        errorMessage: failure.message,
        isBlocked: failure is AccessBlockedFailure,
      ),
      (session) => state = AuthState.authenticated(session),
    );
  }

  Future<void> signOut() async {
    await _logout();
    state = const AuthState.unauthenticated();
  }

  void expireSession() {
    if (state.isAuthenticated) {
      state = const AuthState.unauthenticated(errorMessage: 'Sesión expirada');
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
