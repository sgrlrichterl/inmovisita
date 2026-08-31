import {
  calcularScoreLead,
  clasificar,
  EntradaScore,
  ITEMS_CHECKLIST,
  PESOS,
  UMBRAL_CALIENTE,
  UMBRAL_TIBIO,
} from "../src/dominio/scoring";

const PRECIO = 500_000_000;

const entrada = (parcial: Partial<EntradaScore> = {}): EntradaScore => ({
  nivelInteres: 0,
  presupuestoMax: 0,
  tieneCredito: false,
  duracionMin: 0,
  checklist: {},
  observaciones: null,
  totalFotos: 0,
  ...parcial,
});

const checklistCompleto = (): Record<string, boolean> =>
  Object.fromEntries(ITEMS_CHECKLIST.map((i) => [i, true]));

describe("calcularScoreLead (autoridad del servidor)", () => {
  it("una visita vacia obtiene 0 y se clasifica como fria", () => {
    const resultado = calcularScoreLead(entrada(), PRECIO);
    expect(resultado.score).toBe(0);
    expect(resultado.temperatura).toBe("frio");
  });

  it("el escenario ideal suma exactamente 100", () => {
    const resultado = calcularScoreLead(
      entrada({
        nivelInteres: 5,
        presupuestoMax: PRECIO,
        tieneCredito: true,
        duracionMin: 45,
        checklist: checklistCompleto(),
        observaciones:
          "El cliente pidio una segunda visita y pregunto por el credito.",
        totalFotos: 4,
      }),
      PRECIO
    );

    expect(resultado.score).toBe(100);
    expect(resultado.temperatura).toBe("caliente");
    expect(resultado.desglose.interes).toBe(PESOS.interes);
  });

  it("nunca excede el rango 0-100", () => {
    const resultado = calcularScoreLead(
      entrada({
        nivelInteres: 99,
        presupuestoMax: PRECIO * 10,
        tieneCredito: true,
        duracionMin: 600,
        checklist: checklistCompleto(),
        observaciones: "x".repeat(500),
        totalFotos: 99,
      }),
      PRECIO
    );

    expect(resultado.score).toBeLessThanOrEqual(100);
    expect(resultado.score).toBeGreaterThanOrEqual(0);
  });

  it("escalona la capacidad de compra por tramos", () => {
    const capacidad = (presupuesto: number): number =>
      calcularScoreLead(entrada({presupuestoMax: presupuesto}), PRECIO)
        .desglose.capacidad;

    expect(capacidad(PRECIO)).toBe(PESOS.capacidad);
    expect(capacidad(PRECIO * 0.95)).toBe(20);
    expect(capacidad(PRECIO * 0.85)).toBe(12);
    expect(capacidad(PRECIO * 0.65)).toBe(6);
    expect(capacidad(PRECIO * 0.3)).toBe(0);
  });

  it("ignora claves de checklist desconocidas", () => {
    const resultado = calcularScoreLead(
      entrada({checklist: {inventada: true, otra: true}}),
      PRECIO
    );
    expect(resultado.desglose.checklist).toBe(0);
  });

  it("respeta los umbrales de clasificacion", () => {
    expect(clasificar(UMBRAL_CALIENTE)).toBe("caliente");
    expect(clasificar(UMBRAL_CALIENTE - 1)).toBe("tibio");
    expect(clasificar(UMBRAL_TIBIO)).toBe("tibio");
    expect(clasificar(UMBRAL_TIBIO - 1)).toBe("frio");
  });

  it("el desglose suma el puntaje total", () => {
    const resultado = calcularScoreLead(
      entrada({
        nivelInteres: 4,
        presupuestoMax: PRECIO * 0.9,
        duracionMin: 20,
        totalFotos: 2,
        observaciones: "Interesado en negociar el precio",
      }),
      PRECIO
    );
    const suma = Object.values(resultado.desglose).reduce((a, b) => a + b, 0);
    expect(suma).toBe(resultado.score);
  });
});

describe("paridad con el cliente movil", () => {
  it("usa los mismos pesos documentados en la arquitectura", () => {
    const total = Object.values(PESOS).reduce((a, b) => a + b, 0);
    expect(total).toBe(100);
  });
});
