import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/config/app_config.dart';
import 'core/db/app_database.dart';
import 'features/inmuebles/data/catalogo_demo.dart';
import 'features/inmuebles/data/inmueble_local_data_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final database = await AppDatabase.open();
  await _sembrarCatalogoDemo(database, config);

  runApp(
    ProviderScope(
      overrides: <Override>[
        appConfigProvider.overrideWithValue(config),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const InmoVisitaApp(),
    ),
  );
}

/// En modo demostracion siembra el catalogo local la primera vez que se abre
/// la aplicacion, para que sea utilizable sin backend.
Future<void> _sembrarCatalogoDemo(
  AppDatabase database,
  AppConfig config,
) async {
  if (config.hasRemoteBackend) return;
  final catalogo = InmuebleLocalDataSource(database.db);
  if (await catalogo.total() > 0) return;
  await catalogo.upsertLote(CatalogoDemo.inmuebles());
}
