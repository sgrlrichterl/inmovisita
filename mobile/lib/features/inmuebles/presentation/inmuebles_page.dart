import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/tarjeta.dart';
import '../../visitas/presentation/registrar_visita_page.dart';
import '../domain/entities/inmueble.dart';

/// Catalogo de inmuebles disponible sin conexion.
class InmueblesPage extends ConsumerWidget {
  const InmueblesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inmuebles = ref.watch(inmueblesProvider);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar por titulo, direccion o codigo',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (valor) =>
                ref.read(filtroCatalogoProvider.notifier).state = valor,
          ),
        ),
        Expanded(
          child: inmuebles.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No fue posible leer el catalogo local: $error'),
              ),
            ),
            data: (lista) {
              if (lista.isEmpty) {
                return const Center(
                  child: Text('No hay inmuebles que coincidan con la busqueda'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: lista.length,
                itemBuilder: (context, i) => _InmuebleTile(inmueble: lista[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InmuebleTile extends StatelessWidget {
  const _InmuebleTile({required this.inmueble});

  final Inmueble inmueble;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Tarjeta(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RegistrarVisitaPage(inmueble: inmueble),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: esquema.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inmueble.codigo,
                  style: TextStyle(
                    fontSize: 11,
                    color: esquema.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                inmueble.tipo.etiqueta,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                Formatos.monedaCompacta(inmueble.precio),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            inmueble.titulo,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            '${inmueble.direccion} - ${inmueble.barrio ?? ''} '
            '${inmueble.ciudad}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            children: <Widget>[
              _Dato(icono: Icons.square_foot, texto: '${inmueble.areaM2.toStringAsFixed(0)} m2'),
              _Dato(icono: Icons.bed_outlined, texto: '${inmueble.habitaciones}'),
              _Dato(icono: Icons.bathtub_outlined, texto: '${inmueble.banos}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icono, size: 15),
        const SizedBox(width: 4),
        Text(texto, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
