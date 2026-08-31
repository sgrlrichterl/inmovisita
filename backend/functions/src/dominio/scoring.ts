import {TemperaturaLead} from "./tipos";

/**
 * Modelo de calificacion de leads: implementacion **autoritativa**.
 *
 * El cliente movil ejecuta el mismo algoritmo (ver
 * `mobile/lib/features/visitas/domain/usecases/calcular_score_lead.dart`) para
 * dar retroalimentacion inmediata al asesor sin conexion, pero el puntaje que
 * queda almacenado es siempre el que calcula esta funcion: el dispositivo no
 * es una fuente confiable.
 *
 * | Factor                | Peso maximo |
 * |-----------------------|-------------|
 * | Nivel de interes      | 30          |
 * | Capacidad de compra   | 25          |
 * | Credito preaprobado   | 15          |
 * | Duracion de la visita | 10          |
 * | Checklist completado  | 10          |
 * | Evidencia registrada  | 10          |
 */
export const PESOS = {
  interes: 30,
  capacidad: 25,
  credito: 15,
  duracion: 10,
  checklist: 10,
  evidencia: 10,
} as const;

export const UMBRAL_CALIENTE = 70;
export const UMBRAL_TIBIO = 45;

/** Items obligatorios del checklist de visita. */
export const ITEMS_CHECKLIST = [
  "documentos_verificados",
  "estado_fisico_revisado",
  "zonas_comunes_mostradas",
  "servicios_publicos_ok",
  "parqueadero_verificado",
  "cliente_firmo_asistencia",
] as const;

export interface EntradaScore {
  nivelInteres: number;
  presupuestoMax: number;
  tieneCredito: boolean;
  duracionMin: number;
  checklist: Record<string, boolean>;
  observaciones?: string | null;
  totalFotos?: number;
}

export interface ResultadoScore {
  score: number;
  temperatura: TemperaturaLead;
  desglose: Record<string, number>;
}

const acotar = (valor: number, min: number, max: number): number =>
  Math.min(Math.max(valor, min), max);

function puntajeInteres(nivel: number): number {
  return Math.round((acotar(nivel, 0, 5) / 5) * PESOS.interes);
}

function puntajeCapacidad(presupuesto: number, precio: number): number {
  if (precio <= 0 || presupuesto <= 0) return 0;
  const ratio = presupuesto / precio;
  if (ratio >= 1.0) return PESOS.capacidad;
  if (ratio >= 0.9) return 20;
  if (ratio >= 0.8) return 12;
  if (ratio >= 0.6) return 6;
  return 0;
}

function puntajeDuracion(minutos: number): number {
  if (minutos >= 30) return PESOS.duracion;
  if (minutos >= 15) return 6;
  if (minutos >= 5) return 3;
  return 0;
}

function puntajeChecklist(checklist: Record<string, boolean>): number {
  const marcados = ITEMS_CHECKLIST.filter((item) => checklist[item] === true)
    .length;
  return Math.round((marcados / ITEMS_CHECKLIST.length) * PESOS.checklist);
}

function puntajeEvidencia(
  observaciones: string | null | undefined,
  totalFotos: number
): number {
  let puntos = 0;
  const texto = (observaciones ?? "").trim();
  if (texto.length >= 40) puntos += 5;
  else if (texto.length >= 15) puntos += 2;
  if (totalFotos >= 3) puntos += 5;
  else if (totalFotos >= 1) puntos += 2;
  return puntos;
}

/** Traduce un puntaje a la temperatura comercial del lead. */
export function clasificar(score: number): TemperaturaLead {
  if (score >= UMBRAL_CALIENTE) return "caliente";
  if (score >= UMBRAL_TIBIO) return "tibio";
  return "frio";
}

/** Calcula el puntaje del lead frente al precio del inmueble mostrado. */
export function calcularScoreLead(
  entrada: EntradaScore,
  precioInmueble: number
): ResultadoScore {
  const desglose: Record<string, number> = {
    interes: puntajeInteres(entrada.nivelInteres),
    capacidad: puntajeCapacidad(entrada.presupuestoMax, precioInmueble),
    credito: entrada.tieneCredito ? PESOS.credito : 0,
    duracion: puntajeDuracion(entrada.duracionMin),
    checklist: puntajeChecklist(entrada.checklist ?? {}),
    evidencia: puntajeEvidencia(entrada.observaciones, entrada.totalFotos ?? 0),
  };

  const total = Object.values(desglose).reduce((a, b) => a + b, 0);
  const score = acotar(total, 0, 100);

  return {score, temperatura: clasificar(score), desglose};
}
