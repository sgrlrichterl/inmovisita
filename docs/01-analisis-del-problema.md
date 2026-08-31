# 1. Análisis del problema y justificación tecnológica

## 1.1 Contexto

El sector inmobiliario colombiano opera con un modelo de trabajo eminentemente **de campo**. El asesor no vive frente a un computador: se desplaza entre inmuebles, muchos de ellos en corregimientos, parcelaciones, conjuntos en construcción, sótanos y bodegas industriales, donde la señal de datos es intermitente, lenta o nula.

Las herramientas de gestión de la agencia (CRM, fichas del inmueble, formularios de visita) son aplicaciones web pensadas para escritorio y para conexión permanente. En el punto exacto donde se genera el dato más valioso del negocio —la reacción del cliente frente al inmueble— la herramienta no está disponible.

Aunque la conectividad rural ha mejorado de forma sostenida (32,2 % de hogares en 2022 → **56,9 % en 2025**), sigue 17 puntos por debajo del promedio nacional de 73,9 %, y el propio Ministerio TIC reconoce que el reto ya no es solo el acceso sino "lograr que la conectividad se traduzca en uso productivo" (MinTIC, 2026). Un software que asume red permanente deja fuera precisamente al trabajador móvil.

## 1.2 Delimitación del problema

**Unidad de análisis:** el ciclo de captura de una visita inmobiliaria, desde que el asesor termina de mostrar el inmueble hasta que el coordinador comercial dispone del lead calificado.

**Proceso actual observado:**

| # | Actividad | Herramienta | Momento | Problema que introduce |
|---|---|---|---|---|
| 1 | El asesor muestra el inmueble | — | En sitio | — |
| 2 | Anota interés, presupuesto y observaciones | Papel / notas del teléfono | En sitio | Formato libre, campos omitidos |
| 3 | Toma fotos de hallazgos | Galería del teléfono | En sitio | Evidencia sin vincular a la visita |
| 4 | Envía un resumen por mensajería | WhatsApp | Al recuperar señal | Información dispersa, sin trazabilidad |
| 5 | Retranscribe todo al CRM | Web, en la oficina | Al final del día | **Doble digitación**, pérdida de detalle |
| 6 | El coordinador prioriza el lead | CRM | Día siguiente | La ventana de contacto ya se enfrió |

**Problemas concretos, en orden de impacto:**

1. **Doble digitación.** El mismo dato se captura dos veces (papel y CRM). Además del tiempo consumido, cada retranscripción es una oportunidad de error y de omisión.
2. **Latencia del lead.** Entre el cierre de la visita y la visibilidad del lead para el coordinador transcurren horas o un día completo. En un mercado donde el cliente visita varias agencias el mismo fin de semana, esa demora cuesta oportunidades.
3. **Calificación subjetiva y no comparable.** No existe un criterio uniforme para decidir qué lead es prioritario; depende del juicio y del recuerdo del asesor.
4. **Evidencia no trazable.** Fotos y comentarios viven en chats personales, fuera de cualquier sistema auditable.
5. **Bloqueo por falta de red.** Si la herramienta no carga, el proceso se detiene: no hay degradación elegante, hay interrupción.

**Fuera del alcance de esta entrega:** contabilidad y comisiones, firma electrónica con validez legal, portales públicos de publicación, e integración con pasarelas de pago.

## 1.3 Pregunta problema

> ¿De qué manera el diseño de una aplicación móvil multiplataforma en Flutter, con arquitectura *offline-first* y un backend serverless en Firebase, permite eliminar la doble digitación y reducir a menos de 5 minutos el tiempo entre el cierre de una visita inmobiliaria y la disponibilidad del lead calificado para el coordinador, en zonas con conectividad intermitente?

## 1.4 Objetivos

### Objetivo general (SMART)

**Desarrollar y desplegar**, en un plazo de 8 semanas, una **aplicación móvil multiplataforma en Flutter con arquitectura offline-first y backend serverless en Firebase** que permita registrar el 100 % de una visita inmobiliaria sin conexión y **sincronizar automáticamente el lead calificado en menos de 5 minutos** desde que el dispositivo recupera cobertura, eliminando la retranscripción manual en el CRM.

| Criterio | Cómo se cumple |
|---|---|
| **E**specífico | Registro de visitas offline + sincronización automática + calificación de leads |
| **M**edible | 100 % del formulario disponible sin red; < 5 min de latencia tras recuperar señal; 0 retranscripciones |
| **A**lcanzable | Servicios administrados (Firebase) y un solo código base (Flutter); alcance acotado a un flujo |
| **R**elevante | Ataca la doble digitación y la pérdida de leads, los dos costos reales del proceso actual |
| **T**emporal | 8 semanas, con hitos por objetivo específico |

### Objetivos específicos (estructura metodológica de 3 pasos)

**Paso 1 — Investigación de usuario y prototipado UX/UI (semanas 1 a 3).**
Levantar el flujo real de trabajo del asesor en campo, definir el modelo de datos de la visita y diseñar los prototipos navegables de las cuatro pantallas críticas (autenticación, catálogo, registro de visita y panel de sincronización), evaluando la usabilidad bajo la restricción de uso a una sola mano y con guantes o bajo el sol.

