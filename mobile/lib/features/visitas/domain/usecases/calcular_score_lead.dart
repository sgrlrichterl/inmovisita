import '../entities/visita.dart';

/// Resultado del modelo de calificacion de leads.
class ResultadoScore {
  const ResultadoScore({
    required this.score,
    required this.temperatura,
    required this.desglose,
  });

  /// Puntaje total en el rango [0, 100].
  final int score;

  /// Clasificacion comercial derivada del puntaje.
  final TemperaturaLead temperatura;

  /// Aporte de cada factor, util para explicar la calificacion al asesor
  /// (transparencia del modelo) y para depurar en las pruebas.
  final Map<String, int> desglose;
}

/// Modelo de calificacion de leads inmobiliarios.
///
/// El puntaje es una suma ponderada de seis factores observables durante la
/// visita. Los pesos se documentan en `docs/03-modelo-de-datos.md` y se
/// replican **de forma identica** en la Cloud Function `calcularScoreLead`
/// (TypeScript), que es la autoridad final: el calculo en el dispositivo solo
/// da retroalimentacion inmediata al asesor cuando no hay red.
///
/// | Factor                 | Peso maximo |
/// |------------------------|-------------|
/// | Nivel de interes       | 30          |
/// | Capacidad de compra    | 25          |
/// | Credito preaprobado    | 15          |
/// | Duracion de la visita  | 10          |
/// | Checklist completado   | 10          |
/// | Evidencia registrada   | 10          |
/// | **Total**              | **100**     |
class CalcularScoreLead {
  const CalcularScoreLead();

  static const int pesoInteres = 30;
  static const int pesoCapacidad = 25;
  static const int pesoCredito = 15;
  static const int pesoDuracion = 10;
  static const int pesoChecklist = 10;
  static const int pesoEvidencia = 10;

  static const int umbralCaliente = 70;
  static const int umbralTibio = 45;

  /// Calcula el puntaje de la [visita] frente al [precioInmueble] mostrado.
  ResultadoScore call({
    required Visita visita,
    required double precioInmueble,
  }) {
    final interes = _puntajeInteres(visita.nivelInteres);
    final capacidad = _puntajeCapacidad(visita.presupuestoMax, precioInmueble);
    final credito = visita.tieneCredito ? pesoCredito : 0;
    final duracion = _puntajeDuracion(visita.duracionMin);
    final checklist = _puntajeChecklist(visita);
    final evidencia = _puntajeEvidencia(visita);

    final desglose = <String, int>{
      'interes': interes,
      'capacidad': capacidad,
      'credito': credito,
      'duracion': duracion,
      'checklist': checklist,
      'evidencia': evidencia,
    };

    final total = desglose.values.fold<int>(0, (acc, valor) => acc + valor);
    final score = total.clamp(0, 100);

    return ResultadoScore(
      score: score,
      temperatura: clasificar(score),
      desglose: desglose,
    );
  }

  /// Traduce un puntaje a la temperatura comercial del lead.
  static TemperaturaLead clasificar(int score) {
    if (score >= umbralCaliente) return TemperaturaLead.caliente;
    if (score >= umbralTibio) return TemperaturaLead.tibio;
    return TemperaturaLead.frio;
  }

  /// Interes declarado (0-5) escalado linealmente al peso del factor.
  int _puntajeInteres(int nivelInteres) {
    final nivel = nivelInteres.clamp(0, 5);
    return ((nivel / 5) * pesoInteres).round();
  }

  /// Relacion entre el presupuesto del cliente y el precio del inmueble.
  int _puntajeCapacidad(double presupuesto, double precio) {
    if (precio <= 0 || presupuesto <= 0) return 0;
    final ratio = presupuesto / precio;
    if (ratio >= 1.0) return pesoCapacidad;
    if (ratio >= 0.90) return 20;
    if (ratio >= 0.80) return 12;
    if (ratio >= 0.60) return 6;
    return 0;
  }

  /// Una visita larga correlaciona con mayor intencion de compra.
  int _puntajeDuracion(int minutos) {
    if (minutos >= 30) return pesoDuracion;
    if (minutos >= 15) return 6;
    if (minutos >= 5) return 3;
    return 0;
  }

  /// Proporcion del checklist diligenciado por el asesor.
  int _puntajeChecklist(Visita visita) {
    return (visita.porcentajeChecklist * pesoChecklist).round();
  }

  /// Calidad de la evidencia adjunta: observaciones y fotografias.
  int _puntajeEvidencia(Visita visita) {
    var puntos = 0;
    final observaciones = visita.observaciones?.trim() ?? '';
    if (observaciones.length >= 40) {
      puntos += 5;
    } else if (observaciones.length >= 15) {
      puntos += 2;
    }
    if (visita.totalFotos >= 3) {
      puntos += 5;
    } else if (visita.totalFotos >= 1) {
      puntos += 2;
    }
    return puntos;
  }
}
