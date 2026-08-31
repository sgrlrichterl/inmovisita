/**
 * Generador de la presentación ejecutiva de InmoVisita.
 *
 *   node build_deck.js
 *
 * Produce InmoVisita-Presentacion.pptx en esta misma carpeta.
 */
const pptxgen = require("pptxgenjs");

const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE"; // 13.33 x 7.5 pulgadas
pres.author = "Sebastián García Riveros";
pres.company = "Católica del Norte Fundación Universitaria";
pres.title = "InmoVisita";

const W = 13.33;
const H = 7.5;
const M = 0.7; // margen lateral

const C = {
  dark: "0B3B36",
  darker: "072826",
  teal: "0F766E",
  tealSoft: "E6F2F0",
  amber: "E08A2E",
  amberSoft: "FBEEDC",
  text: "16302C",
  muted: "5B6B69",
  white: "FFFFFF",
  line: "CFE0DC",
};

const FH = "Cambria"; // titulares
const FB = "Calibri"; // cuerpo

/* ------------------------------------------------------------------ */
/* Utilidades de composicion                                           */
/* ------------------------------------------------------------------ */

function slideOscura() {
  const s = pres.addSlide();
  s.background = { color: C.dark };
  return s;
}

function slideClara() {
  const s = pres.addSlide();
  s.background = { color: C.white };
  return s;
}

function titulo(s, texto, sub) {
  s.addText(texto, {
    x: M, y: 0.45, w: W - 2 * M, h: 0.75,
    fontFace: FH, fontSize: 32, bold: true, color: C.dark,
    isTextBox: true, margin: 0,
  });
  if (sub) {
    s.addText(sub, {
      x: M, y: 1.18, w: W - 2 * M, h: 0.4,
      fontFace: FB, fontSize: 14, color: C.muted,
      isTextBox: true, margin: 0,
    });
  }
}

function tarjeta(s, { x, y, w, h, fill = C.white, borde = C.line }) {
  s.addShape(pres.ShapeType.roundRect, {
    x, y, w, h,
    rectRadius: 0.09,
    fill: { color: fill },
    line: { color: borde, width: 1 },
    shadow: { type: "outer", color: "0B3B36", opacity: 0.08, blur: 8, offset: 2, angle: 90 },
  });
}

function circulo(s, { x, y, d = 0.46, texto, fill = C.teal, color = C.white, size = 15 }) {
  s.addShape(pres.ShapeType.ellipse, {
    x, y, w: d, h: d,
    fill: { color: fill },
    line: { color: fill, width: 0 },
  });
  s.addText(texto, {
    x, y, w: d, h: d,
    fontFace: FB, fontSize: size, bold: true, color,
    align: "center", valign: "middle", isTextBox: true, margin: 0,
  });
}

function pie(s, texto) {
  s.addText(texto, {
    x: M, y: H - 0.55, w: W - 2 * M, h: 0.3,
    fontFace: FB, fontSize: 10, color: C.muted,
    isTextBox: true, margin: 0,
  });
}

/* ================================================================== */
/* 1. Portada                                                          */
/* ================================================================== */
{
  const s = slideOscura();

  s.addShape(pres.ShapeType.ellipse, {
    x: W - 3.4, y: -1.6, w: 5.0, h: 5.0,
    fill: { color: C.teal, transparency: 72 }, line: { width: 0 },
  });
  s.addShape(pres.ShapeType.ellipse, {
    x: W - 2.2, y: 3.6, w: 3.2, h: 3.2,
    fill: { color: C.amber, transparency: 84 }, line: { width: 0 },
  });

  s.addText("TALLER ABP  ·  ENTREGA 1  ·  20 %", {
    x: M, y: 1.35, w: 8.5, h: 0.35,
    fontFace: FB, fontSize: 12, bold: true, color: C.amber,
    charSpacing: 2, isTextBox: true, margin: 0,
  });

  s.addText("InmoVisita", {
    x: M, y: 1.8, w: 9.5, h: 1.15,
    fontFace: FH, fontSize: 60, bold: true, color: C.white,
    isTextBox: true, margin: 0,
  });

  s.addText(
    "Aplicación móvil offline-first para el registro y la calificación\nautomática de visitas inmobiliarias en zonas sin cobertura",
    {
      x: M, y: 3.0, w: 8.8, h: 1.0,
      fontFace: FB, fontSize: 17, color: "C9DEDA",
      lineSpacing: 26, isTextBox: true, margin: 0,
    }
  );

  s.addShape(pres.ShapeType.roundRect, {
    x: M, y: 4.35, w: 3.05, h: 0.42, rectRadius: 0.2,
    fill: { color: C.teal }, line: { width: 0 },
  });
  s.addText("Flutter + Firebase Serverless", {
    x: M, y: 4.35, w: 3.05, h: 0.42,
    fontFace: FB, fontSize: 11, bold: true, color: C.white,
    align: "center", valign: "middle", isTextBox: true, margin: 0,
  });

  s.addText(
    [
      { text: "Sebastián García Riveros", options: { bold: true, breakLine: true } },
      { text: "Diseño de Aplicaciones Móviles  ·  Ingeniería Informática", options: { breakLine: true } },
      { text: "Facultad de Ingeniería y Ciencias Ambientales  ·  Católica del Norte Fundación Universitaria", options: {} },
    ],
    {
      x: M, y: 5.5, w: 9.5, h: 1.1,
      fontFace: FB, fontSize: 13, color: "9FBDB7",
      lineSpacing: 20, isTextBox: true, margin: 0,
    }
  );

  s.addNotes(
    "Presentación del Taller ABP. InmoVisita resuelve un problema real del sector inmobiliario: " +
    "el asesor trabaja donde no hay señal y las herramientas de la agencia exigen conexión permanente."
  );
}

