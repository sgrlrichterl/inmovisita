import 'package:uuid/uuid.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';
import '../../inmuebles/data/inmueble_local_data_source.dart';
import '../../sync/domain/entities/outbox_item.dart';
import '../domain/entities/visita.dart';
import '../domain/usecases/calcular_score_lead.dart';
import 'visita_local_data_source.dart';

/// Datos capturados por el asesor en el formulario de visita.
class BorradorVisita {
  const BorradorVisita({
    required this.inmuebleId,
    required this.clienteNombre,
    required this.clienteTelefono,
    this.clienteEmail,
    this.duracionMin = 0,
    this.nivelInteres = 0,
    this.presupuestoMax = 0,
    this.tieneCredito = false,
    this.checklist = const <String, bool>{},
    this.observaciones,
    this.latitud,
    this.longitud,
    this.fechaProgramada,
  });

  final String inmuebleId;
  final String clienteNombre;
  final String clienteTelefono;
  final String? clienteEmail;
  final int duracionMin;
  final int nivelInteres;
  final double presupuestoMax;
  final bool tieneCredito;
  final Map<String, bool> checklist;
  final String? observaciones;
  final double? latitud;
  final double? longitud;
  final int? fechaProgramada;
}

/// Casos de uso de visitas: validacion, calificacion y persistencia offline.
class VisitaRepository {
  VisitaRepository({
    required VisitaLocalDataSource local,
    required InmuebleLocalDataSource inmuebles,
    CalcularScoreLead calcularScore = const CalcularScoreLead(),
    Uuid? uuid,
    DateTime Function()? ahora,
  })  : _local = local,
        _inmuebles = inmuebles,
        _calcularScore = calcularScore,
        _uuid = uuid ?? const Uuid(),
        _ahora = ahora ?? DateTime.now;

  final VisitaLocalDataSource _local;
  final InmuebleLocalDataSource _inmuebles;
  final CalcularScoreLead _calcularScore;
  final Uuid _uuid;
  final DateTime Function() _ahora;

  /// Valida, califica y guarda una visita. La operacion queda encolada para
  /// su envio; el metodo retorna sin esperar a la red.
  Future<Result<Visita>> registrar({
    required BorradorVisita borrador,
    required String asesorUid,
  }) async {
    final validacion = validar(borrador);
    if (validacion != null) {
      return Result<Visita>.err(validacion);
    }

    final inmueble = await _inmuebles.obtener(borrador.inmuebleId);
    if (inmueble == null) {
      return const Result<Visita>.err(
        ValidationFailure('El inmueble no existe en el catalogo local'),
      );
    }

    final ahoraMs = _ahora().millisecondsSinceEpoch;
    final visitaBase = Visita(
      id: _uuid.v4(),
      inmuebleId: borrador.inmuebleId,
      asesorUid: asesorUid,
      clienteNombre: borrador.clienteNombre.trim(),
      clienteTelefono: borrador.clienteTelefono.trim(),
      clienteEmail: borrador.clienteEmail?.trim(),
      fechaProgramada: borrador.fechaProgramada ?? ahoraMs,
      fechaRegistro: ahoraMs,
      duracionMin: borrador.duracionMin,
      estado: EstadoVisita.registrada,
      checklist: borrador.checklist,
      observaciones: borrador.observaciones?.trim(),
      nivelInteres: borrador.nivelInteres,
      presupuestoMax: borrador.presupuestoMax,
      tieneCredito: borrador.tieneCredito,
      latitud: borrador.latitud,
      longitud: borrador.longitud,
      updatedAt: ahoraMs,
      syncState: EstadoSync.pendiente,
    );

    final resultado = _calcularScore(
      visita: visitaBase,
      precioInmueble: inmueble.precio,
    );
    final visita = visitaBase.copyWith(
      scoreLead: resultado.score,
      temperatura: resultado.temperatura,
    );

    await _local.guardar(visita, operacion: OperacionOutbox.crear);
    return Result<Visita>.ok(visita);
  }

  /// Recalcula el puntaje y actualiza una visita ya registrada.
  Future<Result<Visita>> actualizar(Visita visita) async {
    final inmueble = await _inmuebles.obtener(visita.inmuebleId);
    if (inmueble == null) {
      return const Result<Visita>.err(
        ValidationFailure('El inmueble no existe en el catalogo local'),
      );
    }
    final resultado = _calcularScore(
      visita: visita,
      precioInmueble: inmueble.precio,
    );
    final actualizada = visita.copyWith(
      scoreLead: resultado.score,
      temperatura: resultado.temperatura,
      revision: visita.revision + 1,
      updatedAt: _ahora().millisecondsSinceEpoch,
      syncState: EstadoSync.pendiente,
    );
    await _local.guardar(
      actualizada,
      operacion: OperacionOutbox.actualizar,
    );
    return Result<Visita>.ok(actualizada);
  }

  Future<List<Visita>> listar({String? asesorUid}) =>
      _local.listar(asesorUid: asesorUid);

  Future<Visita?> obtener(String id) => _local.obtener(id);

  Future<Map<String, int>> resumen({String? asesorUid}) =>
      _local.resumen(asesorUid: asesorUid);

  /// Reglas de negocio del formulario. Devuelve `null` si el borrador es
  /// valido; en caso contrario, la falla que debe mostrarse al asesor.
  static ValidationFailure? validar(BorradorVisita borrador) {
    if (borrador.inmuebleId.trim().isEmpty) {
      return const ValidationFailure('Seleccione el inmueble visitado');
    }
    if (borrador.clienteNombre.trim().length < 3) {
      return const ValidationFailure(
        'El nombre del cliente debe tener al menos 3 caracteres',
      );
    }
    final soloDigitos =
        borrador.clienteTelefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (soloDigitos.length < 7) {
      return const ValidationFailure('Telefono invalido (minimo 7 digitos)');
    }
    final email = borrador.clienteEmail?.trim() ?? '';
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return const ValidationFailure('Correo electronico invalido');
    }
    if (borrador.nivelInteres < 0 || borrador.nivelInteres > 5) {
      return const ValidationFailure('El nivel de interes va de 0 a 5');
    }
    if (borrador.presupuestoMax < 0) {
      return const ValidationFailure('El presupuesto no puede ser negativo');
    }
    if (borrador.duracionMin < 0 || borrador.duracionMin > 600) {
      return const ValidationFailure('Duracion invalida (0 a 600 minutos)');
    }
    return null;
  }
}
