import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/tarjeta.dart';
import '../domain/entities/visita.dart';
import 'widgets/score_chip.dart';

/// Historial de visitas registradas por el asesor.
class VisitasPage extends ConsumerWidget {
  const VisitasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitas = ref.watch(visitasProvider);
    final resumen = ref.watch(resumenVisitasProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(visitasProvider.notifier).recargar(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          resumen.maybeWhen(
            data: (datos) => Row(
              children: <Widget>[
                Expanded(
                  child: _Indicador(
                    valor: '${datos['total'] ?? 0}',
                    etiqueta: 'Visitas',
                    icono: Icons.assignment_turned_in_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Indicador(
                    valor: '${datos['calientes'] ?? 0}',
                    etiqueta: 'Leads calientes',
                    icono: Icons.local_fire_department_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Indicador(
                    valor: '${datos['pendientes'] ?? 0}',
                    etiqueta: 'Por subir',
                    icono: Icons.cloud_upload_outlined,
                  ),
                ),
              ],
            ),
            orElse: () => const SizedBox(height: 8),
          ),
          const SizedBox(height: 12),
          ...visitas.when(
            loading: () => <Widget>[
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, _) => <Widget>[
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error al leer las visitas: $error'),
              ),
            ],
            data: (lista) => lista.isEmpty
                ? <Widget>[
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Aun no ha registrado visitas.\n'
                          'Seleccione un inmueble en el catalogo para empezar.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ]
                : lista.map((v) => _VisitaTile(visita: v)).toList(),
          ),
        ],
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.valor,
    required this.etiqueta,
    required this.icono,
  });

  final String valor;
  final String etiqueta;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: esquema.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Icon(icono, size: 18, color: esquema.onPrimaryContainer),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: esquema.onPrimaryContainer,
            ),
          ),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: esquema.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _VisitaTile extends StatelessWidget {
  const _VisitaTile({required this.visita});

  final Visita visita;

  @override
  Widget build(BuildContext context) {
    final pendiente = visita.syncState == EstadoSync.pendiente;
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  visita.clienteNombre,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ScoreChip(
                temperatura: visita.temperatura,
                score: visita.scoreLead,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${visita.clienteTelefono} - '
            '${Formatos.fechaHora(visita.fechaRegistro)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(
                pendiente ? Icons.cloud_upload_outlined : Icons.cloud_done,
                size: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Text(
                pendiente ? 'Pendiente de subir' : 'Sincronizada',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                'Checklist '
                '${(visita.porcentajeChecklist * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
