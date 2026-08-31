import express from "express";

import {COLECCIONES, db} from "../infra/firebase";
import {
  asincrono,
  exigirRol,
  PeticionAutenticada,
  verificarToken,
} from "./middleware";
import {aplicarLote, obtenerCambios} from "./sync_service";

/**
 * API REST de InmoVisita.
 *
 * Prefijo de version `/v1`: permite evolucionar el contrato sin romper las
 * apps ya instaladas en los dispositivos de los asesores.
 */
export function crearApi(): express.Express {
  const app = express();

  app.use(express.json({limit: "1mb"}));

  // Sonda de salud: no requiere autenticacion.
  app.get("/v1/salud", (_req, res) => {
    res.json({estado: "ok", version: "1.0.0", hora: Date.now()});
  });

  app.use(verificarToken);

  /** Descarga incremental de cambios. */
  app.get(
    "/v1/sync/pull",
    asincrono(async (req: PeticionAutenticada, res) => {
      const desde = Number(req.query.desde ?? 0);
      const limite = Number(req.query.limite ?? 200);
      if (!Number.isFinite(desde) || desde < 0) {
        res.status(400).json({error: {message: "Parametro 'desde' invalido"}});
        return;
      }
      const cambios = await obtenerCambios(desde, limite, req.identidad!);
      res.json(cambios);
    })
  );

  /** Envio de operaciones pendientes desde el dispositivo. */
  app.post(
    "/v1/sync/push",
    asincrono(async (req: PeticionAutenticada, res) => {
      const operaciones = (req.body as {operaciones?: unknown}).operaciones;
      if (!Array.isArray(operaciones)) {
        res.status(400).json({
          error: {message: "Se esperaba un arreglo 'operaciones'"},
        });
        return;
      }
      const resultados = await aplicarLote(operaciones, req.identidad!);
      res.json({resultados});
    })
  );

  /** Tablero del coordinador: leads calientes del equipo. */
  app.get(
    "/v1/leads",
    exigirRol("coordinador", "admin"),
    asincrono(async (_req: PeticionAutenticada, res) => {
      const consulta = await db.collection(COLECCIONES.visitas)
        .where("temperatura", "==", "caliente")
        .orderBy("updatedAt", "desc")
        .limit(50)
        .get();
      res.json({leads: consulta.docs.map((d) => d.data())});
    })
  );

  /** Metricas agregadas por el trabajo programado. */
  app.get(
    "/v1/metricas",
    exigirRol("coordinador", "admin"),
    asincrono(async (_req: PeticionAutenticada, res) => {
      const consulta = await db.collection(COLECCIONES.metricas)
        .orderBy("fecha", "desc")
        .limit(30)
        .get();
      res.json({metricas: consulta.docs.map((d) => d.data())});
    })
  );

  app.use((_req, res) => {
    res.status(404).json({error: {message: "Recurso no encontrado"}});
  });

  return app;
}
