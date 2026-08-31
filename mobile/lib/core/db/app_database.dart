import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base de datos local SQLite: fuente de verdad de la aplicacion.
///
/// La app es *offline-first*: la interfaz siempre lee de esta base de datos y
/// nunca espera a la red. El motor de sincronizacion (`features/sync`) es el
/// unico responsable de reconciliarla con la nube.
class AppDatabase {
  AppDatabase._(this.db);

  /// Version del esquema. Cada incremento requiere una migracion en
  /// [_onUpgrade].
  static const int schemaVersion = 1;

  static const String dbFileName = 'inmovisita.db';

  final Database db;

  /// Abre (o crea) la base de datos.
  ///
  /// [factory] y [path] se inyectan en las pruebas para usar SQLite en memoria
  /// mediante `sqflite_common_ffi`, sin necesidad de un emulador.
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final resolvedFactory = factory ?? databaseFactory;
    final resolvedPath =
        path ?? p.join(await resolvedFactory.getDatabasesPath(), dbFileName);

    final database = await resolvedFactory.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    return AppDatabase._(database);
  }

  Future<void> close() => db.close();

  /// Borra el contenido de todas las tablas de negocio (cierre de sesion).
  Future<void> wipe() async {
    await db.transaction((txn) async {
      for (final table in const [
        'outbox',
        'visita_fotos',
        'visitas',
        'inmuebles',
        'usuarios',
        'sync_meta',
      ]) {
        await txn.delete(table);
      }
    });
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // La v1 es el esquema inicial. Las migraciones futuras se agregan aqui de
    // forma incremental (if (oldVersion < 2) { ... }).
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE usuarios (
        uid         TEXT PRIMARY KEY,
        nombre      TEXT NOT NULL,
        email       TEXT NOT NULL,
        rol         TEXT NOT NULL DEFAULT 'asesor',
        updated_at  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE inmuebles (
        id            TEXT PRIMARY KEY,
        codigo        TEXT NOT NULL,
        titulo        TEXT NOT NULL,
        direccion     TEXT NOT NULL,
        ciudad        TEXT NOT NULL,
        barrio        TEXT,
        tipo          TEXT NOT NULL,
        precio        REAL NOT NULL DEFAULT 0,
        area_m2       REAL NOT NULL DEFAULT 0,
        habitaciones  INTEGER NOT NULL DEFAULT 0,
        banos         INTEGER NOT NULL DEFAULT 0,
        estado        TEXT NOT NULL DEFAULT 'disponible',
        latitud       REAL,
        longitud      REAL,
        foto_url      TEXT,
        revision      INTEGER NOT NULL DEFAULT 1,
        updated_at    INTEGER NOT NULL DEFAULT 0,
        eliminado     INTEGER NOT NULL DEFAULT 0
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_inmuebles_ciudad ON inmuebles(ciudad, estado)',
    );
    batch.execute(
      'CREATE INDEX idx_inmuebles_updated ON inmuebles(updated_at)',
    );

    batch.execute('''
      CREATE TABLE visitas (
        id                TEXT PRIMARY KEY,
        inmueble_id       TEXT NOT NULL,
        asesor_uid        TEXT NOT NULL,
        cliente_nombre    TEXT NOT NULL,
        cliente_telefono  TEXT NOT NULL,
        cliente_email     TEXT,
        fecha_programada  INTEGER NOT NULL,
        fecha_registro    INTEGER NOT NULL,
        duracion_min      INTEGER NOT NULL DEFAULT 0,
        estado            TEXT NOT NULL DEFAULT 'borrador',
        checklist         TEXT NOT NULL DEFAULT '{}',
        observaciones     TEXT,
        nivel_interes     INTEGER NOT NULL DEFAULT 0,
        presupuesto_max   REAL NOT NULL DEFAULT 0,
        tiene_credito     INTEGER NOT NULL DEFAULT 0,
        latitud           REAL,
        longitud          REAL,
        firma_path        TEXT,
        score_lead        INTEGER NOT NULL DEFAULT 0,
        temperatura       TEXT NOT NULL DEFAULT 'frio',
        revision          INTEGER NOT NULL DEFAULT 1,
        updated_at        INTEGER NOT NULL DEFAULT 0,
        sync_state        TEXT NOT NULL DEFAULT 'pendiente',
        eliminado         INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (inmueble_id) REFERENCES inmuebles(id) ON DELETE CASCADE
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_visitas_asesor ON visitas(asesor_uid, fecha_registro)',
    );
    batch.execute(
      'CREATE INDEX idx_visitas_sync ON visitas(sync_state)',
    );

    batch.execute('''
      CREATE TABLE visita_fotos (
        id          TEXT PRIMARY KEY,
        visita_id   TEXT NOT NULL,
        ruta_local  TEXT NOT NULL,
        url_remota  TEXT,
        subida      INTEGER NOT NULL DEFAULT 0,
        creada_en   INTEGER NOT NULL,
        FOREIGN KEY (visita_id) REFERENCES visitas(id) ON DELETE CASCADE
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_fotos_visita ON visita_fotos(visita_id)',
    );

    // Patron Outbox: toda escritura local encola aqui su operacion remota.
    batch.execute('''
      CREATE TABLE outbox (
        id                 TEXT PRIMARY KEY,
        entidad            TEXT NOT NULL,
        entidad_id         TEXT NOT NULL,
        operacion          TEXT NOT NULL,
        payload            TEXT NOT NULL,
        intentos           INTEGER NOT NULL DEFAULT 0,
        ultimo_error       TEXT,
        creado_en          INTEGER NOT NULL,
        proximo_intento_en INTEGER NOT NULL DEFAULT 0,
        estado             TEXT NOT NULL DEFAULT 'pendiente'
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_outbox_estado ON outbox(estado, proximo_intento_en)',
    );

    batch.execute('''
      CREATE TABLE sync_meta (
        clave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      )
    ''');

    await batch.commit(noResult: true);
  }
}
