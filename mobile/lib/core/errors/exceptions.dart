/// Excepciones tecnicas lanzadas por los data sources.
///
/// Nunca cruzan la frontera de la capa de datos: los repositorios las
/// convierten en `Failure` (ver `core/errors/failures.dart`).
class ServerException implements Exception {
  ServerException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  NetworkException([this.message = 'No fue posible alcanzar el servidor']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException implements Exception {
  UnauthorizedException([this.message = 'Token invalido o expirado']);

  final String message;

  @override
  String toString() => 'UnauthorizedException: $message';
}

class CacheException implements Exception {
  CacheException(this.message);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}
