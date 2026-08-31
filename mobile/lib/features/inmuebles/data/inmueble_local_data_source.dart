import 'package:sqflite/sqflite.dart';

import '../domain/entities/inmueble.dart';

/// Catalogo de inmuebles replicado en el dispositivo.
class InmuebleLocalDataSource {
  const InmuebleLocalDataSource(this._db);

  static const String tabla = 'inmuebles';

  final Database _db;

  /// Inserta o actualiza un lote de inmuebles provenientes del servidor.
  Future<void> upsertLote(List<Inmueble> inmuebles) async {
    if (inmuebles.isEmpty) return;
    final batch = _db.batch();
    for (final inmueble in inmuebles) {
      batch.insert(
        tabla,
        inmueble.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Consulta el catalogo con filtros opcionales.
  Future<List<Inmueble>> listar({
    String? ciudad,
    String? texto,
    TipoInmueble? tipo,
    int limite = 100,
  }) async {
    final condiciones = <String>['eliminado = 0'];
    final argumentos = <Object?>[];

    if (ciudad != null && ciudad.isNotEmpty) {
      condiciones.add('ciudad = ?');
      argumentos.add(ciudad);
    }
    if (tipo != null) {
      condiciones.add('tipo = ?');
      argumentos.add(tipo.name);
    }
    if (texto != null && texto.trim().isNotEmpty) {
      condiciones.add('(titulo LIKE ? OR direccion LIKE ? OR codigo LIKE ?)');
      final patron = '%${texto.trim()}%';
      argumentos..add(patron)..add(patron)..add(patron);
    }

    final filas = await _db.query(
      tabla,
      where: condiciones.join(' AND '),
      whereArgs: argumentos,
      orderBy: 'titulo ASC',
      limit: limite,
    );
    return filas.map(Inmueble.fromMap).toList(growable: false);
  }

  Future<Inmueble?> obtener(String id) async {
    final filas = await _db.query(
      tabla,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (filas.isEmpty) return null;
    return Inmueble.fromMap(filas.first);
  }

  Future<List<String>> ciudades() async {
    final filas = await _db.rawQuery(
      'SELECT DISTINCT ciudad FROM $tabla WHERE eliminado = 0 ORDER BY ciudad',
    );
    return filas
        .map((f) => (f['ciudad'] ?? '') as String)
        .where((c) => c.isNotEmpty)
        .toList(growable: false);
  }

  Future<int> total() async {
    final resultado =
        await _db.rawQuery('SELECT COUNT(*) AS total FROM $tabla WHERE eliminado = 0');
    return Sqflite.firstIntValue(resultado) ?? 0;
  }
}
