import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/login_page.dart';
import 'home_shell.dart';
import 'providers.dart';

/// Raiz de la aplicacion.
class InmoVisitaApp extends ConsumerWidget {
  const InmoVisitaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(sesionProvider);
    return MaterialApp(
      title: 'InmoVisita',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro(),
      darkTheme: AppTheme.oscuro(),
      home: usuario == null ? const LoginPage() : const HomeShell(),
    );
  }
}
