import 'package:sqflite/sqflite.dart';

import '../domain/entities/outbox_item.dart';

/// Acceso a la cola de salida en SQLite.
class OutboxLocalDataSource {
  const OutboxLocalDataSource(this._db);

  static const String tabla = 'outbox';

  final Database _db;

  /// Encola una operacion. Si se pasa [txn], la insercion participa en la
  /// misma transaccion que la escritura de la entidad de negocio, lo que
  /// garantiza que dato y operacion pendiente se guarden de forma atomica.
  Future<void> encolar(OutboxItem item, {DatabaseExecutor? txn}) async {
    await (txn ?? _db).insert(
      tabla,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Operaciones listas para enviar, ordenadas por antiguedad (FIFO).
  Future<List<OutboxItem>> pendientes({
    required int ahoraMs,
    int limite = 50,
  }) async {
    final filas = await _db.query(
      tabla,
      where: 'estado IN (?, ?) AND proximo_intento_en <= ?',
      whereArgs: <Object?>[
        EstadoOutbox.pendiente.name,
        EstadoOutbox.enviando.name,
        ahoraMs,
      ],
      orderBy: 'creado_en ASC',
      limit: limite,
    );
    return filas.map(OutboxItem.fromMap).toList(growable: false);
  }

  Future<int> conteoPendientes() async {
    final resultado = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM $tabla WHERE estado IN (?, ?)',
      <Object?>[EstadoOutbox.pendiente.name, EstadoOutbox.enviando.name],
    );
    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  Future<int> conteoFallidos() async {
    final resultado = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM $tabla WHERE estado = ?',
      <Object?>[EstadoOutbox.fallido.name],
    );
    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  Future<void> marcarEnviado(String id) async {
    await _db.update(
      tabla,
      <String, Object?>{
        'estado': EstadoOutbox.enviado.name,
        'ultimo_error': null,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Registra un intento fallido y programa el siguiente reintento.
  ///
  /// Cuando [definitivo] es `true` la operacion se marca como fallida y deja
  /// de reintentarse; queda visible para el usuario en el panel de
  /// sincronizacion.
  Future<void> registrarFallo({
    required String id,
    required int intentos,
    required String error,
    required int proximoIntentoEnMs,
    required bool definitivo,
  }) async {
    await _db.update(
      tabla,
      <String, Object?>{
        'intentos': intentos,
        'ultimo_error': error,
        'proximo_intento_en': proximoIntentoEnMs,
        'estado': definitivo
            ? EstadoOutbox.fallido.name
            : EstadoOutbox.pendiente.name,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Elimina las operaciones ya confirmadas por el servidor.
  Future<int> purgarEnviados() {
    return _db.delete(
      tabla,
      where: 'estado = ?',
      whereArgs: <Object?>[EstadoOutbox.enviado.name],
    );
  }

  /// Reencola manualmente una operacion fallida (accion del usuario).
  Future<void> reintentar(String id) async {
    await _db.update(
      tabla,
      <String, Object?>{
        'estado': EstadoOutbox.pendiente.name,
        'intentos': 0,
        'proximo_intento_en': 0,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
