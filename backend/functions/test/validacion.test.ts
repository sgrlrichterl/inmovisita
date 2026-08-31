import {normalizarVisita, validarSobre} from "../src/dominio/validacion";

const sobreValido = {
  operacionId: "8f14e45f-ea3e-4a1d-9c1f-1b2c3d4e5f60",
  entidad: "visitas",
  entidadId: "c0ffee00-1111-2222-3333-444455556666",
  operacion: "crear",
  payload: {},
};

describe("validarSobre", () => {
  it("acepta un sobre bien formado", () => {
    const resultado = validarSobre(sobreValido);
    expect(resultado.ok).toBe(true);
  });

  it("rechaza entidades no soportadas", () => {
    const resultado = validarSobre({...sobreValido, entidad: "usuarios"});
    expect(resultado.ok).toBe(false);
  });

  it("rechaza operaciones desconocidas", () => {
    const resultado = validarSobre({...sobreValido, operacion: "truncar"});
    expect(resultado.ok).toBe(false);
  });

  it("rechaza un payload que no es objeto", () => {
    const resultado = validarSobre({...sobreValido, payload: "hola"});
    expect(resultado.ok).toBe(false);
  });

  it("rechaza entradas que no son objetos", () => {
    expect(validarSobre(null).ok).toBe(false);
    expect(validarSobre("texto").ok).toBe(false);
    expect(validarSobre(42).ok).toBe(false);
  });
});

const AHORA = 1_700_000_000_000;

const payloadValido = {
  id: "c0ffee00-1111-2222-3333-444455556666",
  inmuebleId: "inm-001",
  asesorUid: "usuario-malicioso",
  clienteNombre: "  Maria Restrepo ",
  clienteTelefono: "(310) 555-0123",
  clienteEmail: "maria@example.com",
  nivelInteres: 4,
  duracionMin: 30,
  presupuestoMax: 600_000_000,
  tieneCredito: true,
  checklist: {documentos_verificados: true, otra: "si"},
  observaciones: "  Pidio cotizacion  ",
  scoreLead: 100,
  temperatura: "caliente",
};

describe("normalizarVisita", () => {
  it("toma el asesor del token y descarta el del cuerpo", () => {
    const resultado = normalizarVisita(payloadValido, "asesor-real", AHORA);
    expect(resultado.ok).toBe(true);
    if (!resultado.ok) return;
    expect(resultado.valor.asesorUid).toBe("asesor-real");
  });

  it("no confia en el puntaje enviado por el dispositivo", () => {
    const resultado = normalizarVisita(payloadValido, "asesor-real", AHORA);
    expect(resultado.ok).toBe(true);
    if (!resultado.ok) return;
    expect(resultado.valor.scoreLead).toBe(0);
    expect(resultado.valor.temperatura).toBe("frio");
  });

  it("normaliza texto, telefono y checklist", () => {
    const resultado = normalizarVisita(payloadValido, "asesor-real", AHORA);
    expect(resultado.ok).toBe(true);
    if (!resultado.ok) return;
    expect(resultado.valor.clienteNombre).toBe("Maria Restrepo");
    expect(resultado.valor.clienteTelefono).toBe("3105550123");
    expect(resultado.valor.checklist).toEqual({
      documentos_verificados: true,
      otra: false,
    });
    expect(resultado.valor.observaciones).toBe("Pidio cotizacion");
  });

  it("rechaza un nombre demasiado corto", () => {
    const resultado = normalizarVisita(
      {...payloadValido, clienteNombre: "Al"},
      "asesor-real",
      AHORA
    );
    expect(resultado.ok).toBe(false);
  });

  it("rechaza un telefono invalido", () => {
    const resultado = normalizarVisita(
      {...payloadValido, clienteTelefono: "123"},
      "asesor-real",
      AHORA
    );
    expect(resultado.ok).toBe(false);
  });

  it("rechaza un correo mal formado", () => {
    const resultado = normalizarVisita(
      {...payloadValido, clienteEmail: "maria@@correo"},
      "asesor-real",
      AHORA
    );
    expect(resultado.ok).toBe(false);
  });

  it("rechaza valores fuera de rango", () => {
    expect(
      normalizarVisita(
        {...payloadValido, nivelInteres: 9},
        "asesor-real",
        AHORA
      ).ok
    ).toBe(false);
    expect(
      normalizarVisita(
        {...payloadValido, duracionMin: 9999},
        "asesor-real",
        AHORA
      ).ok
    ).toBe(false);
    expect(
      normalizarVisita(
        {...payloadValido, presupuestoMax: -5},
        "asesor-real",
        AHORA
      ).ok
    ).toBe(false);
  });

  it("recorta observaciones muy largas", () => {
    const resultado = normalizarVisita(
      {...payloadValido, observaciones: "x".repeat(5000)},
      "asesor-real",
      AHORA
    );
    expect(resultado.ok).toBe(true);
    if (!resultado.ok) return;
    expect(resultado.valor.observaciones).toHaveLength(2000);
  });
});
