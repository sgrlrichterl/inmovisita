import 'dart:convert';

/// Operacion remota pendiente de aplicar.
enum OperacionOutbox {
  crear,
  actualizar,
  eliminar;

  static OperacionOutbox fromString(String? value) {
    return OperacionOutbox.values.firstWhere(
      (o) => o.name == value,
      orElse: () => OperacionOutbox.actualizar,
    );
  }
}

/// Estado de un elemento dentro de la cola de salida.
enum EstadoOutbox {
  pendiente,
  enviando,
  enviado,
  fallido;

  static EstadoOutbox fromString(String? value) {
    return EstadoOutbox.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoOutbox.pendiente,
    );
  }
}

/// Elemento de la cola de salida (patron *Outbox*).
///
/// Toda escritura local produce un item en esta cola dentro de la misma
/// transaccion SQLite que modifica la entidad. Asi la aplicacion nunca pierde
/// una operacion aunque el proceso muera antes de sincronizar.
class OutboxItem {
  const OutboxItem({
    required this.id,
    required this.entidad,
    required this.entidadId,
    required this.operacion,
    required this.payload,
    required this.creadoEn,
    this.intentos = 0,
    this.ultimoError,
    this.proximoIntentoEn = 0,
    this.estado = EstadoOutbox.pendiente,
  });

  factory OutboxItem.fromMap(Map<String, Object?> map) {
    final rawPayload = (map['payload'] ?? '{}') as String;
    final decoded = jsonDecode(rawPayload);
    return OutboxItem(
      id: map['id']! as String,
      entidad: (map['entidad'] ?? '') as String,
      entidadId: (map['entidad_id'] ?? '') as String,
      operacion: OperacionOutbox.fromString(map['operacion'] as String?),
      payload: decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded},
      intentos: (map['intentos'] ?? 0) as int,
      ultimoError: map['ultimo_error'] as String?,
      creadoEn: (map['creado_en'] ?? 0) as int,
      proximoIntentoEn: (map['proximo_intento_en'] ?? 0) as int,
      estado: EstadoOutbox.fromString(map['estado'] as String?),
    );
  }

  final String id;

  /// Nombre logico de la coleccion remota: `visitas`, `fotos`, ...
  final String entidad;
  final String entidadId;
  final OperacionOutbox operacion;
  final Map<String, dynamic> payload;
  final int intentos;
  final String? ultimoError;
  final int creadoEn;
  final int proximoIntentoEn;
  final EstadoOutbox estado;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'entidad': entidad,
        'entidad_id': entidadId,
        'operacion': operacion.name,
        'payload': jsonEncode(payload),
        'intentos': intentos,
        'ultimo_error': ultimoError,
        'creado_en': creadoEn,
        'proximo_intento_en': proximoIntentoEn,
        'estado': estado.name,
      };

  /// Cuerpo que se envia al endpoint `POST /v1/sync/push`.
  Map<String, dynamic> toEnvelope() => <String, dynamic>{
        'operacionId': id,
        'entidad': entidad,
        'entidadId': entidadId,
        'operacion': operacion.name,
        'payload': payload,
      };
}
