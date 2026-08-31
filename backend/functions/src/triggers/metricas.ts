import {onSchedule} from "firebase-functions/v2/scheduler";

import {calcularMetricas, fechaColombiana} from "../dominio/metricas";
import {Visita} from "../dominio/tipos";
import {COLECCIONES, db} from "../infra/firebase";

/**
 * Trabajo programado que consolida las metricas del dia anterior.
 *
 * Corre una sola vez al dia: evita que el tablero del coordinador tenga que
 * recorrer toda la coleccion de visitas en cada consulta.
 */
export const metricasDiarias = onSchedule(
  {schedule: "0 6 * * *", timeZone: "America/Bogota", region: "us-central1"},
  async () => {
    const ahora = Date.now();
    const inicio = ahora - 24 * 60 * 60 * 1000;

    const consulta = await db.collection(COLECCIONES.visitas)
      .where("fechaRegistro", ">=", inicio)
      .get();

    const visitas = consulta.docs.map((d) => d.data() as Visita);
    const fecha = fechaColombiana(inicio);
    const metrica = calcularMetricas(visitas, fecha, ahora);

    await db.collection(COLECCIONES.metricas).doc(fecha).set(metrica);
  }
);
