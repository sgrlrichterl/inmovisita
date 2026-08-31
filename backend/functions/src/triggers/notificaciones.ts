import {onDocumentWritten} from "firebase-functions/v2/firestore";

import {Visita} from "../dominio/tipos";
import {COLECCIONES, db, messaging} from "../infra/firebase";

/**
 * Notifica al coordinador cuando una visita se convierte en lead caliente.
 *
 * Se dispara sobre la escritura del documento (no desde la app) para que la
 * notificacion ocurra tambien cuando la visita llega horas despues, al
 * sincronizarse un dispositivo que estuvo sin cobertura.
 */
export const alEscribirVisita = onDocumentWritten(
  {document: "visitas/{visitaId}", region: "us-central1"},
  async (evento) => {
    const despues = evento.data?.after?.data() as Visita | undefined;
    const antes = evento.data?.before?.data() as Visita | undefined;

    if (!despues || despues.eliminado) return;
    if (despues.temperatura !== "caliente") return;
    if (antes?.temperatura === "caliente") return; // ya se habia notificado

    const coordinadores = await db.collection(COLECCIONES.usuarios)
      .where("rol", "in", ["coordinador", "admin"])
      .get();

    const tokens = coordinadores.docs
      .map((d) => d.data().fcmToken as string | undefined)
      .filter((t): t is string => typeof t === "string" && t.length > 0);

    if (tokens.length === 0) return;

    await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: "Nuevo lead caliente",
        body: `${despues.clienteNombre} - puntaje ${despues.scoreLead}/100`,
      },
      data: {
        visitaId: despues.id,
        inmuebleId: despues.inmuebleId,
        score: String(despues.scoreLead),
      },
    });
  }
);
