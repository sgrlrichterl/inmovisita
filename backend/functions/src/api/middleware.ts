import {NextFunction, Request, Response} from "express";

import {auth} from "../infra/firebase";

/** Identidad del llamador, derivada exclusivamente del token verificado. */
export interface Identidad {
  uid: string;
  email: string;
  rol: "asesor" | "coordinador" | "admin";
}

export interface PeticionAutenticada extends Request {
  identidad?: Identidad;
}

/**
 * Verifica el token de Firebase Auth enviado en `Authorization: Bearer`.
 *
 * El rol se lee de los *custom claims* del token, no del cuerpo de la
 * peticion: el cliente no puede escalar privilegios.
 */
export async function verificarToken(
  req: PeticionAutenticada,
  res: Response,
  next: NextFunction
): Promise<void> {
  const cabecera = req.headers.authorization ?? "";
  if (!cabecera.startsWith("Bearer ")) {
    res.status(401).json({error: {message: "Token ausente"}});
    return;
  }

  try {
    const decodificado = await auth.verifyIdToken(cabecera.substring(7), true);
    const rol = decodificado.rol;
    req.identidad = {
      uid: decodificado.uid,
      email: decodificado.email ?? "",
      rol: rol === "coordinador" || rol === "admin" ? rol : "asesor",
    };
    next();
  } catch (error) {
    res.status(401).json({
      error: {message: "Token invalido o expirado"},
    });
  }
}

/** Restringe el acceso a los roles indicados. */
export function exigirRol(...roles: Identidad["rol"][]) {
  return (
    req: PeticionAutenticada,
    res: Response,
    next: NextFunction
  ): void => {
    if (!req.identidad || !roles.includes(req.identidad.rol)) {
      res.status(403).json({error: {message: "Permisos insuficientes"}});
      return;
    }
    next();
  };
}

/** Envuelve un manejador asincrono para capturar errores no controlados. */
export function asincrono(
  manejador: (
    req: PeticionAutenticada,
    res: Response
  ) => Promise<void>
) {
  return (req: PeticionAutenticada, res: Response): void => {
    manejador(req, res).catch((error: unknown) => {
      console.error("Error no controlado", error);
      if (!res.headersSent) {
        res.status(500).json({error: {message: "Error interno"}});
      }
    });
  };
}
