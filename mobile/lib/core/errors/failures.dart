/// Errores de dominio de la aplicacion.
///
/// La capa de datos traduce cualquier excepcion tecnica (socket, HTTP, SQLite)
/// a una de estas fallas, de modo que la capa de presentacion nunca dependa de
/// detalles de infraestructura.
sealed class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No hay conexion o el servidor no respondio a tiempo.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexion con el servidor']);
}

/// El servidor respondio con un codigo de error.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;
}

/// Credenciales invalidas o sesion expirada.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Credenciales invalidas']);
}

/// Error al leer o escribir en la base de datos local.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Error de almacenamiento local']);
}

/// Datos que no cumplen las reglas de negocio.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
