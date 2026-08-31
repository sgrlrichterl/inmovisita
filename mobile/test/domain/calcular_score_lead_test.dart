import 'package:flutter_test/flutter_test.dart';
import 'package:inmovisita/features/visitas/domain/entities/visita.dart';
import 'package:inmovisita/features/visitas/domain/usecases/calcular_score_lead.dart';

Visita construirVisita({
  int nivelInteres = 0,
  double presupuesto = 0,
  bool credito = false,
  int duracion = 0,
  Map<String, bool>? checklist,
  String? observaciones,
  int fotos = 0,
}) {
  return Visita(
    id: 'v-1',
    inmuebleId: 'inm-001',
    asesorUid: 'asesor-1',
    clienteNombre: 'Cliente Prueba',
    clienteTelefono: '3001234567',
    fechaProgramada: 0,
    fechaRegistro: 0,
    duracionMin: duracion,
    checklist: checklist ?? const <String, bool>{},
    observaciones: observaciones,
    nivelInteres: nivelInteres,
    presupuestoMax: presupuesto,
    tieneCredito: credito,
    totalFotos: fotos,
  );
}

void main() {
  const calcular = CalcularScoreLead();
  const precio = 500000000.0;

  group('CalcularScoreLead', () {
    test('una visita vacia obtiene el puntaje minimo', () {
      final resultado =
          calcular(visita: construirVisita(), precioInmueble: precio);

      expect(resultado.score, 0);
      expect(resultado.temperatura, TemperaturaLead.frio);
    });

    test('el escenario ideal obtiene exactamente 100 puntos', () {
      final resultado = calcular(
        visita: construirVisita(
          nivelInteres: 5,
          presupuesto: precio,
          credito: true,
          duracion: 45,
          checklist: <String, bool>{
            for (final item in ItemsChecklist.todos) item: true,
          },
          observaciones:
              'El cliente pidio una segunda visita con su pareja y pregunto '
              'por el proceso de credito hipotecario.',
          fotos: 4,
        ),
        precioInmueble: precio,
      );

      expect(resultado.score, 100);
      expect(resultado.temperatura, TemperaturaLead.caliente);
      expect(resultado.desglose['interes'], CalcularScoreLead.pesoInteres);
      expect(resultado.desglose['capacidad'], CalcularScoreLead.pesoCapacidad);
      expect(resultado.desglose['credito'], CalcularScoreLead.pesoCredito);
    });

    test('el puntaje nunca excede 100 ni baja de 0', () {
      final resultado = calcular(
        visita: construirVisita(
          nivelInteres: 99,
          presupuesto: precio * 10,
          credito: true,
          duracion: 600,
          checklist: <String, bool>{
            for (final item in ItemsChecklist.todos) item: true,
          },
          observaciones: 'x' * 500,
          fotos: 50,
        ),
        precioInmueble: precio,
      );

      expect(resultado.score, lessThanOrEqualTo(100));
      expect(resultado.score, greaterThanOrEqualTo(0));
    });

    test('la capacidad de compra se escalona por tramos', () {
      int puntajeCapacidadCon(double presupuesto) {
        return calcular(
          visita: construirVisita(presupuesto: presupuesto),
          precioInmueble: precio,
        ).desglose['capacidad']!;
      }

      expect(puntajeCapacidadCon(precio), CalcularScoreLead.pesoCapacidad);
      expect(puntajeCapacidadCon(precio * 0.95), 20);
      expect(puntajeCapacidadCon(precio * 0.85), 12);
      expect(puntajeCapacidadCon(precio * 0.65), 6);
      expect(puntajeCapacidadCon(precio * 0.30), 0);
    });

    test('sin precio de referencia la capacidad no aporta puntos', () {
      final resultado = calcular(
        visita: construirVisita(presupuesto: 100000000),
        precioInmueble: 0,
      );

      expect(resultado.desglose['capacidad'], 0);
    });

    test('la clasificacion respeta los umbrales documentados', () {
      expect(CalcularScoreLead.clasificar(69), TemperaturaLead.tibio);
      expect(CalcularScoreLead.clasificar(70), TemperaturaLead.caliente);
      expect(CalcularScoreLead.clasificar(45), TemperaturaLead.tibio);
      expect(CalcularScoreLead.clasificar(44), TemperaturaLead.frio);
    });

    test('el desglose suma el puntaje total', () {
      final resultado = calcular(
        visita: construirVisita(
          nivelInteres: 4,
          presupuesto: precio * 0.9,
          duracion: 20,
          fotos: 2,
          observaciones: 'Interesado en negociar el precio',
        ),
        precioInmueble: precio,
      );

      final suma = resultado.desglose.values.fold<int>(0, (a, b) => a + b);
      expect(suma, resultado.score);
    });
  });
}
