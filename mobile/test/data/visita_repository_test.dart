import 'package:flutter_test/flutter_test.dart';
import 'package:inmovisita/core/db/app_database.dart';
import 'package:inmovisita/features/inmuebles/data/catalogo_demo.dart';
import 'package:inmovisita/features/inmuebles/data/inmueble_local_data_source.dart';
import 'package:inmovisita/features/sync/data/outbox_local_data_source.dart';
import 'package:inmovisita/features/visitas/data/visita_local_data_source.dart';
import 'package:inmovisita/features/visitas/data/visita_repository.dart';
import 'package:inmovisita/features/visitas/domain/entities/visita.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Pruebas del flujo offline completo sobre una base SQLite en memoria.
void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase database;
  late VisitaRepository repositorio;
  late OutboxLocalDataSource outbox;
  late VisitaLocalDataSource visitasLocal;

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    final inmuebles = InmuebleLocalDataSource(database.db);
    await inmuebles.upsertLote(CatalogoDemo.inmuebles());

    outbox = OutboxLocalDataSource(database.db);
    visitasLocal = VisitaLocalDataSource(database.db, outbox);
    repositorio = VisitaRepository(local: visitasLocal, inmuebles: inmuebles);
  });

  tearDown(() async {
    await database.close();
  });

  const borradorValido = BorradorVisita(
    inmuebleId: 'inm-001',
    clienteNombre: 'Maria Restrepo',
    clienteTelefono: '3105550123',
    clienteEmail: 'maria@example.com',
    duracionMin: 35,
    nivelInteres: 5,
    presupuestoMax: 640000000,
    tieneCredito: true,
    observaciones:
        'Le gusto el balcon y pidio cotizacion de administracion mensual.',
  );

  group('registro offline', () {
    test('guarda la visita y encola su envio en la misma operacion', () async {
      final resultado = await repositorio.registrar(
        borrador: borradorValido,
        asesorUid: 'asesor-1',
      );

      expect(resultado.isOk, isTrue);
      final visita = resultado.valueOrNull!;
      expect(visita.syncState, EstadoSync.pendiente);
      expect(await outbox.conteoPendientes(), 1);

      final almacenadas = await repositorio.listar(asesorUid: 'asesor-1');
      expect(almacenadas, hasLength(1));
      expect(almacenadas.first.clienteNombre, 'Maria Restrepo');
    });

    test('califica el lead al momento de guardarlo', () async {
      final resultado = await repositorio.registrar(
        borrador: borradorValido,
        asesorUid: 'asesor-1',
      );

      final visita = resultado.valueOrNull!;
      expect(visita.scoreLead, greaterThan(0));
      expect(visita.temperatura, TemperaturaLead.caliente);
    });

    test('el identificador se genera en el dispositivo (idempotencia)',
        () async {
      final a = await repositorio.registrar(
        borrador: borradorValido,
        asesorUid: 'asesor-1',
      );
      final b = await repositorio.registrar(
        borrador: borradorValido,
        asesorUid: 'asesor-1',
      );

      expect(a.valueOrNull!.id, isNotEmpty);
      expect(a.valueOrNull!.id, isNot(b.valueOrNull!.id));
      expect(await outbox.conteoPendientes(), 2);
    });

    test('el resumen refleja las visitas pendientes', () async {
      await repositorio.registrar(
        borrador: borradorValido,
        asesorUid: 'asesor-1',
      );

      final resumen = await repositorio.resumen(asesorUid: 'asesor-1');
      expect(resumen['total'], 1);
      expect(resumen['pendientes'], 1);
      expect(resumen['calientes'], 1);
    });

    test('actualizar incrementa la revision y reencola la operacion', () async {
      final creada = (await repositorio.registrar(
        borrador: borradorValido,
        asesorUid: 'asesor-1',
      ))
          .valueOrNull!;

      final actualizada = (await repositorio.actualizar(
        creada.copyWith(nivelInteres: 1, tieneCredito: false),
      ))
          .valueOrNull!;

      expect(actualizada.revision, creada.revision + 1);
      expect(actualizada.scoreLead, lessThan(creada.scoreLead));
      expect(await outbox.conteoPendientes(), 2);
    });
  });

  group('validaciones de negocio', () {
    test('rechaza un nombre demasiado corto', () async {
      final resultado = await repositorio.registrar(
        borrador: const BorradorVisita(
          inmuebleId: 'inm-001',
          clienteNombre: 'Al',
          clienteTelefono: '3105550123',
        ),
        asesorUid: 'asesor-1',
      );

      expect(resultado.isOk, isFalse);
      expect(await outbox.conteoPendientes(), 0);
    });

    test('rechaza un telefono invalido', () async {
      final resultado = await repositorio.registrar(
        borrador: const BorradorVisita(
          inmuebleId: 'inm-001',
          clienteNombre: 'Carlos Perez',
          clienteTelefono: '123',
        ),
        asesorUid: 'asesor-1',
      );

      expect(resultado.isOk, isFalse);
    });

    test('rechaza un correo mal formado', () async {
      final resultado = await repositorio.registrar(
        borrador: const BorradorVisita(
          inmuebleId: 'inm-001',
          clienteNombre: 'Carlos Perez',
          clienteTelefono: '3105550123',
          clienteEmail: 'carlos@@correo',
        ),
        asesorUid: 'asesor-1',
      );

      expect(resultado.isOk, isFalse);
    });

    test('rechaza un inmueble que no esta en el catalogo local', () async {
      final resultado = await repositorio.registrar(
        borrador: const BorradorVisita(
          inmuebleId: 'inexistente',
          clienteNombre: 'Carlos Perez',
          clienteTelefono: '3105550123',
        ),
        asesorUid: 'asesor-1',
      );

      expect(resultado.isOk, isFalse);
      expect(resultado.failureOrNull, isNotNull);
    });
  });
}
