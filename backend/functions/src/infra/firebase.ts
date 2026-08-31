import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

export const db = admin.firestore();
export const auth = admin.auth();
export const messaging = admin.messaging();

/** Nombres de las colecciones de Firestore. */
export const COLECCIONES = {
  usuarios: "usuarios",
  inmuebles: "inmuebles",
  visitas: "visitas",
  operaciones: "operaciones_sync",
  metricas: "metricas_diarias",
} as const;

export {admin};
