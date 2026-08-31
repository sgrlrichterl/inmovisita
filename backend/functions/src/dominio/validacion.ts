import {Entidad, OperacionSync, SobreOperacion, Visita} from "./tipos";

/** Resultado de una validacion de entrada. */
export type Validacion<T> =
  | {ok: true; valor: T}
  | {ok: false; error: string};

const ENTIDADES: Entidad[] = ["visitas", "fotos"];
const OPERACIONES: OperacionSync[] = ["crear", "actualizar", "eliminar"];

const esTexto = (v: unknown): v is string => typeof v === "string";
const esNumero = (v: unknown): v is number =>
  typeof v === "number" && Number.isFinite(v);

/**
 * Valida la estructura del sobre recibido en `POST /v1/sync/push`.
 *
 * Toda entrada que llega del dispositivo se considera no confiable: se valida
 * forma, tipos y rangos antes de tocar Firestore.
 */
export function validarSobre(dato: unknown): Validacion<SobreOperacion> {
  if (typeof dato !== "object" || dato === null) {
    return {ok: false, error: "La operacion debe ser un objeto"};
  }
  const sobre = dato as Record<string, unknown>;

  if (!esTexto(sobre.operacionId) || sobre.operacionId.length < 8) {
    return {ok: false, error: "operacionId invalido"};
  }
  if (!esTexto(sobre.entidadId) || sobre.entidadId.length < 3) {
    return {ok: false, error: "entidadId invalido"};
  }
  if (!esTexto(sobre.entidad) || !ENTIDADES.includes(sobre.entidad as Entidad)) {
    return {ok: false, error: `entidad no soportada: ${String(sobre.entidad)}`};
  }
  if (
    !esTexto(sobre.operacion) ||
    !OPERACIONES.includes(sobre.operacion as OperacionSync)
  ) {
    return {ok: false, error: `operacion no soportada: ${String(sobre.operacion)}`};
  }
  if (typeof sobre.payload !== "object" || sobre.payload === null) {
    return {ok: false, error: "payload invalido"};
  }

  return {
    ok: true,
    valor: {
      operacionId: sobre.operacionId,
      entidad: sobre.entidad as Entidad,
      entidadId: sobre.entidadId,
      operacion: sobre.operacion as OperacionSync,
      payload: sobre.payload as Record<string, unknown>,
    },
  };
}

const RE_EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

/**
 * Normaliza y valida el cuerpo de una visita.
 *
 * El `asesorUid` se toma **del token**, nunca del cuerpo de la peticion: un
 * dispositivo no puede registrar visitas a nombre de otro asesor.
 */
export function normalizarVisita(
  payload: Record<string, unknown>,
  asesorUid: string,
  ahora: number
): Validacion<Visita> {
  const id = payload.id;
  if (!esTexto(id) || id.length < 8) {
    return {ok: false, error: "id de visita invalido"};
  }
  if (!esTexto(payload.inmuebleId) || payload.inmuebleId.length < 3) {
    return {ok: false, error: "inmuebleId invalido"};
  }
  const nombre = esTexto(payload.clienteNombre) ? payload.clienteNombre.trim() : "";
  if (nombre.length < 3) {
    return {ok: false, error: "El nombre del cliente es obligatorio"};
  }
  const telefono = esTexto(payload.clienteTelefono) ?
    payload.clienteTelefono.replace(/[^0-9]/g, "") :
    "";
  if (telefono.length < 7) {
    return {ok: false, error: "Telefono del cliente invalido"};
  }
  const email = esTexto(payload.clienteEmail) ? payload.clienteEmail.trim() : "";
  if (email.length > 0 && !RE_EMAIL.test(email)) {
    return {ok: false, error: "Correo del cliente invalido"};
  }

  const nivelInteres = esNumero(payload.nivelInteres) ? payload.nivelInteres : 0;
  if (nivelInteres < 0 || nivelInteres > 5) {
    return {ok: false, error: "nivelInteres fuera de rango (0-5)"};
  }
  const duracionMin = esNumero(payload.duracionMin) ? payload.duracionMin : 0;
  if (duracionMin < 0 || duracionMin > 600) {
    return {ok: false, error: "duracionMin fuera de rango (0-600)"};
  }
  const presupuestoMax = esNumero(payload.presupuestoMax) ?
    payload.presupuestoMax :
    0;
  if (presupuestoMax < 0) {
    return {ok: false, error: "presupuestoMax no puede ser negativo"};
  }

  const checklistCrudo = payload.checklist;
  const checklist: Record<string, boolean> = {};
  if (typeof checklistCrudo === "object" && checklistCrudo !== null) {
    for (const [clave, valor] of Object.entries(
      checklistCrudo as Record<string, unknown>
    )) {
      checklist[clave] = valor === true;
    }
  }

  const visita: Visita = {
    id,
    inmuebleId: payload.inmuebleId,
    asesorUid,
    clienteNombre: nombre,
    clienteTelefono: telefono,
    clienteEmail: email.length > 0 ? email : null,
    fechaProgramada: esNumero(payload.fechaProgramada) ?
      payload.fechaProgramada :
      ahora,
    fechaRegistro: esNumero(payload.fechaRegistro) ? payload.fechaRegistro : ahora,
    duracionMin,
    estado: payload.estado === "cancelada" ? "cancelada" : "registrada",
    checklist,
    observaciones: esTexto(payload.observaciones) ?
      payload.observaciones.trim().slice(0, 2000) :
      null,
    nivelInteres,
    presupuestoMax,
    tieneCredito: payload.tieneCredito === true,
    latitud: esNumero(payload.latitud) ? payload.latitud : null,
    longitud: esNumero(payload.longitud) ? payload.longitud : null,
    scoreLead: 0,
    temperatura: "frio",
    revision: esNumero(payload.revision) ? payload.revision : 1,
    updatedAt: esNumero(payload.updatedAt) ? payload.updatedAt : ahora,
    eliminado: payload.eliminado === true,
  };

  return {ok: true, valor: visita};
}
