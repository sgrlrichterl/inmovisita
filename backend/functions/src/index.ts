import {setGlobalOptions} from "firebase-functions/v2";
import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";

import {crearApi} from "./api/router";
import {auth, COLECCIONES, db} from "./infra/firebase";

// Limites globales: contienen el costo ante un pico de trafico y evitan
// arranques en frio masivos.
setGlobalOptions({
  region: "us-central1",
  maxInstances: 10,
  memory: "256MiB",
  timeoutSeconds: 60,
});

/** API REST consumida por la aplicacion movil. */
export const api = onRequest({cors: true}, crearApi());

/**
 * Asigna el rol de un usuario como *custom claim*.
 *
 * Solo un administrador puede invocarla; el rol viaja luego dentro del token
 * firmado y es lo que leen tanto la API como las reglas de Firestore.
 */
export const asignarRol = onCall<{uid: string; rol: string}>(async (peticion) => {
  if (peticion.auth?.token?.rol !== "admin") {
    throw new HttpsError("permission-denied", "Solo un administrador puede asignar roles");
  }
  const {uid, rol} = peticion.data;
  if (!["asesor", "coordinador", "admin"].includes(rol)) {
    throw new HttpsError("invalid-argument", `Rol no valido: ${rol}`);
  }

  await auth.setCustomUserClaims(uid, {rol});
  await db.collection(COLECCIONES.usuarios).doc(uid).set(
    {rol, updatedAt: Date.now()},
    {merge: true}
  );

  return {ok: true, uid, rol};
});

export {alEscribirVisita} from "./triggers/notificaciones";
export {metricasDiarias} from "./triggers/metricas";