/* ================================================================== */
/* 2. El problema                                                      */
/* ================================================================== */
{
  const s = slideClara();
  titulo(s, "El problema", "El dato más valioso del negocio se genera justo donde no hay red");

  const pasos = [
    ["1", "Muestra el inmueble", "En sitio, sin señal de datos"],
    ["2", "Anota en papel o notas", "Formato libre, campos omitidos"],
    ["3", "Envía fotos por mensajería", "Evidencia dispersa, sin trazabilidad"],
    ["4", "Retranscribe al CRM", "Doble digitación al final del día"],
    ["5", "El coordinador se entera", "El lead ya se enfrió"],
  ];

  let y = 1.85;
  pasos.forEach(([n, tit, desc]) => {
    circulo(s, { x: M, y: y + 0.04, d: 0.4, texto: n, size: 13 });
    s.addText(tit, {
      x: M + 0.58, y, w: 4.3, h: 0.28,
      fontFace: FB, fontSize: 14, bold: true, color: C.text,
      isTextBox: true, margin: 0,
    });
    s.addText(desc, {
      x: M + 0.58, y: y + 0.27, w: 4.5, h: 0.28,
      fontFace: FB, fontSize: 11, color: C.muted,
      isTextBox: true, margin: 0,
    });
    y += 0.78;
  });

  tarjeta(s, { x: 6.6, y: 1.8, w: 6.03, h: 1.75, fill: C.tealSoft, borde: C.tealSoft });
  s.addText("56,9 %", {
    x: 6.95, y: 1.95, w: 2.6, h: 0.85,
    fontFace: FH, fontSize: 46, bold: true, color: C.teal,
    isTextBox: true, margin: 0,
  });
  s.addText(
    "de los hogares rurales en Colombia tenía internet en 2025, frente al 73,9 % del promedio nacional (MinTIC, 2026)",
    {
      x: 9.55, y: 1.98, w: 2.75, h: 1.4,
      fontFace: FB, fontSize: 11.5, color: C.text,
      lineSpacing: 16, isTextBox: true, margin: 0,
    }
  );

  tarjeta(s, { x: 6.6, y: 3.75, w: 6.03, h: 2.35 });
  s.addText("Lo que cuesta hoy", {
    x: 6.95, y: 3.95, w: 5.3, h: 0.3,
    fontFace: FB, fontSize: 15, bold: true, color: C.dark,
    isTextBox: true, margin: 0,
  });
  s.addText(
    [
      { text: "Doble digitación de cada visita, con pérdida de detalle", options: { bullet: true, breakLine: true } },
      { text: "Horas o un día completo de latencia hasta el lead", options: { bullet: true, breakLine: true } },
      { text: "Calificación subjetiva, no comparable entre asesores", options: { bullet: true, breakLine: true } },
      { text: "Evidencia fuera de todo sistema auditable", options: { bullet: true } },
    ],
    {
      x: 6.95, y: 4.35, w: 5.3, h: 1.6,
      fontFace: FB, fontSize: 12.5, color: C.text,
      paraSpaceAfter: 7, isTextBox: true, margin: 0,
    }
  );

  pie(s, "Fuente: Ministerio TIC de Colombia (2026).");
  s.addNotes("El proceso actual tiene cinco pasos y dos de ellos son puro reproceso.");
}

/* ================================================================== */
/* 3. Pregunta problema                                                */
/* ================================================================== */
{
  const s = slideOscura();

  s.addShape(pres.ShapeType.ellipse, {
    x: -1.5, y: 4.4, w: 4.4, h: 4.4,
    fill: { color: C.teal, transparency: 80 }, line: { width: 0 },
  });

  s.addText("PREGUNTA PROBLEMA", {
    x: M, y: 1.35, w: 8, h: 0.35,
    fontFace: FB, fontSize: 12, bold: true, color: C.amber,
    charSpacing: 2, isTextBox: true, margin: 0,
  });

  s.addText(
    "¿De qué manera una aplicación móvil multiplataforma en Flutter, con arquitectura " +
    "offline-first y backend serverless en Firebase, permite eliminar la doble digitación y " +
    "reducir a menos de 5 minutos el tiempo entre el cierre de una visita y la disponibilidad " +
    "del lead calificado, en zonas con conectividad intermitente?",
    {
      x: M, y: 1.95, w: 11.4, h: 2.9,
      fontFace: FH, fontSize: 27, color: C.white,
      lineSpacing: 40, isTextBox: true, margin: 0,
    }
  );

  const metas = [
    ["100 %", "del formulario\ndisponible sin red"],
    ["< 5 min", "hasta el lead visible\ntras recuperar señal"],
    ["0", "retranscripciones\nal CRM"],
  ];
  metas.forEach(([valor, etiqueta], i) => {
    const x = M + i * 3.9;
    s.addText(valor, {
      x, y: 5.2, w: 3.5, h: 0.6,
      fontFace: FH, fontSize: 34, bold: true, color: C.amber,
      isTextBox: true, margin: 0,
    });
    s.addText(etiqueta, {
      x, y: 5.85, w: 3.5, h: 0.7,
      fontFace: FB, fontSize: 12, color: "9FBDB7",
      lineSpacing: 16, isTextBox: true, margin: 0,
    });
  });

  s.addNotes("Las tres metas de la derecha son las variables medibles del objetivo general.");
}

