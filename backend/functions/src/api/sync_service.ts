import {calcularScoreLead} from "../dominio/scoring";
import {
  decidirEscritura,
  siguienteRevision,
} from "../dominio/reconciliacion";
import {
  ResultadoOperacion,
  RespuestaPull,
  SobreOperacion,
  Versionado,
  Visita,
} from "../dominio/tipos";
import {normalizarVisita, validarSobre} from "../dominio/validacion";
import {COLECCIONES, db} from "../infra/firebase";
import {Identidad} from "./middleware";

const LIMITE_MAXIMO = 500;

/**
 * Aplica un lote de operaciones provenientes de un dispositivo.
 *
 * Garantias:
 * * **Idempotencia**: cada `operacionId` se registra en `operaciones_sync`;
 *   si el lote se reenvia tras un corte de red, la operacion repetida devuelve
 *   la misma confirmacion sin volver a escribir.
 * * **Autoridad del servidor**: el `asesorUid` y el `scoreLead` se calculan
 *   aqui, ignorando lo que envie el cliente.
 * * **Atomicidad por operacion**: cada escritura se hace en una transaccion de
 *   Firestore junto con su registro de idempotencia.
 */
export async function aplicarLote(
  operaciones: unknown[],
  identidad: Identidad,
  ahora: number = Date.now()
): Promise<ResultadoOperacion[]> {
  const resultados: ResultadoOperacion[] = [];

  for (const crudo of operaciones.slice(0, LIMITE_MAXIMO)) {
    const validacion = validarSobre(crudo);
    if (!validacion.ok) {
      resultados.push({
        operacionId:
          typeof (crudo as {operacionId?: string})?.operacionId === "string" ?
            (crudo as {operacionId: string}).operacionId :
            "desconocida",
        entidadId: "",
        aceptada: false,
        revision: 0,
        updatedAt: 0,
        error: validacion.error,
        reintentable: false,
      });
      continue;
    }

    const sobre = validacion.valor;
    try {
      resultados.push(await aplicarOperacion(sobre, identidad, ahora));
    } catch (error) {
      console.error("Fallo al aplicar la operacion", sobre.operacionId, error);
      resultados.push({
        operacionId: sobre.operacionId,
        entidadId: sobre.entidadId,
        aceptada: false,
        revision: 0,
        updatedAt: 0,
        error: "Error interno al aplicar la operacion",
        reintentable: true,
      });
    }
  }

  return resultados;
}

