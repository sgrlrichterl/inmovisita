/// Registro versionado que participa en la sincronizacion.
///
/// Cualquier entidad sincronizable expone estos tres datos: identificador
/// estable, contador de revision y marca de tiempo de la ultima escritura.
class RegistroVersionado {
  const RegistroVersionado({
    required this.id,
    required this.revision,
    required this.updatedAt,
  });

  final String id;
  final int revision;
  final int updatedAt;
}

/// Decision tomada por el resolvedor de conflictos.
enum DecisionConflicto {
  /// La copia local es mas reciente: se conserva y se reenvia al servidor.
  conservarLocal,

  /// La copia del servidor es mas reciente: se sobrescribe la local.
  aplicarRemoto,

  /// Ambas copias son equivalentes: no hay nada que hacer.
  sinCambios,

  /// Hubo escrituras concurrentes reales: se conserva la remota y se guarda
  /// la local como version en conflicto para revision manual.
  marcarConflicto,
}

/// Estrategia de reconciliacion entre la copia local y la remota.
///
/// Combina dos mecanismos:
///
/// 1. **Contador de revision**: cada escritura aceptada por el servidor
///    incrementa `revision`. Si las revisiones difieren, gana la mayor.
/// 2. **Last-Write-Wins por `updatedAt`**: cuando las revisiones empatan pero
///    los contenidos difieren, se compara la marca de tiempo.
///
/// El caso ambiguo (misma revision, marcas de tiempo distintas y ambas copias
/// modificadas desde la ultima sincronizacion) no se resuelve en silencio: se
/// marca como conflicto para que el coordinador lo revise. Esto evita la
/// perdida silenciosa de datos que sufre un LWW puro.
class ConflictResolver {
  const ConflictResolver({this.toleranciaMs = 1000});

  /// Diferencia maxima de reloj entre dispositivo y servidor que se considera
  /// irrelevante (los relojes de los telefonos no estan sincronizados).
  final int toleranciaMs;

  DecisionConflicto resolver({
    required RegistroVersionado local,
    required RegistroVersionado remoto,
    required bool localModificadoLocalmente,
  }) {
    assert(local.id == remoto.id, 'Solo se comparan registros con el mismo id');

    if (local.revision == remoto.revision &&
        (local.updatedAt - remoto.updatedAt).abs() <= toleranciaMs) {
      return DecisionConflicto.sinCambios;
    }

    if (remoto.revision > local.revision) {
      // El servidor avanzo. Si ademas hay cambios locales sin enviar, se trata
      // de una escritura concurrente real.
      return localModificadoLocalmente
          ? DecisionConflicto.marcarConflicto
          : DecisionConflicto.aplicarRemoto;
    }

    if (local.revision > remoto.revision) {
      return DecisionConflicto.conservarLocal;
    }

    // Misma revision con contenidos distintos: desempata la marca de tiempo.
    if (local.updatedAt > remoto.updatedAt) {
      return DecisionConflicto.conservarLocal;
    }
    return localModificadoLocalmente
        ? DecisionConflicto.marcarConflicto
        : DecisionConflicto.aplicarRemoto;
  }
}