/* ================================================================== */
/* 4. Objetivo general SMART                                           */
/* ================================================================== */
{
  const s = slideClara();
  titulo(s, "Objetivo general", "Formulado bajo el criterio SMART");

  tarjeta(s, { x: M, y: 1.8, w: W - 2 * M, h: 1.5, fill: C.tealSoft, borde: C.tealSoft });
  s.addText(
    "Desarrollar y desplegar, en 8 semanas, una aplicación móvil multiplataforma en Flutter con arquitectura " +
    "offline-first y backend serverless en Firebase que permita registrar el 100 % de una visita inmobiliaria " +
    "sin conexión y sincronizar el lead calificado en menos de 5 minutos desde que el dispositivo recupera " +
    "cobertura, eliminando la retranscripción manual en el CRM.",
    {
      x: M + 0.35, y: 2.0, w: W - 2 * M - 0.7, h: 1.15,
      fontFace: FB, fontSize: 14.5, color: C.text,
      lineSpacing: 22, isTextBox: true, margin: 0,
    }
  );

  const smart = [
    ["E", "Específico", "Registro offline, sincronización automática y calificación de leads"],
    ["M", "Medible", "100 % sin red · < 5 min de latencia · 0 retranscripciones"],
    ["A", "Alcanzable", "Servicios administrados y un solo código base"],
    ["R", "Relevante", "Ataca los dos costos reales: reproceso y pérdida de leads"],
    ["T", "Temporal", "8 semanas, con hitos por objetivo específico"],
  ];

  let y = 3.6;
  smart.forEach(([letra, nombre, desc]) => {
    circulo(s, { x: M, y, d: 0.42, texto: letra, size: 14, fill: C.amber });
    s.addText(nombre, {
      x: M + 0.62, y: y + 0.02, w: 2.0, h: 0.32,
      fontFace: FB, fontSize: 13.5, bold: true, color: C.dark,
      isTextBox: true, margin: 0,
    });
    s.addText(desc, {
      x: M + 2.7, y: y + 0.03, w: 9.3, h: 0.32,
      fontFace: FB, fontSize: 13, color: C.muted,
      isTextBox: true, margin: 0,
    });
    y += 0.6;
  });

  s.addNotes("Cada letra del criterio SMART se cumple con un elemento verificable del objetivo.");
}

/* ================================================================== */
/* 5. Objetivos específicos                                            */
/* ================================================================== */
{
  const s = slideClara();
  titulo(s, "Objetivos específicos", "Estructura metodológica móvil de tres pasos, en 8 semanas");

  const pasos = [
    ["1", "Investigación y prototipado UX/UI", "Semanas 1-3",
      "Levantar el flujo real del asesor en campo, definir el modelo de datos de la visita y diseñar los prototipos navegables de las cuatro pantallas críticas, evaluando usabilidad con uso a una sola mano y en exteriores."],
    ["2", "Frontend móvil e integración backend", "Semanas 4-6",
      "Programar el cliente en Flutter con Clean Architecture y SQLite, implementar el motor de sincronización con patron Outbox e idempotencia, y consumir la API REST en Cloud Functions con JWT, superando el 90 % de cobertura del dominio."],
    ["3", "Pruebas en dispositivos y medición", "Semanas 7-8",
      "Probar en Android e iOS reales bajo tres escenarios de red, midiendo tiempo de registro, latencia de sincronización, consumo de batería y usabilidad SUS, y contrastar con la línea base del proceso manual."],
  ];

  pasos.forEach(([n, tit, plazo, desc], i) => {
    const x = M + i * 4.09;
    tarjeta(s, { x, y: 1.85, w: 3.85, h: 4.15 });
    circulo(s, { x: x + 0.32, y: 2.15, d: 0.55, texto: n, size: 18 });
    s.addText(plazo.toUpperCase(), {
      x: x + 0.32, y: 2.85, w: 3.2, h: 0.25,
      fontFace: FB, fontSize: 10, bold: true, color: C.amber,
      charSpacing: 1.5, isTextBox: true, margin: 0,
    });
    s.addText(tit, {
      x: x + 0.32, y: 3.1, w: 3.2, h: 0.75,
      fontFace: FH, fontSize: 17, bold: true, color: C.dark,
      lineSpacing: 22, isTextBox: true, margin: 0,
    });
    s.addText(desc, {
      x: x + 0.32, y: 3.95, w: 3.2, h: 1.85,
      fontFace: FB, fontSize: 11.5, color: C.muted,
      lineSpacing: 16, isTextBox: true, margin: 0,
    });
  });

  s.addNotes("Los tres pasos corresponden a los sprints del proyecto y cada uno cierra con un incremento instalable.");
}

