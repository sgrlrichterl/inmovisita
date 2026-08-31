import {Visita} from "./tipos";

/** Indicadores agregados de un dia de operacion. */
export interface MetricaDiaria {
  fecha: string;
  totalVisitas: number;
  leadsCalientes: number;
  leadsTibios: number;
  scorePromedio: number;
  minutosPromedio: number;
  asesoresActivos: number;
  calculadaEn: number;
}

/**
 * Calcula los indicadores a partir de las visitas de un dia.
 *
 * Logica pura y sin dependencias de infraestructura: se prueba directamente
 * con `jest`, sin emuladores ni credenciales.
 */
export function calcularMetricas(
  visitas: Visita[],
  fecha: string,
  ahora: number
): MetricaDiaria {
  const total = visitas.length;
  const suma = (f: (v: Visita) => number): number =>
    visitas.reduce((acc, v) => acc + f(v), 0);

  return {
    fecha,
    totalVisitas: total,
    leadsCalientes: visitas.filter((v) => v.temperatura === "caliente").length,
    leadsTibios: visitas.filter((v) => v.temperatura === "tibio").length,
    scorePromedio: total === 0 ?
      0 :
      Math.round(suma((v) => v.scoreLead) / total),
    minutosPromedio: total === 0 ?
      0 :
      Math.round(suma((v) => v.duracionMin) / total),
    asesoresActivos: new Set(visitas.map((v) => v.asesorUid)).size,
    calculadaEn: ahora,
  };
}

/** Fecha en formato YYYY-MM-DD para la zona horaria de Colombia (UTC-5). */
export function fechaColombiana(epochMs: number): string {
  const desplazado = new Date(epochMs - 5 * 60 * 60 * 1000);
  return desplazado.toISOString().slice(0, 10);
}
