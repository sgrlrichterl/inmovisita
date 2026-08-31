import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/tarjeta.dart';
import '../../inmuebles/domain/entities/inmueble.dart';
import '../data/visita_repository.dart';
import '../domain/entities/visita.dart';
import '../domain/usecases/calcular_score_lead.dart';
import 'widgets/score_chip.dart';

/// Formulario de registro de una visita en campo.
///
/// Todo el formulario funciona sin conexion: al guardar, la visita se escribe
/// en SQLite y su envio queda encolado en el outbox.
class RegistrarVisitaPage extends ConsumerStatefulWidget {
  const RegistrarVisitaPage({required this.inmueble, super.key});

  final Inmueble inmueble;

  @override
  ConsumerState<RegistrarVisitaPage> createState() =>
      _RegistrarVisitaPageState();
}

class _RegistrarVisitaPageState extends ConsumerState<RegistrarVisitaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _presupuestoCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  static const CalcularScoreLead _calculadora = CalcularScoreLead();

  int _nivelInteres = 3;
  double _duracion = 20;
  bool _tieneCredito = false;
  bool _guardando = false;
  late Map<String, bool> _checklist = ItemsChecklist.vacio();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _presupuestoCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  double get _presupuesto =>
      double.tryParse(_presupuestoCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
      0;

  /// Vista previa del puntaje con los datos que hay en pantalla.
  ResultadoScore get _preview {
    final provisional = Visita(
      id: 'preview',
      inmuebleId: widget.inmueble.id,
      asesorUid: '',
      clienteNombre: _nombreCtrl.text,
      clienteTelefono: _telefonoCtrl.text,
      fechaProgramada: 0,
      fechaRegistro: 0,
      duracionMin: _duracion.round(),
      checklist: _checklist,
      observaciones: _observacionesCtrl.text,
      nivelInteres: _nivelInteres,
      presupuestoMax: _presupuesto,
      tieneCredito: _tieneCredito,
    );
    return _calculadora(
      visita: provisional,
      precioInmueble: widget.inmueble.precio,
    );
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final usuario = ref.read(sesionProvider);
    if (usuario == null) return;

    setState(() => _guardando = true);
    final resultado = await ref.read(visitaRepositoryProvider).registrar(
          asesorUid: usuario.uid,
          borrador: BorradorVisita(
            inmuebleId: widget.inmueble.id,
            clienteNombre: _nombreCtrl.text,
            clienteTelefono: _telefonoCtrl.text,
            clienteEmail: _emailCtrl.text,
            duracionMin: _duracion.round(),
            nivelInteres: _nivelInteres,
            presupuestoMax: _presupuesto,
            tieneCredito: _tieneCredito,
            checklist: _checklist,
            observaciones: _observacionesCtrl.text,
            latitud: widget.inmueble.latitud,
            longitud: widget.inmueble.longitud,
          ),
        );

    if (!mounted) return;
    setState(() => _guardando = false);

    final visita = resultado.valueOrNull;
    if (visita == null) {
      final falla = resultado.failureOrNull;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(falla?.message ?? 'No fue posible guardar')),
      );
      return;
    }

    await ref.read(visitasProvider.notifier).recargar();
    await ref.read(syncProvider.notifier).refrescarPendientes();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Visita guardada en el dispositivo - lead '
          '${visita.temperatura.etiqueta.toLowerCase()} '
          '(${visita.scoreLead}/100)',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar visita')),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: <Widget>[
            Tarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.inmueble.titulo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.inmueble.codigo} - '
                    '${Formatos.moneda(widget.inmueble.precio)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const _Seccion(titulo: 'Datos del cliente'),
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Minimo 3 caracteres'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefono'),
              validator: (v) {
                final digitos = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                return digitos.length < 7 ? 'Telefono invalido' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo (opcional)',
              ),
            ),
            const SizedBox(height: 20),
            const _Seccion(titulo: 'Calificacion del lead'),
            Text('Nivel de interes: $_nivelInteres / 5'),
            Slider(
              value: _nivelInteres.toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              label: '$_nivelInteres',
              onChanged: (v) => setState(() => _nivelInteres = v.round()),
            ),
            Text('Duracion de la visita: ${_duracion.round()} minutos'),
            Slider(
              value: _duracion,
              min: 0,
              max: 90,
              divisions: 18,
              label: '${_duracion.round()} min',
              onChanged: (v) => setState(() => _duracion = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _presupuestoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Presupuesto maximo del cliente (COP)',
                prefixText: r'$ ',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Credito preaprobado'),
              value: _tieneCredito,
              onChanged: (v) => setState(() => _tieneCredito = v),
            ),
            const SizedBox(height: 12),
            const _Seccion(titulo: 'Checklist de la visita'),
            ...ItemsChecklist.todos.map(
              (item) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(ItemsChecklist.etiquetas[item] ?? item),
                value: _checklist[item] ?? false,
                onChanged: (v) => setState(() {
                  _checklist = <String, bool>{
                    ..._checklist,
                    item: v ?? false,
                  };
                }),
              ),
            ),
            const SizedBox(height: 12),
            const _Seccion(titulo: 'Observaciones'),
            TextFormField(
              controller: _observacionesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Comentarios del cliente, objeciones, acuerdos...',
              ),
            ),
            const SizedBox(height: 20),
            Tarjeta(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Calificacion estimada del lead'),
                        const SizedBox(height: 4),
                        Text(
                          '${preview.score} / 100',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  ScoreChip(temperatura: preview.temperatura),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: FilledButton.icon(
          onPressed: _guardando ? null : _guardar,
          icon: const Icon(Icons.save_outlined),
          label: Text(_guardando ? 'Guardando...' : 'Guardar visita'),
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        titulo.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 1.1,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