/* ================================================================== */
/* 6. La solución                                                      */
/* ================================================================== */
{
  const s = slideClara();
  titulo(s, "La solución", "La red deja de ser un requisito y pasa a ser un recurso opcional");

  const caps = [
    ["A", "Catálogo sin señal", "Réplica local con sincronización delta por marca de tiempo"],
    ["B", "Visita completa en campo", "Checklist, interés, presupuesto y geolocalización sobre SQLite"],
    ["C", "Calificación automática", "Modelo de 6 factores, 0 a 100, frío / tibio / caliente"],
    ["D", "Cero pérdida de datos", "Outbox transaccional y reintentos con retroceso exponencial"],
    ["E", "Conflictos resueltos", "Revisión monótona y detección explícita de escrituras concurrentes"],
    ["F", "Aviso inmediato", "Disparador de Firestore que notifica al coordinador por push"],
  ];

  caps.forEach(([l, tit, desc], i) => {
    const col = i % 3;
    const fila = Math.floor(i / 3);
    const x = M + col * 4.09;
    const y = 1.9 + fila * 2.15;
    tarjeta(s, { x, y, w: 3.85, h: 1.9, fill: fila === 0 ? C.white : C.tealSoft, borde: fila === 0 ? C.line : C.tealSoft });
    circulo(s, { x: x + 0.3, y: y + 0.28, d: 0.44, texto: l, size: 14, fill: fila === 0 ? C.teal : C.dark });
    s.addText(tit, {
      x: x + 0.85, y: y + 0.31, w: 2.8, h: 0.4,
      fontFace: FB, fontSize: 14, bold: true, color: C.dark,
      isTextBox: true, margin: 0,
    });
    s.addText(desc, {
      x: x + 0.3, y: y + 0.82, w: 3.3, h: 0.85,
      fontFace: FB, fontSize: 11.5, color: C.muted,
      lineSpacing: 15, isTextBox: true, margin: 0,
    });
  });

  s.addNotes("Seis capacidades, cada una respaldada por un mecanismo tecnico concreto del repositorio.");
}

/* ================================================================== */
/* 7. Arquitectura                                                     */
/* ================================================================== */
{
  const s = slideClara();
  titulo(s, "Arquitectura en la nube", "Tres capas, backend serverless, sin servidores que administrar");

  // --- Dispositivo
  tarjeta(s, { x: M, y: 1.8, w: 3.6, h: 4.3, fill: C.tealSoft, borde: C.tealSoft });
  s.addText("DISPOSITIVO  ·  FLUTTER", {
    x: M + 0.25, y: 1.98, w: 3.1, h: 0.3,
    fontFace: FB, fontSize: 10, bold: true, color: C.teal,
    charSpacing: 1.2, isTextBox: true, margin: 0,
  });
  const capasApp = [
    ["Presentación", "Widgets + Riverpod"],
    ["Dominio", "Entidades, scoring, sync"],
    ["Datos", "Repositorios y data sources"],
    ["SQLite", "Fuente de verdad local"],
    ["Outbox", "Cola de operaciones"],
    ["Secure Storage", "Tokens cifrados"],
  ];
  capasApp.forEach(([t, d], i) => {
    const y = 2.35 + i * 0.62;
    s.addShape(pres.ShapeType.roundRect, {
      x: M + 0.25, y, w: 3.1, h: 0.52, rectRadius: 0.07,
      fill: { color: C.white }, line: { color: C.line, width: 1 },
    });
    s.addText(t, {
      x: M + 0.4, y: y + 0.03, w: 2.9, h: 0.24,
      fontFace: FB, fontSize: 11.5, bold: true, color: C.dark,
      isTextBox: true, margin: 0,
    });
    s.addText(d, {
      x: M + 0.4, y: y + 0.26, w: 2.9, h: 0.23,
      fontFace: FB, fontSize: 9.5, color: C.muted,
      isTextBox: true, margin: 0,
    });
  });

  // --- Conector
  s.addShape(pres.ShapeType.rightArrow, {
    x: 4.45, y: 3.55, w: 0.85, h: 0.42,
    fill: { color: C.amber }, line: { width: 0 },
  });
  s.addText("HTTPS · TLS 1.2+ · Bearer JWT", {
    x: 4.05, y: 4.05, w: 1.75, h: 0.5,
    fontFace: FB, fontSize: 9, color: C.muted, align: "center",
    lineSpacing: 12, isTextBox: true, margin: 0,
  });

  // --- Nube
  tarjeta(s, { x: 5.9, y: 1.8, w: 6.73, h: 4.3, fill: C.white, borde: C.line });
  s.addText("GOOGLE CLOUD  ·  FIREBASE  ·  us-central1", {
    x: 6.15, y: 1.98, w: 6.2, h: 0.3,
    fontFace: FB, fontSize: 10, bold: true, color: C.teal,
    charSpacing: 1.2, isTextBox: true, margin: 0,
  });

  const servicios = [
    ["Authentication", "JWT + custom claims de rol"],
    ["Cloud Functions v2", "API REST /v1/sync/pull · push"],
    ["Cloud Firestore", "inmuebles · visitas · operaciones"],
    ["Cloud Storage", "Fotos y firmas de la visita"],
    ["Trigger + Scheduler", "Notificación y métricas diarias"],
    ["Cloud Messaging", "Push al coordinador"],
  ];
  servicios.forEach(([t, d], i) => {
    const col = i % 2;
    const fila = Math.floor(i / 2);
    const x = 6.15 + col * 3.16;
    const y = 2.42 + fila * 1.18;
    s.addShape(pres.ShapeType.roundRect, {
      x, y, w: 3.0, h: 1.0, rectRadius: 0.07,
      fill: { color: C.tealSoft }, line: { color: C.tealSoft, width: 1 },
    });
    s.addText(t, {
      x: x + 0.18, y: y + 0.15, w: 2.7, h: 0.3,
      fontFace: FB, fontSize: 12, bold: true, color: C.dark,
      isTextBox: true, margin: 0,
    });
    s.addText(d, {
      x: x + 0.18, y: y + 0.48, w: 2.7, h: 0.42,
      fontFace: FB, fontSize: 10, color: C.muted,
      lineSpacing: 13, isTextBox: true, margin: 0,
    });
  });

  pie(s, "El dispositivo nunca espera a la red: lee y escribe siempre en SQLite. La nube se reconcilia después.");
  s.addNotes("El punto clave: la interfaz jamas depende de la red. La sincronización ocurre en segundo plano.");
}

