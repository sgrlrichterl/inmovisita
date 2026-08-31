import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../sync/data/outbox_local_data_source.dart';
import '../../sync/domain/entities/outbox_item.dart';
import '../domain/entities/visita.dart';

/// Persistencia local de visitas y su evidencia fotografica.
///
/// Cada escritura de negocio se guarda junto con su operacion de salida en una
/// unica transaccion (patron Outbox transaccional).
class VisitaLocalDataSource {
  VisitaLocalDataSource(this._db, this._outbox, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  static const String tabla = 'visitas';
  static const String tablaFotos = 'visita_fotos';

  static const String _selectConFotos = '''
    SELECT v.*,
           (SELECT COUNT(*) FROM $tablaFotos f WHERE f.visita_id = v.id)
             AS total_fotos
    FROM $tabla v
  ''';

  final Database _db;
  final OutboxLocalDataSource _outbox;
  final Uuid _uuid;

  /// Guarda una visita y encola su envio al servidor.
  Future<void> guardar(
    Visita visita, {
    OperacionOutbox operacion = OperacionOutbox.crear,
    bool encolar = true,
  }) async {
    await _db.transaction((txn) async {
      await txn.insert(
        tabla,
        visita.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (encolar) {
        await _outbox.encolar(
          OutboxItem(
            id: _uuid.v4(),
            entidad: 'visitas',
            entidadId: visita.id,
            operacion: operacion,
            payload: visita.toJson(),
            creadoEn: DateTime.now().millisecondsSinceEpoch,
          ),
          txn: txn,
        );
      }
    });
  }

  /// Aplica una visita recibida del servidor sin generar cola de salida.
  Future<void> aplicarDesdeRemoto(Visita visita) async {
    await _db.insert(
      tabla,
      visita.copyWith(syncState: EstadoSync.sincronizado).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Visita>> listar({
    String? asesorUid,
    EstadoSync? syncState,
    int limite = 200,
  }) async {
    final condiciones = <String>['v.eliminado = 0'];
    final argumentos = <Object?>[];
    if (asesorUid != null) {
      condiciones.add('v.asesor_uid = ?');
      argumentos.add(asesorUid);
    }
    if (syncState != null) {
      condiciones.add('v.sync_state = ?');
      argumentos.add(syncState.name);
    }
    final filas = await _db.rawQuery(
      '$_selectConFotos WHERE ${condiciones.join(' AND ')} '
      'ORDER BY v.fecha_registro DESC LIMIT ?',
      <Object?>[...argumentos, limite],
    );
    return filas.map(Visita.fromMap).toList(growable: false);
  }

  Future<Visita?> obtener(String id) async {
    final filas = await _db.rawQuery(
      '$_selectConFotos WHERE v.id = ? LIMIT 1',
      <Object?>[id],
    );
    if (filas.isEmpty) return null;
    return Visita.fromMap(filas.first);
  }

  /// Marca la visita como confirmada por el servidor.
  Future<void> marcarSincronizada({
    required String id,
    required int revision,
    required int updatedAt,
  }) async {
    await _db.update(
      tabla,
      <String, Object?>{
        'sync_state': EstadoSync.sincronizado.name,
        'revision': revision,
        'updated_at': updatedAt,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> marcarError(String id) async {
    await _db.update(
      tabla,
      <String, Object?>{'sync_state': EstadoSync.error.name},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<String> agregarFoto({
    required String visitaId,
    required String rutaLocal,
  }) async {
    final id = _uuid.v4();
    await _db.insert(tablaFotos, <String, Object?>{
      'id': id,
      'visita_id': visitaId,
      'ruta_local': rutaLocal,
      'url_remota': null,
      'subida': 0,
      'creada_en': DateTime.now().millisecondsSinceEpoch,
    });
    return id;
  }

  Future<List<Map<String, Object?>>> fotosDe(String visitaId) {
    return _db.query(
      tablaFotos,
      where: 'visita_id = ?',
      whereArgs: <Object?>[visitaId],
      orderBy: 'creada_en ASC',
    );
  }

  /// Indicadores para el panel del asesor.
  Future<Map<String, int>> resumen({String? asesorUid}) async {
    final where = asesorUid == null ? '' : 'AND asesor_uid = ?';
    final args = <Object?>[if (asesorUid != null) asesorUid];
    final filas = await _db.rawQuery('''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN temperatura = 'caliente' THEN 1 ELSE 0 END) AS calientes,
        SUM(CASE WHEN sync_state = 'pendiente' THEN 1 ELSE 0 END) AS pendientes
      FROM $tabla
      WHERE eliminado = 0 $where
    ''', args);

    final fila = filas.isEmpty ? const <String, Object?>{} : filas.first;
    int leer(String clave) {
      final valor = fila[clave];
      if (valor is int) return valor;
      if (valor is num) return valor.toInt();
      return 0;
    }

    return <String, int>{
      'total': leer('total'),
      'calientes': leer('calientes'),
      'pendientes': leer('pendientes'),
    };
  }
}
