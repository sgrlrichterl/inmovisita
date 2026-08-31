/// Tipo comercial del inmueble.
enum TipoInmueble {
  apartamento,
  casa,
  local,
  oficina,
  lote,
  bodega;

  static TipoInmueble fromString(String? value) {
    return TipoInmueble.values.firstWhere(
      (t) => t.name == value,
      orElse: () => TipoInmueble.apartamento,
    );
  }

  String get etiqueta => switch (this) {
        TipoInmueble.apartamento => 'Apartamento',
        TipoInmueble.casa => 'Casa',
        TipoInmueble.local => 'Local comercial',
        TipoInmueble.oficina => 'Oficina',
        TipoInmueble.lote => 'Lote',
        TipoInmueble.bodega => 'Bodega',
      };
}

/// Inmueble del catalogo que el asesor muestra en campo.
///
/// El catalogo se replica completo en el dispositivo para que la consulta
/// funcione sin red; solo se descargan los registros modificados desde la
/// ultima sincronizacion (sincronizacion delta por `updatedAt`).
class Inmueble {
  const Inmueble({
    required this.id,
    required this.codigo,
    required this.titulo,
    required this.direccion,
    required this.ciudad,
    required this.tipo,
    required this.precio,
    required this.areaM2,
    required this.habitaciones,
    required this.banos,
    required this.updatedAt,
    this.barrio,
    this.estado = 'disponible',
    this.latitud,
    this.longitud,
    this.fotoUrl,
    this.revision = 1,
    this.eliminado = false,
  });

  factory Inmueble.fromMap(Map<String, Object?> map) {
    return Inmueble(
      id: map['id']! as String,
      codigo: (map['codigo'] ?? '') as String,
      titulo: (map['titulo'] ?? '') as String,
      direccion: (map['direccion'] ?? '') as String,
      ciudad: (map['ciudad'] ?? '') as String,
      barrio: map['barrio'] as String?,
      tipo: TipoInmueble.fromString(map['tipo'] as String?),
      precio: _toDouble(map['precio']),
      areaM2: _toDouble(map['area_m2']),
      habitaciones: _toInt(map['habitaciones']),
      banos: _toInt(map['banos']),
      estado: (map['estado'] ?? 'disponible') as String,
      latitud: map['latitud'] == null ? null : _toDouble(map['latitud']),
      longitud: map['longitud'] == null ? null : _toDouble(map['longitud']),
      fotoUrl: map['foto_url'] as String?,
      revision: _toInt(map['revision']),
      updatedAt: _toInt(map['updated_at']),
      eliminado: _toInt(map['eliminado']) == 1,
    );
  }

  /// Construye la entidad desde la representacion JSON de la API.
  factory Inmueble.fromJson(Map<String, dynamic> json) {
    return Inmueble(
      id: json['id']! as String,
      codigo: (json['codigo'] ?? '') as String,
      titulo: (json['titulo'] ?? '') as String,
      direccion: (json['direccion'] ?? '') as String,
      ciudad: (json['ciudad'] ?? '') as String,
      barrio: json['barrio'] as String?,
      tipo: TipoInmueble.fromString(json['tipo'] as String?),
      precio: _toDouble(json['precio']),
      areaM2: _toDouble(json['areaM2']),
      habitaciones: _toInt(json['habitaciones']),
      banos: _toInt(json['banos']),
      estado: (json['estado'] ?? 'disponible') as String,
      latitud: json['latitud'] == null ? null : _toDouble(json['latitud']),
      longitud: json['longitud'] == null ? null : _toDouble(json['longitud']),
      fotoUrl: json['fotoUrl'] as String?,
      revision: _toInt(json['revision']),
      updatedAt: _toInt(json['updatedAt']),
      eliminado: json['eliminado'] == true,
    );
  }

  final String id;
  final String codigo;
  final String titulo;
  final String direccion;
  final String ciudad;
  final String? barrio;
  final TipoInmueble tipo;
  final double precio;
  final double areaM2;
  final int habitaciones;
  final int banos;
  final String estado;
  final double? latitud;
  final double? longitud;
  final String? fotoUrl;
  final int revision;
  final int updatedAt;
  final bool eliminado;

  bool get disponible => estado == 'disponible' && !eliminado;

  double get precioPorM2 => areaM2 <= 0 ? 0 : precio / areaM2;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'codigo': codigo,
        'titulo': titulo,
        'direccion': direccion,
        'ciudad': ciudad,
        'barrio': barrio,
        'tipo': tipo.name,
        'precio': precio,
        'area_m2': areaM2,
        'habitaciones': habitaciones,
        'banos': banos,
        'estado': estado,
        'latitud': latitud,
        'longitud': longitud,
        'foto_url': fotoUrl,
        'revision': revision,
        'updated_at': updatedAt,
        'eliminado': eliminado ? 1 : 0,
      };

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