/* ================================================================== */
/* 8. Motor de sincronización                                          */
/* ================================================================== */
{
  const s = slideClara();
  titulo(s, "El motor de sincronización", "Cuatro problemas distintos, cuatro mecanismos distintos");

  const mecanismos = [
    ["Outbox transaccional", "El proceso muere entre guardar y enviar",
      "El dato y su operación pendiente se escriben en la MISMA transacción SQLite"],
    ["Idempotencia por UUID", "Un reintento duplica la visita",
      "El operacionId lo genera el dispositivo; el servidor lo registra y no reprocesa"],
    ["Cursor delta", "Traer todo el catálogo agota datos y batería",
      "Solo viajan los registros con updatedAt posterior al último cursor confirmado"],
    ["Revisión + LWW con conflicto", "Dos dispositivos editan el mismo registro",
      "Contador monótono; si ambas copias cambiaron se marca conflicto, no se sobrescribe"],
  ];

  mecanismos.forEach(([tit, problema, sol], i) => {
    const y = 1.85 + i * 1.13;
    tarjeta(s, { x: M, y, w: W - 2 * M, h: 1.0, fill: i % 2 === 0 ? C.white : C.tealSoft, borde: i % 2 === 0 ? C.line : C.tealSoft });
    circulo(s, { x: M + 0.28, y: y + 0.27, d: 0.46, texto: String(i + 1), size: 15, fill: C.teal });
    s.addText(tit, {
      x: M + 0.92, y: y + 0.18, w: 3.5, h: 0.3,
      fontFace: FB, fontSize: 14, bold: true, color: C.dark,
      isTextBox: true, margin: 0,
    });
    s.addText(problema, {
      x: M + 0.92, y: y + 0.52, w: 3.5, h: 0.32,
      fontFace: FB, fontSize: 10.5, italic: true, color: C.amber,
      isTextBox: true, margin: 0,
    });
    s.addText(sol, {
      x: M + 4.7, y: y + 0.3, w: 7.0, h: 0.5,
      fontFace: FB, fontSize: 12, color: C.muted,
      lineSpacing: 15, isTextBox: true, margin: 0,
    });
  });

  s.addText("Reintentos: 5 s → 10 s → 20 s → 40 s ... tope 15 min, con jitter de ±20 % para no saturar el backend cuando decenas de dispositivos recuperan cobertura a la vez.", {
    x: M, y: 6.4, w: W - 2 * M, h: 0.4,
    fontFace: FB, fontSize: 11.5, color: C.text,
    isTextBox: true, margin: 0,
  });

  s.addNotes("Este es el nucleo tecnico del proyecto y el que concentra la mayor parte de las pruebas automatizadas.");
}

/* ================================================================== */
/* 9. Modelo de calificación de leads                                  */
/* ================================================================== */
{
  const s = slideClara();
  titulo(s, "Calificación automática del lead", "Modelo explicable de seis factores, replicado en cliente y servidor");

  s.addChart(
    pres.ChartType.bar,
    [{
      name: "Peso maximo",
      labels: ["Nivel de interés", "Capacidad de compra", "Crédito preaprobado", "Duración de visita", "Checklist completo", "Evidencia registrada"],
      values: [30, 25, 15, 10, 10, 10],
    }],
    {
      x: M, y: 1.85, w: 7.0, h: 4.0,
      barDir: "bar",
      chartColors: [C.teal],
      showTitle: true,
      title: "Peso de cada factor sobre 100 puntos",
      titleFontSize: 13,
      titleColor: C.dark,
      titleFontFace: FB,
      showValue: true,
      dataLabelPosition: "outEnd",
      dataLabelColor: C.text,
      dataLabelFontSize: 11,
      dataLabelFontFace: FB,
      showLegend: false,
      catAxisLabelColor: C.text,
      catAxisLabelFontSize: 11,
      catAxisLabelFontFace: FB,
      valAxisLabelColor: C.muted,
      valAxisLabelFontSize: 10,
      valAxisMaxVal: 35,
      valGridLine: { color: "EDF3F2", size: 1 },
      catGridLine: { style: "none" },
      barGapWidthPct: 45,
    }
  );

  const rangos = [
    ["Caliente", "70 a 100", "Contacto inmediato del coordinador", "C2410C"],
    ["Tibio", "45 a 69", "Seguimiento en las siguientes 48 horas", C.amber],
    ["Frío", "0 a 44", "Queda en campaña de nutrición", "2563EB"],
  ];

  s.addText("Clasificación comercial", {
    x: 8.1, y: 1.9, w: 4.5, h: 0.3,
    fontFace: FB, fontSize: 14, bold: true, color: C.dark,
    isTextBox: true, margin: 0,
  });

  rangos.forEach(([nombre, rango, accion, color], i) => {
    const y = 2.35 + i * 1.05;
    tarjeta(s, { x: 8.1, y, w: 4.53, h: 0.92 });
    s.addShape(pres.ShapeType.ellipse, {
      x: 8.32, y: y + 0.3, w: 0.3, h: 0.3,
      fill: { color }, line: { width: 0 },
    });
    s.addText(nombre, {
      x: 8.72, y: y + 0.14, w: 1.7, h: 0.3,
      fontFace: FB, fontSize: 13.5, bold: true, color: C.dark,
      isTextBox: true, margin: 0,
    });
    s.addText(rango + " puntos", {
      x: 8.72, y: y + 0.45, w: 1.9, h: 0.28,
      fontFace: FB, fontSize: 10.5, color: C.muted,
      isTextBox: true, margin: 0,
    });
    s.addText(accion, {
      x: 10.5, y: y + 0.24, w: 1.95, h: 0.5,
      fontFace: FB, fontSize: 10.5, color: C.muted,
      lineSpacing: 13, isTextBox: true, margin: 0,
    });
  });

  s.addText("El servidor recalcula el puntaje e ignora el que envía el dispositivo: hay pruebas que lo verifican.", {
    x: 8.1, y: 5.55, w: 4.53, h: 0.6,
    fontFace: FB, fontSize: 11, italic: true, color: C.teal,
    lineSpacing: 15, isTextBox: true, margin: 0,
  });

  s.addNotes("El modelo es auditable: la app muestra el desglose por factor mientras el asesor llena el formulario.");
}

