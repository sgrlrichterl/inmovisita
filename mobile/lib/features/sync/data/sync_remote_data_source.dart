import '../../../core/network/api_client.dart';
import '../../inmuebles/domain/entities/inmueble.dart';
import '../../visitas/domain/entities/visita.dart';
import '../domain/entities/outbox_item.dart';

/// Cambios recibidos del servidor en una sincronizacion delta.
class ResultadoPull {
  const ResultadoPull({
    required this.inmuebles,
    required this.visitas,
    required this.cursor,
    this.hayMas = false,
  });

  final List<Inmueble> inmuebles;
  final List<Visita> visitas;

  /// Marca de tiempo del cambio mas reciente entregado por el servidor.
  final int cursor;

  /// `true` si el servidor trunco la pagina y quedan cambios por descargar.
  final bool hayMas;

  bool get vacio => inmuebles.isEmpty && visitas.isEmpty;
}

/// Confirmacion del servidor para una operacion de la cola de salida.
class ResultadoPush {
  const ResultadoPush({
    required this.operacionId,
    required this.entidadId,
    required this.aceptada,
    this.revision = 0,
    this.updatedAt = 0,
    this.error,
    this.reintentable = true,
  });

  factory ResultadoPush.fromJson(Map<String, dynamic> json) {
    return ResultadoPush(
      operacionId: (json['operacionId'] ?? '') as String,
      entidadId: (json['entidadId'] ?? '') as String,
      aceptada: json['aceptada'] == true,
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
      error: json['error'] as String?,
      reintentable: json['reintentable'] != false,
    );
  }

  final String operacionId;
  final String entidadId;
  final bool aceptada;
  final int revision;
  final int updatedAt;
  final String? error;

  /// `false` para errores permanentes (validacion, permisos): no se reintenta.
  final bool reintentable;
}

/// Contrato de los endpoints de sincronizacion.
///
/// Se declara como interfaz para que el motor de sincronizacion dependa de una
/// abstraccion (principio de inversion de dependencias) y pueda probarse con
/// un doble de prueba sin tocar la red.
abstract interface class SyncApi {
  /// Descarga los cambios ocurridos despues de [desde] (epoch ms).
  Future<ResultadoPull> pull({required int desde, int limite});

  /// Envia un lote de operaciones pendientes.
  Future<List<ResultadoPush>> push(List<OutboxItem> items);
}

/// Cliente HTTP de los endpoints de sincronizacion de la API.
class SyncRemoteDataSource implements SyncApi {
  const SyncRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<ResultadoPull> pull({required int desde, int limite = 200}) async {
    final json = await _api.get('/v1/sync/pull', query: <String, String>{
      'desde': '$desde',
      'limite': '$limite',
    });

    final inmuebles = (json['inmuebles'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Inmueble.fromJson)
        .toList(growable: false);
    final visitas = (json['visitas'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Visita.fromJson)
        .toList(growable: false);

    return ResultadoPull(
      inmuebles: inmuebles,
      visitas: visitas,
      cursor: (json['cursor'] as num?)?.toInt() ?? desde,
      hayMas: json['hayMas'] == true,
    );
  }

  /// El servidor responde una confirmacion por operacion; el campo
  /// `operacionId` (UUID generado en el dispositivo) hace la operacion
  /// idempotente: reenviar el mismo lote no duplica registros.
  @override
  Future<List<ResultadoPush>> push(List<OutboxItem> items) async {
    if (items.isEmpty) return const <ResultadoPush>[];
    final json = await _api.post('/v1/sync/push', <String, dynamic>{
      'operaciones': items.map((i) => i.toEnvelope()).toList(growable: false),
    });
    return (json['resultados'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ResultadoPush.fromJson)
        .toList(growable: false);
  }
}