**Paso 2 — Desarrollo del frontend móvil e integración con el backend (semanas 4 a 6).**
Implementar la aplicación en Flutter con Clean Architecture, persistencia SQLite, motor de sincronización con patrón Outbox, y consumir la API REST desplegada en Cloud Functions con autenticación JWT de Firebase, alcanzando cobertura de pruebas automatizadas sobre el 90 % de la lógica de dominio.

**Paso 3 — Pruebas en dispositivos reales y medición de desempeño (semanas 7 y 8).**
Ejecutar pruebas en dispositivos Android e iOS reales bajo tres escenarios de red (sin señal, señal intermitente y 4G estable), midiendo el tiempo de registro por visita, la latencia de sincronización, el consumo de batería y la usabilidad percibida mediante la escala SUS, y contrastar los resultados con la línea base del proceso manual.

## 1.5 Justificación tecnológica

La elección no se hizo por popularidad sino contra tres restricciones del problema: **(a)** la aplicación debe funcionar sin red, **(b)** el tráfico es intermitente y en ráfagas, y **(c)** el equipo que la mantendrá es pequeño.

| Decisión | Justificación frente al problema | Alternativa evaluada y por qué se descartó |
|---|---|---|
| **Flutter** como framework de cliente | Un solo código base para Android e iOS; acceso a SQLite nativo mediante `sqflite`, indispensable para el modo offline; compilación AOT que mantiene fluidez en gama media, que es el parque real de dispositivos de los asesores | **Nativo duplicado (Kotlin + Swift):** el mejor rendimiento no compensa duplicar el costo de desarrollo y mantenimiento del motor de sincronización, que es la parte más delicada. **React Native:** viable, pero el puente con SQLite y la ausencia de tipado estricto por defecto añaden riesgo en la capa crítica |
| **SQLite como fuente de verdad local** | Permite consultas relacionales, transacciones ACID y, sobre todo, guardar dato y operación pendiente **atómicamente** | **Almacenamiento clave-valor:** no soporta transacciones multi-entidad ni consultas por rango, que la sincronización delta necesita |
| **Cloud Functions v2 (serverless)** | Los asesores sincronizan en ráfagas al recuperar cobertura; se paga por invocación y la capacidad se ajusta sola. `maxInstances` acota el gasto ante un pico | **Servidor o contenedor permanente:** costo fijo mensual para un uso de pocos minutos al día, más la carga de parchear y monitorear el sistema operativo |
| **Cloud Firestore** | Consultas por rango de `updatedAt` (base del cursor delta), transacciones para la idempotencia, reglas de seguridad declarativas y escalado sin intervención | **PostgreSQL administrado:** modelo relacional más expresivo, pero exige gestionar el *pool* de conexiones desde funciones efímeras y no ofrece reglas de acceso por documento |
| **Firebase Authentication** | Tokens JWT firmados, con *custom claims* de rol verificables tanto en la API como en las reglas; API REST que evita archivos de configuración nativos | **Autenticación propia:** reimplementar emisión, rotación y revocación de tokens es una de las principales fuentes de vulnerabilidades en aplicaciones móviles |
| **Cloud Storage + FCM** | La evidencia fotográfica excede el límite de 1 MiB por documento de Firestore; el push es el único canal con latencia de segundos y costo cero | **Imágenes en base64:** rompe el límite del documento. **SMS/correo para avisos:** mayor latencia y costo por mensaje |

## 1.6 Elementos diferenciadores (proyección investigativa)

1. **Modelo de calificación de leads explicable.** El puntaje no es una caja negra: se compone de seis factores con pesos documentados y la aplicación muestra el desglose. Es auditable, ajustable y comparable entre asesores.
2. **Reconciliación con detección explícita de conflictos.** La mayoría de implementaciones offline aplican *last-write-wins* puro, que pierde datos en silencio. Aquí el contador de revisión permite distinguir una actualización legítima de una escritura concurrente real, y esta última se marca en lugar de descartarse.
3. **Paridad de algoritmo cliente/servidor verificada por pruebas.** El mismo modelo de puntaje existe en Dart y en TypeScript; ambas implementaciones tienen suites equivalentes que fijan los mismos valores esperados, y el servidor conserva la autoridad final.
4. **Instrumento de medición replicable.** El protocolo del Paso 3 (tres escenarios de red, cuatro métricas, escala SUS) es transferible a cualquier otro proceso de captura de datos en campo: salud rural, inspección agrícola, censos, mantenimiento de infraestructura.

## Referencias

- Ministerio de Tecnologías de la Información y las Comunicaciones de Colombia. (2026). *Gobierno Petro conectó 3,5 millones de hogares en tres años y, por primera vez, más de la mitad de los hogares rurales tienen internet*. https://www.mintic.gov.co/portal/715/w3-article-437305.html
- Ministerio de Tecnologías de la Información y las Comunicaciones de Colombia. (2025). *Boletín trimestral de las TIC*. https://colombiatic.mintic.gov.co/679/articles-417629_archivo_pdf.pdf
