class ServerException implements Exception {
  ServerException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  NetworkException(this.message);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  CacheException(this.message);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class NotFoundException implements Exception {
  NotFoundException();

  @override
  String toString() => 'NotFoundException';
}

/// Backend returned HTTP 403 during login: the account exists and the
/// password is right, but the admin has disabled access.
class AccessBlockedException implements Exception {
  AccessBlockedException(this.message);

  final String message;

  @override
  String toString() => 'AccessBlockedException: $message';
}
