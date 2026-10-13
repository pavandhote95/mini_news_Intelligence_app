/// Exceptions are thrown inside the data layer only.
/// Repositories catch them and convert them into [Failure]s
/// so the domain and presentation layers never see raw exceptions.
class ServerException implements Exception {
  const ServerException({required this.message, this.statusCode, this.code});

  final String message;
  final int? statusCode;

  /// NewsAPI error code, e.g. `apiKeyInvalid`, `rateLimited`.
  final String? code;

  @override
  String toString() => 'ServerException($statusCode, $code): $message';
}

class MissingApiKeyException implements Exception {
  const MissingApiKeyException();
}

class CacheException implements Exception {
  const CacheException(this.message);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}
