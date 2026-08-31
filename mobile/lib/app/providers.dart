import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/db/app_database.dart';
import '../core/network/api_client.dart';
import '../core/network/connectivity_service.dart';
import '../features/auth/data/auth_remote_data_source.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/session_store.dart';
import '../features/auth/domain/entities/usuario.dart';
import '../features/inmuebles/data/inmueble_local_data_source.dart';
import '../features/inmuebles/domain/entities/inmueble.dart';
import '../features/sync/data/outbox_local_data_source.dart';
import '../features/sync/data/sync_meta_data_source.dart';
import '../features/sync/data/sync_remote_data_source.dart';
import '../features/sync/domain/sync_engine.dart';
import '../features/visitas/data/visita_local_data_source.dart';
import '../features/visitas/data/visita_repository.dart';
import '../features/visitas/domain/entities/visita.dart';

/// --- Dependencias inyectadas desde `main()` -------------------------------

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider debe sobrescribirse'),
);

final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider debe sobrescribirse'),
);

/// --- Fuentes de datos -----------------------------------------------------

final outboxDataSourceProvider = Provider<OutboxLocalDataSource>(
  (ref) => OutboxLocalDataSource(ref.watch(appDatabaseProvider).db),
);

final inmuebleDataSourceProvider = Provider<InmuebleLocalDataSource>(
  (ref) => InmuebleLocalDataSource(ref.watch(appDatabaseProvider).db),
);

final visitaDataSourceProvider = Provider<VisitaLocalDataSource>(
  (ref) => VisitaLocalDataSource(
    ref.watch(appDatabaseProvider).db,
    ref.watch(outboxDataSourceProvider),
  ),
);

final syncMetaProvider = Provider<SyncMetaDataSource>(
  (ref) => SyncMetaDataSource(ref.watch(appDatabaseProvider).db),
);

final connectivityProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityPlusService(),
);

/// --- Autenticacion y red --------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  final remoto = config.hasRemoteBackend
      ? AuthRemoteDataSource(apiKey: config.firebaseApiKey)
      : null;
  final repo = AuthRepository(
    config: config,
    store: SessionStore(),
    remoto: remoto,
  );
  ref.onDispose(() => remoto?.close());
  return repo;
});

final apiClientProvider = Provider<ApiClient?>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasRemoteBackend) return null;
  final auth = ref.watch(authRepositoryProvider);
  final cliente = ApiClient(
    baseUrl: config.apiBaseUrl,
    tokenProvider: auth.tokenActual,
  );
  ref.onDispose(cliente.close);
  return cliente;
});

final syncRemoteProvider = Provider<SyncApi?>((ref) {
  final api = ref.watch(apiClientProvider);
  return api == null ? null : SyncRemoteDataSource(api);
});

/// --- Casos de uso ---------------------------------------------------------

final visitaRepositoryProvider = Provider<VisitaRepository>(
  (ref) => VisitaRepository(
    local: ref.watch(visitaDataSourceProvider),
    inmuebles: ref.watch(inmuebleDataSourceProvider),
  ),
);

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(
    outbox: ref.watch(outboxDataSourceProvider),
    visitas: ref.watch(visitaDataSourceProvider),
    inmuebles: ref.watch(inmuebleDataSourceProvider),
    meta: ref.watch(syncMetaProvider),
    remoto: ref.watch(syncRemoteProvider),
  ),
);

/// --- Estado de la interfaz ------------------------------------------------

class SesionNotifier extends Notifier<Usuario?> {
  @override
  Usuario? build() => ref.read(authRepositoryProvider).usuario;

  Future<String?> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final resultado = await ref
        .read(authRepositoryProvider)
        .iniciarSesion(email: email, password: password);
    return resultado.fold(
      (usuario) {
        state = usuario;
        return null;
      },
      (falla) => falla.message,
    );
  }

  Future<void> restaurar() async {
    state = await ref.read(authRepositoryProvider).restaurarSesion();
  }

  Future<void> cerrarSesion() async {
    await ref.read(authRepositoryProvider).cerrarSesion();
    state = null;
  }
}

final sesionProvider =
    NotifierProvider<SesionNotifier, Usuario?>(SesionNotifier.new);

/// Filtro activo del catalogo.
final filtroCatalogoProvider = StateProvider<String>((ref) => '');

class InmueblesNotifier extends AsyncNotifier<List<Inmueble>> {
  @override
  Future<List<Inmueble>> build() async {
    final texto = ref.watch(filtroCatalogoProvider);
    return ref.read(inmuebleDataSourceProvider).listar(texto: texto);
  }

