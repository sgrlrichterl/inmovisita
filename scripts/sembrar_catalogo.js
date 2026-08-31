#!/usr/bin/env node
/**
 * Siembra el catalogo de inmuebles y usuarios de demostracion.
 *
 * Uso contra el emulador (recomendado para evaluar el proyecto):
 *
 *   export FIRESTORE_EMULATOR_HOST=localhost:8080
 *   export FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
 *   node scripts/sembrar_catalogo.js inmovisita-demo
 *
 * Uso contra un proyecto real (requiere GOOGLE_APPLICATION_CREDENTIALS):
 *
 *   node scripts/sembrar_catalogo.js mi-proyecto-firebase
 */
const admin = require("firebase-admin");

const projectId = process.argv[2] || process.env.GCLOUD_PROJECT || "inmovisita-demo";

admin.initializeApp({projectId});

const db = admin.firestore();
const auth = admin.auth();

const AHORA = Date.now();

const INMUEBLES = [
  ["inm-001", "MED-1024", "Apartamento con balcon en Laureles", "Cra 76 # 42-18", "Medellin", "Laureles", "apartamento", 620000000, 88, 3, 2, 6.2447, -75.5916],
  ["inm-002", "MED-1031", "Casa campestre en Rionegro", "Vereda El Tablazo km 4", "Rionegro", "El Tablazo", "casa", 980000000, 320, 4, 4, 6.1494, -75.3742],
  ["inm-003", "MED-1045", "Apartaestudio remodelado en Envigado", "Calle 37 Sur # 43-12", "Envigado", "La Magnolia", "apartamento", 310000000, 45, 1, 1, 6.1667, -75.5833],
  ["inm-004", "MED-1052", "Local comercial sobre via principal", "Av 33 # 68-40", "Medellin", "Belen", "local", 450000000, 120, 0, 2, 6.2308, -75.5906],
  ["inm-005", "MED-1063", "Oficina amoblada en El Poblado", "Cra 43A # 1-50, piso 8", "Medellin", "El Poblado", "oficina", 720000000, 95, 0, 2, 6.2088, -75.5674],
  ["inm-006", "MED-1077", "Lote urbanizable en Guarne", "Vereda La Clara lote 12", "Guarne", "La Clara", "lote", 260000000, 1200, 0, 0, 6.2803, -75.4419],
  ["inm-007", "MED-1088", "Casa de dos pisos en Bello", "Calle 50 # 55-21", "Bello", "Niquia", "casa", 395000000, 140, 4, 3, 6.3378, -75.5544],
  ["inm-008", "MED-1094", "Bodega industrial en Itagui", "Cra 50 # 78-15", "Itagui", "Santa Maria", "bodega", 1250000000, 640, 0, 2, 6.1719, -75.6114],
];

const USUARIOS = [
  {uid: "demo-asesor-001", email: "asesor@inmovisita.co", nombre: "Asesor Demo", rol: "asesor"},
  {uid: "demo-coord-001", email: "coordinador@inmovisita.co", nombre: "Coordinadora Demo", rol: "coordinador"},
];

async function sembrarInmuebles() {
  const lote = db.batch();
  for (const fila of INMUEBLES) {
    const [id, codigo, titulo, direccion, ciudad, barrio, tipo, precio, areaM2, habitaciones, banos, latitud, longitud] = fila;
    lote.set(db.collection("inmuebles").doc(id), {
      id, codigo, titulo, direccion, ciudad, barrio, tipo,
      precio, areaM2, habitaciones, banos, latitud, longitud,
      estado: "disponible",
      revision: 1,
      updatedAt: AHORA,
      eliminado: false,
    });
  }
  await lote.commit();
  console.log(`Catalogo sembrado: ${INMUEBLES.length} inmuebles`);
}

async function sembrarUsuarios() {
  for (const usuario of USUARIOS) {
    try {
      await auth.createUser({
        uid: usuario.uid,
        email: usuario.email,
        password: "demo1234",
        displayName: usuario.nombre,
      });
    } catch (error) {
      if (error.code !== "auth/uid-already-exists" &&
          error.code !== "auth/email-already-exists") {
        throw error;
      }
    }
    await auth.setCustomUserClaims(usuario.uid, {rol: usuario.rol});
    await db.collection("usuarios").doc(usuario.uid).set({
      ...usuario,
      updatedAt: AHORA,
    });
    console.log(`Usuario listo: ${usuario.email} (${usuario.rol})`);
  }
}

async function main() {
  console.log(`Proyecto: ${projectId}`);
  await sembrarInmuebles();
  await sembrarUsuarios();
  console.log("Siembra completada.");
}

main().catch((error) => {
  console.error("Fallo la siembra:", error);
  process.exit(1);
});
