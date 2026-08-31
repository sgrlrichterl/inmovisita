import {
  decidirEscritura,
  siguienteRevision,
} from "../src/dominio/reconciliacion";
import {Versionado} from "../src/dominio/tipos";

const reg = (revision: number, updatedAt: number): Versionado => ({
  id: "v-1",
  revision,
  updatedAt,
});

describe("decidirEscritura", () => {
  it("acepta la creacion cuando no hay copia almacenada", () => {
    expect(decidirEscritura(null, reg(1, 1000))).toBe("aplicar");
  });

  it("detecta una escritura identica", () => {
    expect(decidirEscritura(reg(3, 5000), reg(3, 5000))).toBe("sin-cambios");
  });

  it("acepta una revision mayor", () => {
    expect(decidirEscritura(reg(3, 5000), reg(4, 4000))).toBe("aplicar");
  });

  it("acepta una revision menor pero mas reciente en el tiempo", () => {
    expect(decidirEscritura(reg(5, 1000), reg(2, 9000))).toBe("aplicar");
  });

  it("rechaza de forma permanente una escritura obsoleta", () => {
    expect(decidirEscritura(reg(5, 9000), reg(2, 1000)))
      .toBe("rechazar-obsoleta");
  });
});

describe("siguienteRevision", () => {
  it("avanza siempre desde la revision mas alta conocida", () => {
    expect(siguienteRevision(reg(4, 1000), reg(2, 2000))).toBe(5);
    expect(siguienteRevision(reg(4, 1000), reg(9, 2000))).toBe(10);
    expect(siguienteRevision(null, reg(1, 2000))).toBe(2);
  });

  it("es monotona ante reenvios del mismo dato", () => {
    let almacenada = reg(1, 1000);
    for (let i = 0; i < 5; i++) {
      const nueva = siguienteRevision(almacenada, reg(1, 1000));
      expect(nueva).toBeGreaterThan(almacenada.revision);
      almacenada = reg(nueva, 1000);
    }
  });
});