  Future<void> recargar() async {
    state = const AsyncValue<List<Inmueble>>.loading();
    state = await AsyncValue.guard(
      () => ref.read(inmuebleDataSourceProvider).listar(
            texto: ref.read(filtroCatalogoProvider),
          ),
    );
  }
}

final inmueblesProvider =
    AsyncNotifierProvider<InmueblesNotifier, List<Inmueble>>(
  InmueblesNotifier.new,
);

class VisitasNotifier extends AsyncNotifier<List<Visita>> {
  @override
  Future<List<Visita>> build() async {
    final usuario = ref.watch(sesionProvider);
    return ref.read(visitaRepositoryProvider).listar(asesorUid: usuario?.uid);
  }

  Future<void> recargar() async {
    final usuario = ref.read(sesionProvider);
    state = await AsyncValue.guard(
      () => ref.read(visitaRepositoryProvider).listar(asesorUid: usuario?.uid),
    );
  }
}

final visitasProvider =
    AsyncNotifierProvider<VisitasNotifier, List<Visita>>(VisitasNotifier.new);

/// Indicadores del panel principal.
final resumenVisitasProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(visitasProvider);
  final usuario = ref.watch(sesionProvider);
  return ref.read(visitaRepositoryProvider).resumen(asesorUid: usuario?.uid);
});

/// Estado observable del sincronizador.
class EstadoSyncUi {
  const EstadoSyncUi({
    this.pendientes = 0,
    this.sincronizando = false,
    this.enLinea = true,
    this.ultimoReporte,
  });

  final int pendientes;
  final bool sincronizando;
  final bool enLinea;
  final ReporteSync? ultimoReporte;

  EstadoSyncUi copyWith({
    int? pendientes,
    bool? sincronizando,
    bool? enLinea,
    ReporteSync? ultimoReporte,
  }) {
    return EstadoSyncUi(
      pendientes: pendientes ?? this.pendientes,
      sincronizando: sincronizando ?? this.sincronizando,
      enLinea: enLinea ?? this.enLinea,
      ultimoReporte: ultimoReporte ?? this.ultimoReporte,
    );
  }
}

/// Coordina el ciclo periodico de sincronizacion y expone su estado a la UI.
class SyncNotifier extends Notifier<EstadoSyncUi> {
  Timer? _timer;
  StreamSubscription<bool>? _suscripcion;

  @override
  EstadoSyncUi build() {
    final config = ref.watch(appConfigProvider);
    final conectividad = ref.watch(connectivityProvider);

    _timer = Timer.periodic(
      Duration(seconds: config.syncIntervalSeconds),
      (_) => unawaited(sincronizar()),
    );
    _suscripcion = conectividad.onStatusChange.listen((enLinea) {
      state = state.copyWith(enLinea: enLinea);
      if (enLinea) {
        unawaited(sincronizar());
      }
    });

    ref.onDispose(() {
      _timer?.cancel();
      unawaited(_suscripcion?.cancel());
    });

    unawaited(refrescarPendientes());
    return const EstadoSyncUi();
  }

  Future<void> refrescarPendientes() async {
    final pendientes = await ref.read(outboxDataSourceProvider).conteoPendientes();
    state = state.copyWith(pendientes: pendientes);
  }

  /// Ejecuta un ciclo de sincronizacion y refresca las vistas dependientes.
  Future<ReporteSync> sincronizar() async {
    if (state.sincronizando) {
      return const ReporteSync(omitida: true);
    }
    state = state.copyWith(sincronizando: true);
    final enLinea = await ref.read(connectivityProvider).isOnline;
    final reporte =
        await ref.read(syncEngineProvider).sincronizar(hayConexion: enLinea);
    final pendientes =
        await ref.read(outboxDataSourceProvider).conteoPendientes();
    state = EstadoSyncUi(
      pendientes: pendientes,
      sincronizando: false,
      enLinea: enLinea,
      ultimoReporte: reporte,
    );
    if (reporte.totalRecibidos > 0) {
      await ref.read(visitasProvider.notifier).recargar();
      await ref.read(inmueblesProvider.notifier).recargar();
    }
    return reporte;
  }
}

final syncProvider =
    NotifierProvider<SyncNotifier, EstadoSyncUi>(SyncNotifier.new);

/// Detalle del estado de la cola de salida para la pantalla de sincronizacion.
final detalleSyncProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(syncProvider);
  final outbox = ref.watch(outboxDataSourceProvider);
  final meta = ref.watch(syncMetaProvider);
  return <String, int>{
    'pendientes': await outbox.conteoPendientes(),
    'fallidos': await outbox.conteoFallidos(),
    'ultimaSync': await meta.ultimaSync,
  };
});
