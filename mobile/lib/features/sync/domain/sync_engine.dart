import 'dart:math';

import '../../../core/errors/exceptions.dart';
import '../../inmuebles/data/inmueble_local_data_source.dart';
import '../../visitas/data/visita_local_data_source.dart';
import '../../visitas/domain/entities/visita.dart';
import '../data/outbox_local_data_source.dart';
import '../data/sync_meta_data_source.dart';
import '../data/sync_remote_data_source.dart';
import 'conflict_resolver.dart';
import 'entities/outbox_item.dart';
import 'retry_policy.dart';

/// Resultado de un ciclo de sincronizacion.
class ReporteSync {
  const ReporteSync({
    this.operacionesEnviadas = 0,
    this.operacionesFallidas = 0,
    this.inmueblesRecibidos = 0,
    this.visitasRecibidas = 0,
    this.conflictos = 0,
    this.omitida = false,
    this.error,
  });

  final int operacionesEnviadas;
  final int operacionesFallidas;
  final int inmueblesRecibidos;
  final int visitasRecibidas;
  final int conflictos;

  /// `true` cuando no habia red o backend configurado: no es un error.
  final bool omitida;
  final String? error;

  bool get exitosa => error == null && !omitida;

  int get totalRecibidos => inmueblesRecibidos + visitasRecibidas;

  @override
  String toString() => 'ReporteSync(enviadas: $operacionesEnviadas, '
      'fallidas: $operacionesFallidas, recibidos: $totalRecibidos, '
      'conflictos: $conflictos, omitida: $omitida, error: $error)';
}

/// Orquestador de la sincronizacion bidireccional.
///
/// Ejecuta dos fases en orden estricto:
///
/// 1. **Push**: vacia la cola de salida hacia el servidor. Se hace primero
///    para que el `pull` posterior traiga ya el estado consolidado y no
///    sobrescriba cambios locales que aun no habian salido.
/// 2. **Pull**: descarga los cambios remotos posteriores al ultimo cursor y
///    los reconcilia con [ConflictResolver].
///
/// El metodo [sincronizar] nunca lanza excepciones: cualquier fallo se reporta
/// en [ReporteSync], de modo que el ciclo periodico no se interrumpa.
class SyncEngine {
  SyncEngine({
    required OutboxLocalDataSource outbox,
    required VisitaLocalDataSource visitas,
    required InmuebleLocalDataSource inmuebles,
    required SyncMetaDataSource meta,
    SyncApi? remoto,
    RetryPolicy retryPolicy = const RetryPolicy(),
    ConflictResolver conflictResolver = const ConflictResolver(),
    Random? random,
    DateTime Function()? ahora,
  })  : _outbox = outbox,
        _visitas = visitas,
        _inmuebles = inmuebles,
        _meta = meta,
        _remoto = remoto,
        _retryPolicy = retryPolicy,
        _conflictResolver = conflictResolver,
        _random = random ?? Random(),
        _ahora = ahora ?? DateTime.now;

  final OutboxLocalDataSource _outbox;
  final VisitaLocalDataSource _visitas;
  final InmuebleLocalDataSource _inmuebles;
  final SyncMetaDataSource _meta;
  final SyncApi? _remoto;
  final RetryPolicy _retryPolicy;
  final ConflictResolver _conflictResolver;
  final Random _random;
  final DateTime Function() _ahora;

  bool _enCurso = false;

  bool get enCurso => _enCurso;

  /// Ejecuta un ciclo completo (push + pull).
  ///
  /// [hayConexion] se consulta antes de tocar la red; si es `false` el ciclo
  /// se omite sin penalizar los contadores de reintento.
  Future<ReporteSync> sincronizar({bool hayConexion = true}) async {
    final remoto = _remoto;
    if (remoto == null || !hayConexion) {
      return const ReporteSync(omitida: true);
    }
    if (_enCurso) {
      return const ReporteSync(omitida: true);
    }
    _enCurso = true;
    try {
      final push = await _ejecutarPush(remoto);
      final pull = await _ejecutarPull(remoto);
      await _meta.registrarUltimaSync(_ahora().millisecondsSinceEpoch);
      await _outbox.purgarEnviados();
      return ReporteSync(
        operacionesEnviadas: push.enviadas,
        operacionesFallidas: push.fallidas,
        inmueblesRecibidos: pull.inmuebles,
        visitasRecibidas: pull.visitas,
        conflictos: pull.conflictos,
        error: push.error ?? pull.error,
      );
    } finally {
      _enCurso = false;
    }
  }

