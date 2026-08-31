import {Versionado} from "./tipos";

export type DecisionServidor =
  | "aplicar"
  | "sin-cambios"
  | "rechazar-obsoleta";

/**
 * Decide si una escritura entrante debe aplicarse sobre el estado almacenado.
 *
 * Reglas (el servidor es la autoridad):
 * 1. Si no existe copia almacenada, se acepta (creacion).
 * 2. Si la revision entrante es mayor o igual a la almacenada, se acepta.
 * 3. Si la revision entrante es menor pero su marca de tiempo es posterior,
 *    se acepta: el dispositivo estuvo mucho tiempo sin conectarse pero su dato
 *    es mas reciente.
 * 4. En cualquier otro caso la escritura es obsoleta y se rechaza de forma
 *    permanente (el cliente no debe reintentarla; recibira el estado del
 *    servidor en el siguiente `pull`).
 */
export function decidirEscritura(
  almacenada: Versionado | null,
  entrante: Versionado
): DecisionServidor {
  if (almacenada === null) return "aplicar";

  if (
    entrante.revision === almacenada.revision &&
    entrante.updatedAt === almacenada.updatedAt
  ) {
    return "sin-cambios";
  }
  if (entrante.revision >= almacenada.revision) return "aplicar";
  if (entrante.updatedAt > almacenada.updatedAt) return "aplicar";
  return "rechazar-obsoleta";
}

/**
 * Revision que debe quedar almacenada tras aceptar una escritura.
 *
 * Siempre avanza: garantiza que el contador sea monotono aunque el cliente
 * envie un valor menor o repetido.
 */
export function siguienteRevision(
  almacenada: Versionado | null,
  entrante: Versionado
): number {
  const base = Math.max(almacenada?.revision ?? 0, entrante.revision ?? 0);
  return base + 1;
}
