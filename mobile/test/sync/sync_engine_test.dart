import 'package:flutter_test/flutter_test.dart';
import 'package:inmovisita/core/db/app_database.dart';
import 'package:inmovisita/core/errors/exceptions.dart';
import 'package:inmovisita/features/inmuebles/data/catalogo_demo.dart';
import 'package:inmovisita/features/inmuebles/data/inmueble_local_data_source.dart';
import 'package:inmovisita/features/inmuebles/domain/entities/inmueble.dart';
import 'package:inmovisita/features/sync/data/outbox_local_data_source.dart';
import 'package:inmovisita/features/sync/data/sync_meta_data_source.dart';
import 'package:inmovisita/features/sync/data/sync_remote_data_source.dart';
import 'package:inmovisita/features/sync/domain/entities/outbox_item.dart';
import 'package:inmovisita/features/sync/domain/sync_engine.dart';
import 'package:inmovisita/features/visitas/data/visita_local_data_source.dart';
import 'package:inmovisita/features/visitas/data/visita_repository.dart';
import 'package:inmovisita/features/visitas/domain/entities/visita.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Doble de prueba del contrato de sincronizacion.
///
/// Registra las operaciones recibidas y permite programar la respuesta del
/// servidor para cada escenario.
class FakeSyncApi implements SyncApi {
  FakeSyncApi({
    this.aceptarTodo = true,
    this.reintentable = true,
    this.excepcion,
    this.respuestaPull,
  });

  final bool aceptarTodo;
  final bool reintentable;
  final Object? excepcion;
  final ResultadoPull? respuestaPull;

  final List<OutboxItem> recibidas = <OutboxItem>[];
  int llamadasPull = 0;
  int ultimoCursorSolicitado = -1;

  @override
  Future<List<ResultadoPush>> push(List<OutboxItem> items) async {
    if (excepcion != null) {
      throw excepcion!;
    }
    recibidas.addAll(items);
    return items
        .map(
          (i) => ResultadoPush(
            operacionId: i.id,
            entidadId: i.entidadId,
            aceptada: aceptarTodo,
            revision: 2,
            updatedAt: 1700000000000,
            error: aceptarTodo ? null : 'Rechazada por el servidor',
            reintentable: reintentable,
          ),
        )
        .toList();
  }

  @override
  Future<ResultadoPull> pull({required int desde, int limite = 200}) async {
    llamadasPull++;
    ultimoCursorSolicitado = desde;
    return respuestaPull ??
        const ResultadoPull(
          inmuebles: <Inmueble>[],
          visitas: <Visita>[],
          cursor: 0,
        );
  }
}

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase database;
  late OutboxLocalDataSource outbox;
  late VisitaLocalDataSource visitasLocal;
  late InmuebleLocalDataSource inmueblesLocal;
  late SyncMetaDataSource meta;
  late VisitaRepository repositorio;

  const borrador = BorradorVisita(
    inmuebleId: 'inm-002',
    clienteNombre: 'Julian Mesa',
    clienteTelefono: '3204447788',
    duracionMin: 25,
    nivelInteres: 4,
    presupuestoMax: 900000000,
  );

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    inmueblesLocal = InmuebleLocalDataSource(database.db);
    await inmueblesLocal.upsertLote(CatalogoDemo.inmuebles());
    outbox = OutboxLocalDataSource(database.db);
    visitasLocal = VisitaLocalDataSource(database.db, outbox);
    meta = SyncMetaDataSource(database.db);
    repositorio = VisitaRepository(
      local: visitasLocal,
      inmuebles: inmueblesLocal,
    );
  });

  tearDown(() async {
    await database.close();
  });

  SyncEngine motorCon(SyncApi? api) => SyncEngine(
        outbox: outbox,
        visitas: visitasLocal,
        inmuebles: inmueblesLocal,
        meta: meta,
        remoto: api,
      );

  group('SyncEngine', () {
    test('sin backend configurado el ciclo se omite', () async {
      final reporte = await motorCon(null).sincronizar();

      expect(reporte.omitida, isTrue);
      expect(reporte.exitosa, isFalse);
    });

    test('sin conexion no se toca la red', () async {
      final api = FakeSyncApi();
      final reporte = await motorCon(api).sincronizar(hayConexion: false);

      expect(reporte.omitida, isTrue);
      expect(api.llamadasPull, 0);
    });

    test('envia la cola pendiente y marca las visitas como sincronizadas',
        () async {
      final visita = (await repositorio.registrar(
        borrador: borrador,
        asesorUid: 'asesor-1',
      ))
          .valueOrNull!;
      expect(await outbox.conteoPendientes(), 1);

      final api = FakeSyncApi();
      final reporte = await motorCon(api).sincronizar();

      expect(reporte.operacionesEnviadas, 1);
      expect(reporte.operacionesFallidas, 0);
      expect(api.recibidas.single.entidadId, visita.id);
      expect(api.recibidas.single.operacion, OperacionOutbox.crear);

      final almacenada = await visitasLocal.obtener(visita.id);
      expect(almacenada!.syncState, EstadoSync.sincronizado);
      expect(almacenada.revision, 2);
      expect(await outbox.conteoPendientes(), 0);
    });

    test('un rechazo permanente marca la operacion como fallida', () async {
      final visita = (await repositorio.registrar(
        borrador: borrador,
        asesorUid: 'asesor-1',
      ))
          .valueOrNull!;

      final api = FakeSyncApi(aceptarTodo: false, reintentable: false);
      final reporte = await motorCon(api).sincronizar();

      expect(reporte.operacionesFallidas, 1);
      expect(await outbox.conteoFallidos(), 1);

      final almacenada = await visitasLocal.obtener(visita.id);
      expect(almacenada!.syncState, EstadoSync.error);
    });

    test('un fallo de red conserva la operacion para reintentarla', () async {
      await repositorio.registrar(borrador: borrador, asesorUid: 'asesor-1');

      final api = FakeSyncApi(excepcion: NetworkException('sin red'));
      final reporte = await motorCon(api).sincronizar();

      expect(reporte.error, isNotNull);
      expect(reporte.operacionesFallidas, 1);
      // Sigue en cola (reprogramada), no se marca como fallida definitiva.
      expect(await outbox.conteoFallidos(), 0);
      expect(await outbox.conteoPendientes(), 1);
    });

    test('aplica los cambios recibidos y avanza el cursor', () async {
      const visitaRemota = Visita(
        id: 'remota-1',
        inmuebleId: 'inm-003',
        asesorUid: 'asesor-9',
        clienteNombre: 'Cliente Remoto',
        clienteTelefono: '3001112233',
        fechaProgramada: 1700000000000,
        fechaRegistro: 1700000000000,
        revision: 3,
        updatedAt: 1700000500000,
        syncState: EstadoSync.sincronizado,
      );

      final api = FakeSyncApi(
        respuestaPull: const ResultadoPull(
          inmuebles: <Inmueble>[],
          visitas: <Visita>[visitaRemota],
          cursor: 1700000500000,
        ),
      );

      final reporte = await motorCon(api).sincronizar();

      expect(reporte.visitasRecibidas, 1);
      expect(await visitasLocal.obtener('remota-1'), isNotNull);
      expect(await meta.cursorPull, 1700000500000);
      expect(api.ultimoCursorSolicitado, 0);
    });
  });
}