  Future<_ResumenPush> _ejecutarPush(SyncApi remoto) async {
    final ahoraMs = _ahora().millisecondsSinceEpoch;
    final pendientes = await _outbox.pendientes(ahoraMs: ahoraMs);
    if (pendientes.isEmpty) {
      return const _ResumenPush();
    }

    final List<ResultadoPush> resultados;
    try {
      resultados = await remoto.push(pendientes);
    } on NetworkException catch (e) {
      await _reprogramarLote(pendientes, e.message, reintentable: true);
      return _ResumenPush(fallidas: pendientes.length, error: e.message);
    } on UnauthorizedException catch (e) {
      await _reprogramarLote(pendientes, e.message, reintentable: true);
      return _ResumenPush(fallidas: pendientes.length, error: e.message);
    } on ServerException catch (e) {
      final reintentable = (e.statusCode ?? 500) >= 500;
      await _reprogramarLote(pendientes, e.message, reintentable: reintentable);
      return _ResumenPush(fallidas: pendientes.length, error: e.message);
    }

    final porId = <String, ResultadoPush>{
      for (final r in resultados) r.operacionId: r,
    };

    var enviadas = 0;
    var fallidas = 0;
    for (final item in pendientes) {
      final resultado = porId[item.id];
      if (resultado == null) {
        fallidas++;
        await _programarReintento(
          item,
          'El servidor no confirmo la operacion',
          reintentable: true,
        );
        continue;
      }
      if (resultado.aceptada) {
        enviadas++;
        await _outbox.marcarEnviado(item.id);
        if (item.entidad == 'visitas') {
          await _visitas.marcarSincronizada(
            id: item.entidadId,
            revision: resultado.revision,
            updatedAt: resultado.updatedAt,
          );
        }
      } else {
        fallidas++;
        await _programarReintento(
          item,
          resultado.error ?? 'Rechazada por el servidor',
          reintentable: resultado.reintentable,
        );
        if (item.entidad == 'visitas' && !resultado.reintentable) {
          await _visitas.marcarError(item.entidadId);
        }
      }
    }
    return _ResumenPush(enviadas: enviadas, fallidas: fallidas);
  }

  Future<void> _reprogramarLote(
    List<OutboxItem> items,
    String error, {
    required bool reintentable,
  }) async {
    for (final item in items) {
      await _programarReintento(item, error, reintentable: reintentable);
    }
  }

  Future<void> _programarReintento(
    OutboxItem item,
    String error, {
    required bool reintentable,
  }) async {
    final intentos = item.intentos + 1;
    final agotado = !reintentable || !_retryPolicy.debeReintentar(intentos);
    final espera = _retryPolicy.esperaPara(intentos, random: _random);
    await _outbox.registrarFallo(
      id: item.id,
      intentos: intentos,
      error: error,
      proximoIntentoEnMs:
          _ahora().millisecondsSinceEpoch + espera.inMilliseconds,
      definitivo: agotado,
    );
  }

  Future<_ResumenPull> _ejecutarPull(SyncApi remoto) async {
    final cursor = await _meta.cursorPull;
    final ResultadoPull resultado;
    try {
      resultado = await remoto.pull(desde: cursor);
    } on NetworkException catch (e) {
      return _ResumenPull(error: e.message);
    } on UnauthorizedException catch (e) {
      return _ResumenPull(error: e.message);
    } on ServerException catch (e) {
      return _ResumenPull(error: e.message);
    }

    await _inmuebles.upsertLote(resultado.inmuebles);

    var conflictos = 0;
    var aplicadas = 0;
    for (final remota in resultado.visitas) {
      final local = await _visitas.obtener(remota.id);
      if (local == null) {
        await _visitas.aplicarDesdeRemoto(remota);
        aplicadas++;
        continue;
      }
      final decision = _conflictResolver.resolver(
        local: RegistroVersionado(
          id: local.id,
          revision: local.revision,
          updatedAt: local.updatedAt,
        ),
        remoto: RegistroVersionado(
          id: remota.id,
          revision: remota.revision,
          updatedAt: remota.updatedAt,
        ),
        localModificadoLocalmente: local.syncState == EstadoSync.pendiente,
      );
      switch (decision) {
        case DecisionConflicto.aplicarRemoto:
        case DecisionConflicto.sinCambios:
          await _visitas.aplicarDesdeRemoto(remota);
          aplicadas++;
          break;
        case DecisionConflicto.marcarConflicto:
          conflictos++;
          await _visitas.aplicarDesdeRemoto(remota);
          aplicadas++;
          break;
        case DecisionConflicto.conservarLocal:
          // La copia local es mas nueva; su operacion sigue en la cola.
          break;
      }
    }

    if (resultado.cursor > cursor) {
      await _meta.guardarCursorPull(resultado.cursor);
    }

    return _ResumenPull(
      inmuebles: resultado.inmuebles.length,
      visitas: aplicadas,
      conflictos: conflictos,
    );
  }
}

class _ResumenPush {
  const _ResumenPush({this.enviadas = 0, this.fallidas = 0, this.error});

  final int enviadas;
  final int fallidas;
  final String? error;
}

class _ResumenPull {
  const _ResumenPull({
    this.inmuebles = 0,
    this.visitas = 0,
    this.conflictos = 0,
    this.error,
  });

  final int inmuebles;
  final int visitas;
  final int conflictos;
  final String? error;
}
