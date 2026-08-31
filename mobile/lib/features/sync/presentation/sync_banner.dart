import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// Franja permanente que informa el estado de la sincronizacion.
///
/// Es la pieza de interfaz que hace visible el modelo offline-first: el asesor
/// siempre sabe cuantos registros faltan por subir y nunca queda bloqueado.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(syncProvider);
    final esquema = Theme.of(context).colorScheme;

    Color fondo = esquema.primaryContainer;
    Color texto = esquema.onPrimaryContainer;
    IconData icono = Icons.cloud_done_outlined;
    String mensaje = 'Todo sincronizado';

    if (estado.sincronizando) {
      fondo = esquema.secondaryContainer;
      texto = esquema.onSecondaryContainer;
      icono = Icons.sync;
      mensaje = 'Sincronizando...';
    } else if (!estado.enLinea) {
      fondo = esquema.errorContainer;
      texto = esquema.onErrorContainer;
      icono = Icons.cloud_off;
      mensaje = 'Sin conexion - ${estado.pendientes} registro(s) en cola';
    } else if (estado.pendientes > 0) {
      fondo = esquema.tertiaryContainer;
      texto = esquema.onTertiaryContainer;
      icono = Icons.cloud_upload_outlined;
      mensaje = '${estado.pendientes} registro(s) pendientes por subir';
    }

    return Material(
      color: fondo,
      child: InkWell(
        onTap: () => unawaited(ref.read(syncProvider.notifier).sincronizar()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(icono, size: 18, color: texto),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensaje,
                  style: TextStyle(color: texto, fontSize: 13),
                ),
              ),
              if (!estado.sincronizando)
                Text(
                  'Sincronizar',
                  style: TextStyle(
                    color: texto,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
