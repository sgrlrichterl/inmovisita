import 'dart:convert';

/// Estado del ciclo de vida de una visita.
enum EstadoVisita {
  borrador,
  registrada,
  cancelada;

  static EstadoVisita fromString(String? value) {
    return EstadoVisita.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoVisita.borrador,
    );
  }
}

/// Estado de sincronizacion del registro con la nube.
enum EstadoSync {
  pendiente,
  sincronizado,
  error;

  static EstadoSync fromString(String? value) {
    return EstadoSync.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoSync.pendiente,
    );
  }
}

/// Clasificacion comercial derivada del puntaje del lead.
enum TemperaturaLead {
  frio,
  tibio,
  caliente;

  static TemperaturaLead fromString(String? value) {
    return TemperaturaLead.values.firstWhere(
      (t) => t.name == value,
      orElse: () => TemperaturaLead.frio,
    );
  }

  String get etiqueta => switch (this) {
        TemperaturaLead.frio => 'Frio',
        TemperaturaLead.tibio => 'Tibio',
        TemperaturaLead.caliente => 'Caliente',
      };
}

/// Items estandar del checklist que el asesor diligencia durante la visita.
class ItemsChecklist {
  const ItemsChecklist._();

  static const String documentosVerificados = 'documentos_verificados';
  static const String estadoFisicoRevisado = 'estado_fisico_revisado';
  static const String zonasComunesMostradas = 'zonas_comunes_mostradas';
  static const String serviciosPublicosOk = 'servicios_publicos_ok';
  static const String parqueaderoVerificado = 'parqueadero_verificado';
  static const String clienteFirmoAsistencia = 'cliente_firmo_asistencia';

  static const List<String> todos = <String>[
    documentosVerificados,
    estadoFisicoRevisado,
    zonasComunesMostradas,
    serviciosPublicosOk,
    parqueaderoVerificado,
    clienteFirmoAsistencia,
  ];

  static const Map<String, String> etiquetas = <String, String>{
    documentosVerificados: 'Documentos del inmueble verificados',
    estadoFisicoRevisado: 'Estado fisico revisado con el cliente',
    zonasComunesMostradas: 'Zonas comunes mostradas',
    serviciosPublicosOk: 'Servicios publicos funcionando',
    parqueaderoVerificado: 'Parqueadero / deposito verificado',
    clienteFirmoAsistencia: 'Cliente firmo la asistencia',
  };

  static Map<String, bool> vacio() => <String, bool>{
        for (final item in todos) item: false,
      };
}

/// Registro de una visita realizada en campo.
///
/// Es la entidad central del sistema: se crea siempre en el dispositivo (con
/// un identificador UUID generado localmente, lo que hace la operacion
/// idempotente frente a reintentos) y luego se propaga a la nube.
class Visita {
  const Visita({
    required this.id,
    required this.inmuebleId,
    required this.asesorUid,
    required this.clienteNombre,
    required this.clienteTelefono,
    required this.fechaProgramada,
    required this.fechaRegistro,
    this.clienteEmail,
    this.duracionMin = 0,
    this.estado = EstadoVisita.borrador,
    this.checklist = const <String, bool>{},
    this.observaciones,
    this.nivelInteres = 0,
    this.presupuestoMax = 0,
    this.tieneCredito = false,
    this.latitud,
    this.longitud,
    this.firmaPath,
    this.scoreLead = 0,
    this.temperatura = TemperaturaLead.frio,
    this.revision = 1,
    this.updatedAt = 0,
    this.syncState = EstadoSync.pendiente,
    this.eliminado = false,
    this.totalFotos = 0,
  });

  factory Visita.fromMap(Map<String, Object?> map) {
    return Visita(
      id: map['id']! as String,
      inmuebleId: (map['inmueble_id'] ?? '') as String,
      asesorUid: (map['asesor_uid'] ?? '') as String,
      clienteNombre: (map['cliente_nombre'] ?? '') as String,
      clienteTelefono: (map['cliente_telefono'] ?? '') as String,
      clienteEmail: map['cliente_email'] as String?,
      fechaProgramada: _toInt(map['fecha_programada']),
      fechaRegistro: _toInt(map['fecha_registro']),
      duracionMin: _toInt(map['duracion_min']),
      estado: EstadoVisita.fromString(map['estado'] as String?),
      checklist: decodificarChecklist(map['checklist'] as String?),
      observaciones: map['observaciones'] as String?,
      nivelInteres: _toInt(map['nivel_interes']),
      presupuestoMax: _toDouble(map['presupuesto_max']),
      tieneCredito: _toInt(map['tiene_credito']) == 1,
      latitud: map['latitud'] == null ? null : _toDouble(map['latitud']),
      longitud: map['longitud'] == null ? null : _toDouble(map['longitud']),
      firmaPath: map['firma_path'] as String?,
      scoreLead: _toInt(map['score_lead']),
      temperatura: TemperaturaLead.fromString(map['temperatura'] as String?),
      revision: _toInt(map['revision']),
      updatedAt: _toInt(map['updated_at']),
      syncState: EstadoSync.fromString(map['sync_state'] as String?),
      eliminado: _toInt(map['eliminado']) == 1,
      totalFotos: _toInt(map['total_fotos']),
    );
  }

