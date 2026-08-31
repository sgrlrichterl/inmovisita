/**
 * Tipos compartidos por la API de sincronizacion.
 *
 * Este modulo no depende de firebase-admin ni de express: es logica pura y por
 * lo tanto se prueba sin emuladores ni credenciales.
 */

export type EstadoVisita = "borrador" | "registrada" | "cancelada";

export type TemperaturaLead = "frio" | "tibio" | "caliente";

export type OperacionSync = "crear" | "actualizar" | "eliminar";

export type Entidad = "visitas" | "fotos";

/** Registro versionado que participa en la reconciliacion. */
export interface Versionado {
  id: string;
  revision: number;
  updatedAt: number;
}

export interface Visita extends Versionado {
  inmuebleId: string;
  asesorUid: string;
  clienteNombre: string;
  clienteTelefono: string;
  clienteEmail?: string | null;
  fechaProgramada: number;
  fechaRegistro: number;
  duracionMin: number;
  estado: EstadoVisita;
  checklist: Record<string, boolean>;
  observaciones?: string | null;
  nivelInteres: number;
  presupuestoMax: number;
  tieneCredito: boolean;
  latitud?: number | null;
  longitud?: number | null;
  scoreLead: number;
  temperatura: TemperaturaLead;
  totalFotos?: number;
  eliminado: boolean;
}

/** Sobre que envia el dispositivo por cada operacion pendiente. */
export interface SobreOperacion {
  operacionId: string;
  entidad: Entidad;
  entidadId: string;
  operacion: OperacionSync;
  payload: Record<string, unknown>;
}

/** Confirmacion que el servidor devuelve por cada operacion. */
export interface ResultadoOperacion {
  operacionId: string;
  entidadId: string;
  aceptada: boolean;
  revision: number;
  updatedAt: number;
  error?: string;
  /** `false` para errores permanentes: el cliente no debe reintentar. */
  reintentable: boolean;
}

export interface RespuestaPull {
  inmuebles: unknown[];
  visitas: unknown[];
  cursor: number;
  hayMas: boolean;
}