/* ================================================================== */
/* 10. Seguridad                                                       */
/* ================================================================== */
{
  const s = slideOscura();

  s.addText("Seguridad por capas", {
    x: M, y: 0.6, w: 11.9, h: 0.7,
    fontFace: FH, fontSize: 32, bold: true, color: C.white,
    isTextBox: true, margin: 0,
  });
  s.addText("Toda entrada del dispositivo se considera hostil", {
    x: M, y: 1.3, w: 11.9, h: 0.35,
    fontFace: FB, fontSize: 14, color: "9FBDB7",
    isTextBox: true, margin: 0,
  });

  const capas = [
    ["Dispositivo", ["Tokens en Keychain / EncryptedSharedPreferences", "Sin secretos compilados: todo por --dart-define", "Base local sin documentos ni datos financieros"]],
    ["Transporte", ["HTTPS obligatorio con TLS 1.2 o superior", "Authorization: Bearer con JWT de una hora", "Renovación transparente 5 min antes del vencimiento"]],
    ["Nube", ["verifyIdToken con comprobación de revocación", "Rol como custom claim firmado, no como campo del cuerpo", "Reglas de Firestore y Storage: denegar por defecto"]],
  ];

  capas.forEach(([tit, items], i) => {
    const x = M + i * 4.09;
    s.addShape(pres.ShapeType.roundRect, {
      x, y: 2.0, w: 3.85, h: 3.6, rectRadius: 0.09,
      fill: { color: C.darker }, line: { color: "1E5049", width: 1 },
    });
    circulo(s, { x: x + 0.3, y: 2.3, d: 0.46, texto: String(i + 1), size: 15, fill: C.amber, color: C.darker });
    s.addText(tit, {
      x: x + 0.88, y: 2.36, w: 2.8, h: 0.35,
      fontFace: FH, fontSize: 18, bold: true, color: C.white,
      isTextBox: true, margin: 0,
    });
    s.addText(
      items.map((t, k) => ({ text: t, options: { bullet: true, breakLine: k < items.length - 1 } })),
      {
        x: x + 0.3, y: 3.0, w: 3.25, h: 2.4,
        fontFace: FB, fontSize: 11.5, color: "C9DEDA", valign: "top",
        paraSpaceAfter: 9, lineSpacing: 15, isTextBox: true, margin: 0,
      }
    );
  });

  s.addText("El servidor ignora deliberadamente asesorUid, scoreLead y revision enviados por el cliente: los recalcula.", {
    x: M, y: 5.95, w: 11.9, h: 0.4,
    fontFace: FB, fontSize: 12, italic: true, color: C.amber,
    isTextBox: true, margin: 0,
  });

  s.addNotes("El modelo de amenazas STRIDE completo esta en docs/05-seguridad.md.");
}

/* ================================================================== */
/* 11. Calidad e ingeniería                                            */
/* ================================================================== */
{
  const s = slideClara();
  titulo(s, "Calidad de ingeniería", "La arquitectura se diseñó para poder probarse");

  const stats = [
    ["32", "pruebas automatizadas\nen el backend"],
    ["96 %", "cobertura de la\nlógica de dominio"],
    ["9", "suites entre cliente\ny servidor"],
    ["0", "errores de tipo en\nmodo estricto"],
  ];

  stats.forEach(([v, l], i) => {
    const x = M + i * 3.06;
    tarjeta(s, { x, y: 1.85, w: 2.85, h: 1.6, fill: C.tealSoft, borde: C.tealSoft });
    s.addText(v, {
      x: x + 0.25, y: 1.98, w: 2.4, h: 0.7,
      fontFace: FH, fontSize: 38, bold: true, color: C.teal,
      isTextBox: true, margin: 0,
    });
    s.addText(l, {
      x: x + 0.25, y: 2.68, w: 2.4, h: 0.65,
      fontFace: FB, fontSize: 11, color: C.text,
      lineSpacing: 14, isTextBox: true, margin: 0,
    });
  });

  const practicas = [
    ["Clean Architecture por feature", "El dominio no conoce Flutter, SQLite ni HTTP"],
    ["Inversión de dependencias", "El motor depende de la interfaz SyncApi, no del cliente HTTP"],
    ["SQLite real en las pruebas", "sqflite_common_ffi ejecuta la base en memoria, sin emulador"],
    ["Integración continua", "tsc, jest, flutter analyze y flutter test en cada push"],
    ["Paridad cliente/servidor verificada", "El mismo modelo de scoring en Dart y TypeScript, con pruebas espejo"],
    ["Configuración fuera del código", "Ningún secreto versionado; .gitignore cubre credenciales"],
  ];

  practicas.forEach(([tit, desc], i) => {
    const col = i % 2;
    const fila = Math.floor(i / 2);
    const x = M + col * 6.13;
    const y = 3.75 + fila * 0.88;
    circulo(s, { x, y: y + 0.05, d: 0.36, texto: "✓", size: 13 });
    s.addText(tit, {
      x: x + 0.52, y, w: 5.4, h: 0.28,
      fontFace: FB, fontSize: 12.5, bold: true, color: C.dark,
      isTextBox: true, margin: 0,
    });
    s.addText(desc, {
      x: x + 0.52, y: y + 0.27, w: 5.4, h: 0.28,
      fontFace: FB, fontSize: 10.5, color: C.muted,
      isTextBox: true, margin: 0,
    });
  });

  pie(s, "Resultado real de npm test sobre este repositorio: 4 suites, 32 pruebas, 96,21 % de sentencias cubiertas.");
  s.addNotes("La cobertura se mide sobre src/dominio, que es donde vive la lógica de negocio del backend.");
}

