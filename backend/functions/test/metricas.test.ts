import {calcularMetricas, fechaColombiana} from "../src/dominio/metricas";
import {Visita} from "../src/dominio/tipos";

const visita = (parcial: Partial<Visita>): Visita => ({
  id: "v",
  inmuebleId: "inm-001",
  asesorUid: "asesor-1",
  clienteNombre: "Cliente",
  clienteTelefono: "3001112233",
  fechaProgramada: 0,
  fechaRegistro: 0,
  duracionMin: 0,
  estado: "registrada",
  checklist: {},
  nivelInteres: 0,
  presupuestoMax: 0,
  tieneCredito: false,
  scoreLead: 0,
  temperatura: "frio",
  revision: 1,
  updatedAt: 0,
  eliminado: false,
  ...parcial,
});

describe("calcularMetricas", () => {
  it("devuelve ceros cuando no hubo visitas", () => {
    const metrica = calcularMetricas([], "2026-08-28", 1000);
    expect(metrica.totalVisitas).toBe(0);
    expect(metrica.scorePromedio).toBe(0);
    expect(metrica.asesoresActivos).toBe(0);
  });

  it("agrega totales, promedios y asesores unicos", () => {
    const metrica = calcularMetricas(
      [
        visita({scoreLead: 80, duracionMin: 30, temperatura: "caliente"}),
        visita({
          scoreLead: 50,
          duracionMin: 20,
          temperatura: "tibio",
          asesorUid: "asesor-2",
        }),
        visita({scoreLead: 20, duracionMin: 10, temperatura: "frio"}),
      ],
      "2026-08-28",
      1000
    );

    expect(metrica.totalVisitas).toBe(3);
    expect(metrica.leadsCalientes).toBe(1);
    expect(metrica.leadsTibios).toBe(1);
    expect(metrica.scorePromedio).toBe(50);
    expect(metrica.minutosPromedio).toBe(20);
    expect(metrica.asesoresActivos).toBe(2);
  });
});

describe("fechaColombiana", () => {
  it("aplica el desplazamiento UTC-5", () => {
    // 2026-08-29 02:00 UTC corresponde al 28 de agosto en Colombia.
    const epoch = Date.UTC(2026, 7, 29, 2, 0, 0);
    expect(fechaColombiana(epoch)).toBe("2026-08-28");
  });

  it("no cambia el dia para una hora de la tarde", () => {
    const epoch = Date.UTC(2026, 7, 29, 20, 0, 0);
    expect(fechaColombiana(epoch)).toBe("2026-08-29");
  });
});
