import 'package:sqflite/sqflite.dart';

/// Almacen clave-valor para el estado del sincronizador (cursores, marcas).
class SyncMetaDataSource {
  const SyncMetaDataSource(this._db);

  static const String tabla = 'sync_meta';
  static const String claveCursor = 'cursor_pull';
  static const String claveUltimaSync = 'ultima_sync';

  final Database _db;

  Future<int> leerEntero(String clave, {int porDefecto = 0}) async {
    final filas = await _db.query(
      tabla,
      where: 'clave = ?',
      whereArgs: <Object?>[clave],
      limit: 1,
    );
    if (filas.isEmpty) return porDefecto;
    return int.tryParse((filas.first['valor'] ?? '') as String) ?? porDefecto;
  }

  Future<void> escribirEntero(String clave, int valor) async {
    await _db.insert(
      tabla,
      <String, Object?>{'clave': clave, 'valor': '$valor'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> get cursorPull => leerEntero(claveCursor);

  Future<void> guardarCursorPull(int valor) =>
      escribirEntero(claveCursor, valor);

  Future<int> get ultimaSync => leerEntero(claveUltimaSync);

  Future<void> registrarUltimaSync(int epochMs) =>
      escribirEntero(claveUltimaSync, epochMs);
}
