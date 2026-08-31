import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/tarjeta.dart';

/// Panel de control de la sincronizacion.
class SyncPage extends ConsumerWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(syncProvider);
    final detalle = ref.watch(detalleSyncProvider);
    final config = ref.watch(appConfigProvider);
    final reporte = estado.ultimoReporte;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Tarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Estado de la cola de salida',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              detalle.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
                data: (datos) => Column(
                  children: <Widget>[
                    _Fila(
                      etiqueta: 'Operaciones pendientes',
                      valor: '${datos['pendientes'] ?? 0}',
                    ),
                    _Fila(
                      etiqueta: 'Operaciones fallidas',
                      valor: '${datos['fallidos'] ?? 0}',
                    ),
                    _Fila(
                      etiqueta: 'Ultima sincronizacion',
                      valor: Formatos.hace(datos['ultimaSync'] ?? 0),
                    ),
                    _Fila(
                      etiqueta: 'Conectividad',
                      valor: estado.enLinea ? 'En linea' : 'Sin conexion',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: estado.sincronizando
              ? null
              : () => unawaited(ref.read(syncProvider.notifier).sincronizar()),
          icon: const Icon(Icons.sync),
          label: Text(
            estado.sincronizando ? 'Sincronizando...' : 'Sincronizar ahora',
          ),
        ),
        const SizedBox(height: 16),
        if (reporte != null)
          Tarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Ultimo ciclo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _Fila(
                  etiqueta: 'Operaciones enviadas',
                  valor: '${reporte.operacionesEnviadas}',
                ),
                _Fila(
                  etiqueta: 'Operaciones fallidas',
                  valor: '${reporte.operacionesFallidas}',
                ),
                _Fila(
                  etiqueta: 'Registros recibidos',
                  valor: '${reporte.totalRecibidos}',
                ),
                _Fila(
                  etiqueta: 'Conflictos resueltos',
                  valor: '${reporte.conflictos}',
                ),
                if (reporte.error != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    reporte.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (!config.hasRemoteBackend)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'La aplicacion corre en modo demostracion: las operaciones se '
              'acumulan en la cola local y no se envian a la nube. Configure '
              'API_BASE_URL y FIREBASE_API_KEY para habilitar el backend.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(etiqueta, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
