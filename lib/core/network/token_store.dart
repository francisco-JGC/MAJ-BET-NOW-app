/// In-memory holder for the current session's tokens.
///
/// Persistence lives in `AuthLocalDatasource`; this class exists only so
/// synchronous, non-async-friendly consumers (the Dio interceptor on the
/// hot path of every request) can read the current token without awaiting
/// secure storage.
class TokenStore {
  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  void setTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// Called by the interceptor after a successful silent refresh. Refresh
  /// token stays the same — the backend only rotates the short-lived one.
  void updateAccessToken(String accessToken) {
    _accessToken = accessToken;
  }

  void clear() {
    _accessToken = null;
    _refreshToken = null;
  }
}