  factory Visita.fromJson(Map<String, dynamic> json) {
    final checklist = json['checklist'];
    return Visita(
      id: json['id']! as String,
      inmuebleId: (json['inmuebleId'] ?? '') as String,
      asesorUid: (json['asesorUid'] ?? '') as String,
      clienteNombre: (json['clienteNombre'] ?? '') as String,
      clienteTelefono: (json['clienteTelefono'] ?? '') as String,
      clienteEmail: json['clienteEmail'] as String?,
      fechaProgramada: _toInt(json['fechaProgramada']),
      fechaRegistro: _toInt(json['fechaRegistro']),
      duracionMin: _toInt(json['duracionMin']),
      estado: EstadoVisita.fromString(json['estado'] as String?),
      checklist: checklist is Map
          ? checklist.map(
              (key, value) => MapEntry(key.toString(), value == true),
            )
          : const <String, bool>{},
      observaciones: json['observaciones'] as String?,
      nivelInteres: _toInt(json['nivelInteres']),
      presupuestoMax: _toDouble(json['presupuestoMax']),
      tieneCredito: json['tieneCredito'] == true,
      latitud: json['latitud'] == null ? null : _toDouble(json['latitud']),
      longitud: json['longitud'] == null ? null : _toDouble(json['longitud']),
      scoreLead: _toInt(json['scoreLead']),
      temperatura: TemperaturaLead.fromString(json['temperatura'] as String?),
      revision: _toInt(json['revision']),
      updatedAt: _toInt(json['updatedAt']),
      syncState: EstadoSync.sincronizado,
      eliminado: json['eliminado'] == true,
    );
  }

  final String id;
  final String inmuebleId;
  final String asesorUid;
  final String clienteNombre;
  final String clienteTelefono;
  final String? clienteEmail;
  final int fechaProgramada;
  final int fechaRegistro;
  final int duracionMin;
  final EstadoVisita estado;
  final Map<String, bool> checklist;
  final String? observaciones;

  /// Interes manifestado por el cliente, en escala de 0 a 5.
  final int nivelInteres;
  final double presupuestoMax;
  final bool tieneCredito;
  final double? latitud;
  final double? longitud;
  final String? firmaPath;
  final int scoreLead;
  final TemperaturaLead temperatura;

  /// Contador monotono usado para resolver conflictos de escritura.
  final int revision;
  final int updatedAt;
  final EstadoSync syncState;
  final bool eliminado;

  /// Campo derivado (no persistido en la tabla `visitas`).
  final int totalFotos;

  int get itemsChecklistCompletados =>
      checklist.values.where((marcado) => marcado).length;

  double get porcentajeChecklist {
    if (ItemsChecklist.todos.isEmpty) return 0;
    return itemsChecklistCompletados / ItemsChecklist.todos.length;
  }

  Visita copyWith({
    String? clienteNombre,
    String? clienteTelefono,
    String? clienteEmail,
    int? duracionMin,
    EstadoVisita? estado,
    Map<String, bool>? checklist,
    String? observaciones,
    int? nivelInteres,
    double? presupuestoMax,
    bool? tieneCredito,
    double? latitud,
    double? longitud,
    String? firmaPath,
    int? scoreLead,
    TemperaturaLead? temperatura,
    int? revision,
    int? updatedAt,
    EstadoSync? syncState,
    bool? eliminado,
    int? totalFotos,
  }) {
    return Visita(
      id: id,
      inmuebleId: inmuebleId,
      asesorUid: asesorUid,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      clienteEmail: clienteEmail ?? this.clienteEmail,
      fechaProgramada: fechaProgramada,
      fechaRegistro: fechaRegistro,
      duracionMin: duracionMin ?? this.duracionMin,
      estado: estado ?? this.estado,
      checklist: checklist ?? this.checklist,
      observaciones: observaciones ?? this.observaciones,
      nivelInteres: nivelInteres ?? this.nivelInteres,
      presupuestoMax: presupuestoMax ?? this.presupuestoMax,
      tieneCredito: tieneCredito ?? this.tieneCredito,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      firmaPath: firmaPath ?? this.firmaPath,
      scoreLead: scoreLead ?? this.scoreLead,
      temperatura: temperatura ?? this.temperatura,
      revision: revision ?? this.revision,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      eliminado: eliminado ?? this.eliminado,
      totalFotos: totalFotos ?? this.totalFotos,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'inmueble_id': inmuebleId,
        'asesor_uid': asesorUid,
        'cliente_nombre': clienteNombre,
        'cliente_telefono': clienteTelefono,
        'cliente_email': clienteEmail,
        'fecha_programada': fechaProgramada,
        'fecha_registro': fechaRegistro,
        'duracion_min': duracionMin,
        'estado': estado.name,
        'checklist': jsonEncode(checklist),
        'observaciones': observaciones,
        'nivel_interes': nivelInteres,
        'presupuesto_max': presupuestoMax,
        'tiene_credito': tieneCredito ? 1 : 0,
        'latitud': latitud,
        'longitud': longitud,
        'firma_path': firmaPath,
        'score_lead': scoreLead,
        'temperatura': temperatura.name,
        'revision': revision,
        'updated_at': updatedAt,
        'sync_state': syncState.name,
        'eliminado': eliminado ? 1 : 0,
      };

  /// Representacion enviada a la API (claves en camelCase).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'inmuebleId': inmuebleId,
        'asesorUid': asesorUid,
        'clienteNombre': clienteNombre,
        'clienteTelefono': clienteTelefono,
        'clienteEmail': clienteEmail,
        'fechaProgramada': fechaProgramada,
        'fechaRegistro': fechaRegistro,
        'duracionMin': duracionMin,
        'estado': estado.name,
        'checklist': checklist,
        'observaciones': observaciones,
        'nivelInteres': nivelInteres,
        'presupuestoMax': presupuestoMax,
        'tieneCredito': tieneCredito,
        'latitud': latitud,
        'longitud': longitud,
        'revision': revision,
        'updatedAt': updatedAt,
        'eliminado': eliminado,
      };

  static Map<String, bool> decodificarChecklist(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <String, bool>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value == true),
        );
      }
    } on FormatException {
      return <String, bool>{};
    }
    return <String, bool>{};
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