async function aplicarOperacion(
  sobre: SobreOperacion,
  identidad: Identidad,
  ahora: number
): Promise<ResultadoOperacion> {
  if (sobre.entidad !== "visitas") {
    return {
      operacionId: sobre.operacionId,
      entidadId: sobre.entidadId,
      aceptada: false,
      revision: 0,
      updatedAt: 0,
      error: `Entidad no soportada: ${sobre.entidad}`,
      reintentable: false,
    };
  }

  const normalizada = normalizarVisita(sobre.payload, identidad.uid, ahora);
  if (!normalizada.ok) {
    return {
      operacionId: sobre.operacionId,
      entidadId: sobre.entidadId,
      aceptada: false,
      revision: 0,
      updatedAt: 0,
      error: normalizada.error,
      reintentable: false,
    };
  }

  const entrante = normalizada.valor;
  const refOperacion = db.collection(COLECCIONES.operaciones)
    .doc(sobre.operacionId);
  const refVisita = db.collection(COLECCIONES.visitas).doc(entrante.id);
  const refInmueble = db.collection(COLECCIONES.inmuebles)
    .doc(entrante.inmuebleId);

  return db.runTransaction(async (tx) => {
    const yaAplicada = await tx.get(refOperacion);
    if (yaAplicada.exists) {
      const datos = yaAplicada.data() as ResultadoOperacion;
      return {...datos, operacionId: sobre.operacionId};
    }

    const inmueble = await tx.get(refInmueble);
    if (!inmueble.exists) {
      return rechazo(
        sobre,
        "El inmueble referenciado no existe",
        false
      );
    }

    const actual = await tx.get(refVisita);
    const almacenada = actual.exists ?
      (actual.data() as Visita) :
      null;

    if (almacenada !== null && almacenada.asesorUid !== identidad.uid &&
        identidad.rol === "asesor") {
      return rechazo(sobre, "La visita pertenece a otro asesor", false);
    }

    const decision = decidirEscritura(
      almacenada as Versionado | null,
      entrante
    );
    if (decision === "rechazar-obsoleta") {
      return rechazo(sobre, "Version obsoleta: el servidor tiene un dato mas reciente", false);
    }

    const precio = (inmueble.data()?.precio as number | undefined) ?? 0;
    const score = calcularScoreLead(
      {
        nivelInteres: entrante.nivelInteres,
        presupuestoMax: entrante.presupuestoMax,
        tieneCredito: entrante.tieneCredito,
        duracionMin: entrante.duracionMin,
        checklist: entrante.checklist,
        observaciones: entrante.observaciones,
        totalFotos: entrante.totalFotos ?? 0,
      },
      precio
    );

    const revision = decision === "sin-cambios" ?
      (almacenada?.revision ?? 1) :
      siguienteRevision(almacenada as Versionado | null, entrante);

    const documento: Visita = {
      ...entrante,
      scoreLead: score.score,
      temperatura: score.temperatura,
      revision,
      updatedAt: ahora,
      eliminado: sobre.operacion === "eliminar" ? true : entrante.eliminado,
    };

    tx.set(refVisita, documento, {merge: true});

    const confirmacion: ResultadoOperacion = {
      operacionId: sobre.operacionId,
      entidadId: entrante.id,
      aceptada: true,
      revision,
      updatedAt: ahora,
      reintentable: true,
    };
    tx.set(refOperacion, {
      ...confirmacion,
      asesorUid: identidad.uid,
      registradaEn: ahora,
    });

    return confirmacion;
  });
}

function rechazo(
  sobre: SobreOperacion,
  mensaje: string,
  reintentable: boolean
): ResultadoOperacion {
  return {
    operacionId: sobre.operacionId,
    entidadId: sobre.entidadId,
    aceptada: false,
    revision: 0,
    updatedAt: 0,
    error: mensaje,
    reintentable,
  };
}

/**
 * Devuelve los cambios posteriores a `desde` (sincronizacion delta).
 *
 * Un asesor solo recibe sus propias visitas; un coordinador recibe las de todo
 * el equipo. El catalogo de inmuebles es comun.
 */
export async function obtenerCambios(
  desde: number,
  limite: number,
  identidad: Identidad
): Promise<RespuestaPull> {
  const tope = Math.min(Math.max(limite, 1), LIMITE_MAXIMO);

  const consultaInmuebles = db.collection(COLECCIONES.inmuebles)
    .where("updatedAt", ">", desde)
    .orderBy("updatedAt", "asc")
    .limit(tope);

  let consultaVisitas = db.collection(COLECCIONES.visitas)
    .where("updatedAt", ">", desde)
    .orderBy("updatedAt", "asc")
    .limit(tope);

  if (identidad.rol === "asesor") {
    consultaVisitas = db.collection(COLECCIONES.visitas)
      .where("asesorUid", "==", identidad.uid)
      .where("updatedAt", ">", desde)
      .orderBy("updatedAt", "asc")
      .limit(tope);
  }

  const [inmuebles, visitas] = await Promise.all([
    consultaInmuebles.get(),
    consultaVisitas.get(),
  ]);

  const docsInmuebles = inmuebles.docs.map((d) => d.data());
  const docsVisitas = visitas.docs.map((d) => d.data());

  const cursor = Math.max(
    desde,
    ...docsInmuebles.map((d) => Number(d.updatedAt) || 0),
    ...docsVisitas.map((d) => Number(d.updatedAt) || 0)
  );

  return {
    inmuebles: docsInmuebles,
    visitas: docsVisitas,
    cursor,
    hayMas: inmuebles.size === tope || visitas.size === tope,
  };
}
