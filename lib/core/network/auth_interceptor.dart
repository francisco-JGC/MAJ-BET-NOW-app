import 'package:dio/dio.dart';

import 'token_store.dart';

/// Attaches the access token to every request, and — on 401 — attempts one
/// silent refresh before giving up and signalling the session expired.
///
/// Design notes:
/// - Refresh calls hit `/auth/refresh` via a bare Dio so the refresh itself
///   is not intercepted (no chance of infinite recursion).
/// - Concurrent 401s share the same in-flight refresh future so a burst of
///   parallel requests burns exactly one refresh call.
/// - Each original request is retried at most once (`_retried` marker in
///   RequestOptions.extra) so a persistently 401ing endpoint doesn't loop.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStore,
    required this.onRefreshed,
    required this.onSessionExpired,
  });

  final TokenStore tokenStore;

  /// Called with the fresh access token after a successful refresh so the
  /// app can persist it to secure storage. Runs before the original request
  /// is retried.
  final Future<void> Function(String newAccessToken) onRefreshed;

  /// Fired when refresh is not possible or fails — the app should log the
  /// user out and route them back to the login screen.
  final void Function() onSessionExpired;

  static const _refreshPath = '/auth/refresh';
  static const _retriedKey = '_authRetried';

  Future<String?>? _refreshInFlight;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = tokenStore.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final original = err.requestOptions;

    // Never try to refresh the refresh call itself — hard failure.
    if (original.path.endsWith(_refreshPath)) {
      onSessionExpired();
      return handler.next(err);
    }

    // Retry at most once per original request.
    if (original.extra[_retriedKey] == true) {
      onSessionExpired();
      return handler.next(err);
    }

    final refreshToken = tokenStore.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      onSessionExpired();
      return handler.next(err);
    }

    final newAccessToken = await _refreshOnce(
      baseUrl: original.baseUrl,
      refreshToken: refreshToken,
    );

    if (newAccessToken == null || newAccessToken.isEmpty) {
      onSessionExpired();
      return handler.next(err);
    }

    await onRefreshed(newAccessToken);

    try {
      original.headers['Authorization'] = 'Bearer $newAccessToken';
      original.extra[_retriedKey] = true;
      // Bare Dio so the retry doesn't re-enter this interceptor. The
      // original RequestOptions already carries method, path, body, etc.
      final retryDio = Dio();
      final retryResponse = await retryDio.fetch<dynamic>(original);
      return handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    } catch (_) {
      return handler.next(err);
    }
  }

  Future<String?> _refreshOnce({
    required String baseUrl,
    required String refreshToken,
  }) {
    final pending = _refreshInFlight;
    if (pending != null) return pending;
    final future = _doRefresh(baseUrl: baseUrl, refreshToken: refreshToken)
        .whenComplete(() {
      _refreshInFlight = null;
    });
    _refreshInFlight = future;
    return future;
  }

  Future<String?> _doRefresh({
    required String baseUrl,
    required String refreshToken,
  }) async {
    try {
      final bareDio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await bareDio.post<Map<String, dynamic>>(
        _refreshPath,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final data = response.data;
      if (data == null) return null;
      final token = data['accessToken'];
      return token is String ? token : null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