/* ================================================================== */
/* 12. Costos                                                          */
/* ================================================================== */
{
  const s = slideClara();
  titulo(s, "Costos de operación", "Escenario de 10 asesores y 1 320 visitas mensuales");

  const filas = [
    ["Google Play Console", "Google", "Pago único de por vida", "$25,00"],
    ["Apple Developer Program", "Apple", "Suscripción anual", "$99,00"],
    ["Firebase: Firestore, Functions, Storage", "Google Cloud", "Estimado mensual", "$15,00"],
    ["Cloud Messaging (push)", "Google", "Mensual", "$0,00"],
  ];

  s.addTable(
    [
      [
        { text: "Concepto / servicio móvil", options: { bold: true, color: C.white, fill: { color: C.dark } } },
        { text: "Proveedor", options: { bold: true, color: C.white, fill: { color: C.dark } } },
        { text: "Frecuencia", options: { bold: true, color: C.white, fill: { color: C.dark } } },
        { text: "Costo USD", options: { bold: true, color: C.white, fill: { color: C.dark }, align: "right" } },
      ],
      ...filas.map((f, i) => [
        { text: f[0], options: { fill: { color: i % 2 ? C.tealSoft : C.white } } },
        { text: f[1], options: { fill: { color: i % 2 ? C.tealSoft : C.white } } },
        { text: f[2], options: { fill: { color: i % 2 ? C.tealSoft : C.white } } },
        { text: f[3], options: { fill: { color: i % 2 ? C.tealSoft : C.white }, align: "right", bold: true } },
      ]),
    ],
    {
      x: M, y: 1.9, w: 7.6,
      colW: [3.3, 1.5, 1.7, 1.1],
      rowH: 0.42,
      fontFace: FB, fontSize: 11.5, color: C.text,
      border: { type: "solid", color: C.line, pt: 1 },
      valign: "middle",
    }
  );

  tarjeta(s, { x: M, y: 4.35, w: 7.6, h: 1.0, fill: C.amberSoft, borde: C.amberSoft });
  s.addText("Costo total estimado del proyecto", {
    x: M + 0.3, y: 4.6, w: 4.6, h: 0.4,
    fontFace: FB, fontSize: 14, bold: true, color: C.dark,
    isTextBox: true, margin: 0,
  });
  s.addText("$139,00 USD", {
    x: M + 4.9, y: 4.52, w: 2.5, h: 0.6,
    fontFace: FH, fontSize: 26, bold: true, color: C.amber,
    align: "right", isTextBox: true, margin: 0,
  });

  s.addChart(
    pres.ChartType.doughnut,
    [{
      name: "Presupuesto",
      labels: ["Comprometido", "Disponible"],
      values: [139, 161],
    }],
    {
      x: 8.55, y: 1.9, w: 4.1, h: 3.5,
      chartColors: [C.teal, C.tealSoft],
      holeSize: 62,
      showTitle: true,
      title: "Presupuesto asignado: 300 USD",
      titleFontSize: 12,
      titleFontFace: FB,
      titleColor: C.dark,
      showLegend: true,
      legendPos: "b",
      legendFontSize: 11,
      legendColor: C.text,
      showValue: true,
      dataLabelColor: C.white,
      dataLabelFontSize: 11,
      dataLabelFontFace: FB,
    }
  );

  s.addText("53,7 % de eficiencia presupuestal", {
    x: 8.55, y: 5.45, w: 4.1, h: 0.35,
    fontFace: FB, fontSize: 13, bold: true, color: C.teal,
    align: "center", isTextBox: true, margin: 0,
  });

  pie(s, "El costo crece con el número de operaciones, no con el de usuarios: por eso la sincronización delta es también un control de gasto.");
  s.addNotes("A este volumen el consumo cabe en la capa gratuita; los 15 USD son margen de seguridad, no costo calculado.");
}

