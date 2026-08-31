import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/inmuebles/presentation/inmuebles_page.dart';
import '../features/sync/presentation/sync_banner.dart';
import '../features/sync/presentation/sync_page.dart';
import '../features/visitas/presentation/visitas_page.dart';
import 'providers.dart';

/// Contenedor principal con navegacion inferior.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _indice = 0;

  static const List<Widget> _paginas = <Widget>[
    InmueblesPage(),
    VisitasPage(),
    SyncPage(),
  ];

  static const List<String> _titulos = <String>[
    'Catalogo',
    'Mis visitas',
    'Sincronizacion',
  ];

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(sesionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_indice]),
        actions: <Widget>[
          if (usuario != null)
            PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 16,
                child: Text(
                  usuario.iniciales,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              onSelected: (valor) {
                if (valor == 'salir') {
                  unawaited(ref.read(sesionProvider.notifier).cerrarSesion());
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text('${usuario.nombre}\n${usuario.email}'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'salir',
                  child: Text('Cerrar sesion'),
                ),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: <Widget>[
          const SyncBanner(),
          Expanded(child: _paginas[_indice]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work),
            label: 'Catalogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Visitas',
          ),
          NavigationDestination(
            icon: Icon(Icons.sync_outlined),
            selectedIcon: Icon(Icons.sync),
            label: 'Sync',
          ),
        ],
      ),
    );
  }
}
