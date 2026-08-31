import 'dart:math';

/// Politica de reintentos con retroceso exponencial y *jitter*.
///
/// Evita que todos los dispositivos que recuperan conectividad a la vez
/// golpeen el backend en el mismo instante (efecto rebano). El jitter es
/// proporcional y se puede fijar en pruebas inyectando un [Random] con semilla.
class RetryPolicy {
  const RetryPolicy({
    this.baseDelay = const Duration(seconds: 5),
    this.maxDelay = const Duration(minutes: 15),
    this.maxIntentos = 5,
    this.factorJitter = 0.2,
  });

  final Duration baseDelay;
  final Duration maxDelay;
  final int maxIntentos;
  final double factorJitter;

  /// Espera antes del intento numero [intentos] + 1.
  ///
  /// Progresion: 5s, 10s, 20s, 40s, 80s ... con tope en [maxDelay].
  Duration esperaPara(int intentos, {Random? random}) {
    final exponente = intentos.clamp(0, 20);
    final crudoMs = baseDelay.inMilliseconds * pow(2, exponente).toDouble();
    final acotadoMs = min(crudoMs, maxDelay.inMilliseconds.toDouble());
    if (random == null || factorJitter <= 0) {
      return Duration(milliseconds: acotadoMs.round());
    }
    // Jitter simetrico: +-factorJitter del valor acotado.
    final delta = acotadoMs * factorJitter * (random.nextDouble() * 2 - 1);
    final conJitter = (acotadoMs + delta).clamp(0.0, maxDelay.inMilliseconds.toDouble());
    return Duration(milliseconds: conJitter.round());
  }

  /// `true` si la operacion aun puede reintentarse.
  bool debeReintentar(int intentos) => intentos < maxIntentos;
}