/* ================================================================== */
/* 13. Antes y después                                                 */
/* ================================================================== */
{
  const s = slideClara();
  titulo(s, "Resultado esperado", "Metas medibles frente a la línea base del proceso manual");

  const comparacion = [
    ["Tiempo de registro por visita", "~6 min", "<= 3 min"],
    ["Retranscripciones al CRM", "1 por visita", "0"],
    ["Latencia hasta el lead visible", "Horas o día siguiente", "< 5 min"],
    ["Operaciones perdidas", "Sin control", "0"],
    ["Criterio de priorización", "Subjetivo", "Puntaje 0-100 auditable"],
  ];

  s.addText("PROCESO MANUAL", {
    x: 5.15, y: 1.85, w: 3.4, h: 0.3,
    fontFace: FB, fontSize: 10.5, bold: true, color: C.muted,
    charSpacing: 1.2, align: "center", isTextBox: true, margin: 0,
  });
  s.addText("CON INMOVISITA", {
    x: 8.95, y: 1.85, w: 3.65, h: 0.3,
    fontFace: FB, fontSize: 10.5, bold: true, color: C.teal,
    charSpacing: 1.2, align: "center", isTextBox: true, margin: 0,
  });

  comparacion.forEach(([metrica, antes, después], i) => {
    const y = 2.3 + i * 0.82;
    s.addText(metrica, {
      x: M, y: y + 0.15, w: 4.3, h: 0.35,
      fontFace: FB, fontSize: 13, bold: true, color: C.dark,
      isTextBox: true, margin: 0,
    });
    s.addShape(pres.ShapeType.roundRect, {
      x: 5.15, y, w: 3.4, h: 0.65, rectRadius: 0.08,
      fill: { color: "F3F5F5" }, line: { color: "F3F5F5", width: 1 },
    });
    s.addText(antes, {
      x: 5.15, y, w: 3.4, h: 0.65,
      fontFace: FB, fontSize: 12.5, color: C.muted,
      align: "center", valign: "middle", isTextBox: true, margin: 0,
    });
    s.addShape(pres.ShapeType.roundRect, {
      x: 8.95, y, w: 3.65, h: 0.65, rectRadius: 0.08,
      fill: { color: C.tealSoft }, line: { color: C.tealSoft, width: 1 },
    });
    s.addText(después, {
      x: 8.95, y, w: 3.65, h: 0.65,
      fontFace: FB, fontSize: 12.5, bold: true, color: C.teal,
      align: "center", valign: "middle", isTextBox: true, margin: 0,
    });
  });

  pie(s, "La línea base se levanta con cronometraje directo durante la primera semana, antes de introducir la aplicación.");
  s.addNotes("El contraste se validara con prueba t pareada y tamano del efecto, segun el protocolo de docs/07.");
}

/* ================================================================== */
/* 14. Proyeccion investigativa                                        */
/* ================================================================== */
{
  const s = slideOscura();

  s.addShape(pres.ShapeType.ellipse, {
    x: W - 3.0, y: -1.2, w: 4.6, h: 4.6,
    fill: { color: C.teal, transparency: 76 }, line: { width: 0 },
  });

  s.addText("PROYECCIÓN INVESTIGATIVA", {
    x: M, y: 0.9, w: 8, h: 0.35,
    fontFace: FB, fontSize: 12, bold: true, color: C.amber,
    charSpacing: 2, isTextBox: true, margin: 0,
  });
  s.addText("Qué hace este proyecto transferible", {
    x: M, y: 1.35, w: 9.5, h: 0.7,
    fontFace: FH, fontSize: 32, bold: true, color: C.white,
    isTextBox: true, margin: 0,
  });

  const lineas = [
    ["Modelo de scoring calibrable", "Contrastar el puntaje contra el desenlace real del lead y recalibrar los pesos por regresión logística: de heurística a modelo predictivo validado."],
    ["Reconciliación sin pérdida silenciosa", "La detección explícita de conflictos es generalizable a cualquier sistema de captura distribuida; el siguiente paso son estructuras CRDT."],
    ["Instrumento de medición replicable", "El protocolo de tres escenarios de red y cuatro métricas sirve para salud rural, inspección agrícola, censos o mantenimiento de infraestructura."],
  ];

  lineas.forEach(([tit, desc], i) => {
    const y = 2.35 + i * 1.25;
    circulo(s, { x: M, y: y + 0.05, d: 0.5, texto: String(i + 1), size: 16, fill: C.amber, color: C.darker });
    s.addText(tit, {
      x: M + 0.72, y, w: 10.5, h: 0.35,
      fontFace: FB, fontSize: 16, bold: true, color: C.white,
      isTextBox: true, margin: 0,
    });
    s.addText(desc, {
      x: M + 0.72, y: y + 0.38, w: 10.5, h: 0.7,
      fontFace: FB, fontSize: 12.5, color: "9FBDB7",
      lineSpacing: 17, isTextBox: true, margin: 0,
    });
  });

  s.addShape(pres.ShapeType.roundRect, {
    x: M, y: 6.25, w: 11.9, h: 0.62, rectRadius: 0.1,
    fill: { color: C.darker }, line: { color: "1E5049", width: 1 },
  });
  s.addText("Código, documentación técnica y esta presentación:  github.com/sgrlrichterl/inmovisita", {
    x: M, y: 6.25, w: 11.9, h: 0.62,
    fontFace: FB, fontSize: 13, bold: true, color: C.white,
    align: "center", valign: "middle", isTextBox: true, margin: 0,
  });

  s.addNotes("Cierre: el proyecto no termina en la entrega; las tres lineas son continuaciones concretas para el semillero.");
}

pres.writeFile({ fileName: "InmoVisita-Presentacion.pptx" }).then((f) => {
  console.log("Generado:", f);
});
