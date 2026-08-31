# 9. Respuestas para el formulario de Canvas

Texto listo para copiar y pegar en el **Ecosistema Interactivo Mobile** del Taller ABP, campo por campo y en el mismo orden en que aparece en las cuatro pestañas del formulario.

> Cada bloque indica si el campo es de **una línea** o de **texto largo**. Los campos de una línea admiten texto extenso, pero se leen mejor con una sola frase; los textos que siguen ya están calibrados para eso.

---

## Pestaña 1 · Identificación y Metodología

### Título Formal del Proyecto Móvil `una línea`

```
InmoVisita: aplicación móvil multiplataforma en Flutter con arquitectura offline-first para el registro y la calificación automática de visitas inmobiliarias en zonas con conectividad intermitente
```

Contiene los tres elementos que pide la ayuda del campo: la solución (registro y calificación de visitas), la tecnología del cliente (Flutter multiplataforma) y el problema del usuario final (conectividad intermitente).

### Integrantes del Equipo `una línea`

```
Sebastián García Riveros
```

*(Si el trabajo es en pareja, separa los nombres completos con un guion o una coma.)*

### Selección de Metodología de Desarrollo Móvil `lista desplegable`

Elige la opción más cercana a **Scrum** (según la lista puede aparecer como *Scrum*, *Scrum Móvil* o *Ágil / Scrum*). Si la lista no ofrece nada equivalente, elige la más próxima y ajusta la primera frase del texto siguiente para que coincida con lo seleccionado.

### Descripción extendida del marco metodológico `texto largo`

```
Scrum adaptado al ciclo de vida móvil, con sprints de dos semanas y una definición de terminado que exige análisis estático sin advertencias, pruebas automatizadas en verde y ejecución verificada en dispositivo real.

El proyecto se organiza en cuatro sprints alineados con los tres pasos metodológicos: descubrimiento y prototipado UX/UI, desarrollo del cliente y de la persistencia local, integración con el backend y motor de sincronización, y pruebas en campo con medición de desempeño. Cada sprint cierra con un incremento instalable en el dispositivo de un asesor, porque en un proyecto offline-first la retroalimentación válida solo se obtiene en la condición real de red.

La integración continua ejecuta verificación de tipos, análisis estático y las suites de pruebas del cliente y del backend en cada push, lo que mantiene la rama principal siempre desplegable.
```

### Enlace al Repositorio (GitHub) y/o Prototipo Figma `una línea`

```
https://github.com/sgrlrichterl/inmovisita
```

*(Reemplaza `USUARIO` por tu nombre de usuario de GitHub.)*

---

## Pestaña 2 · Problema y Pregunta

### Contexto y Diagnóstico del Problema Móvil `texto largo`

```
Los asesores inmobiliarios trabajan en campo —corregimientos, parcelaciones, obra gris, sótanos— donde la señal de datos es intermitente o nula. Las herramientas de la agencia son aplicaciones web que exigen conexión permanente, de modo que en el momento y el lugar donde se genera el dato más valioso del negocio (la reacción del cliente frente al inmueble) la herramienta no está disponible.

El asesor termina anotando la visita en papel o en notas del teléfono, enviando fotos sueltas por mensajería y retranscribiendo todo al CRM al final del día. Esto produce cuatro fallas concretas: doble digitación con pérdida de detalle; latencia de horas o de un día entre el cierre de la visita y la visibilidad del lead para el coordinador; calificación subjetiva y no comparable entre asesores; y evidencia fotográfica dispersa en chats personales, sin trazabilidad.

El contexto lo respalda: la conectividad de los hogares rurales en Colombia pasó del 32,2 % en 2022 al 56,9 % en 2025, aún 17 puntos por debajo del promedio nacional de 73,9 % (MinTIC, 2026). Diseñar asumiendo red permanente excluye justamente al trabajador móvil.
```

### Formulación de la Pregunta Problema `una línea`

```
¿De qué manera una aplicación móvil multiplataforma en Flutter, con arquitectura offline-first y backend serverless en Firebase, permite eliminar la doble digitación y reducir a menos de 5 minutos el tiempo entre el cierre de una visita inmobiliaria y la disponibilidad del lead calificado para el coordinador, en zonas con conectividad intermitente?
```

---

## Pestaña 3 · Objetivos SMART Asistidos

### Objetivo General (SMART) `texto largo`

```
Desarrollar y desplegar, en un plazo de 8 semanas, una aplicación móvil multiplataforma en Flutter con arquitectura offline-first y backend serverless en Firebase que permita registrar el 100 % de una visita inmobiliaria sin conexión y sincronizar automáticamente el lead calificado en menos de 5 minutos desde que el dispositivo recupera cobertura, eliminando la retranscripción manual en el CRM.
```

Cumple la fórmula que pide el campo: verbo (*desarrollar y desplegar*) + tecnología móvil (*Flutter offline-first + Firebase serverless*) + métrica (*100 % sin conexión, menos de 5 minutos*) + plazo (*8 semanas*).

### Paso 1 · Investigación de Usuario y Prototipado UX/UI `una línea`

```
Diseñar los wireframes y el prototipo interactivo de las cuatro pantallas críticas en Figma, evaluando heurísticas de usabilidad para uso a una sola mano y en exteriores, en la semana 3.
```

### Paso 2 · Desarrollo Frontend Móvil e Integración API/Backend `una línea`

```
Programar el cliente en Flutter con Clean Architecture, persistencia SQLite y motor de sincronización con patrón Outbox, e integrar la API REST desplegada en Cloud Functions con autenticación JWT, superando el 90 % de cobertura de pruebas de la lógica de dominio, en la semana 6.
```

### Paso 3 · Pruebas en Dispositivos Reales y Medición de Rendimiento `una línea`

```
Realizar pruebas en dispositivos Android e iOS reales bajo tres escenarios de red, midiendo tiempo de registro por visita, latencia de sincronización, consumo de batería y usabilidad SUS, contrastadas con la línea base del proceso manual, en la semana 8.
```

---

## Pestaña 4 · Arquitectura y Simulador de Costos

### Enfoque Tecnológico Seleccionado `lista desplegable`

Deja la opción que el formulario trae por defecto:

```
Multiplataforma / Cross-Platform (Flutter / React Native)
```

### Simulador de Costos `tabla`

**El formulario ya viene con las tres filas correctas y con el total que corresponde a este proyecto.** Verifica que quede así y no cambies nada más:

| Concepto / Servicio Móvil | Proveedor | Frecuencia / Estimación | Costo USD | Subtotal |
|---|---|---|---:|---:|
| Google Play Console | Google | Pago Único de por vida | 25 | $25,00 |
| Apple Developer Program | Apple | Suscripción Anual | 99 | $99,00 |
| Firebase Base de Datos | Google Cloud | Estimado Mensual | 15 | $15,00 |

- **Costo Total Estimado: $139,00 USD**
- **Presupuesto Asignado: 300 USD**
- **Eficiencia de Presupuesto: 53,7 % libre**

Opcionalmente puedes usar *Agregar Nuevo Servicio/Costo Móvil* para dejar constancia de que también consideraste las notificaciones push, que no tienen costo:

```
Firebase Cloud Messaging (push)  ·  Google  ·  Mensual  ·  0
```

Esa fila no altera el total ni la eficiencia. El desglose completo, con los supuestos de cálculo y la proyección a 50 y 200 asesores, está en [`08-costos.md`](08-costos.md).

### Estrategia de Seguridad en el Dispositivo `texto largo`

```
Los tokens de sesión nunca se guardan en texto plano: se almacenan con flutter_secure_storage, que en Android usa EncryptedSharedPreferences respaldado por el Android Keystore y en iOS el Keychain con accesibilidad first_unlock_this_device, de modo que las credenciales no se restauran en otro dispositivo desde una copia de seguridad.

La autenticación se realiza contra Firebase Identity Platform, que emite un idToken JWT de una hora y un refreshToken de larga duración. El cliente considera el token vencido cinco minutos antes de su expiración real para evitar carreras por desfase de reloj, y lo renueva de forma transparente antes de cada petición. Todo el tráfico viaja por HTTPS con TLS 1.2 o superior y el token se envía en la cabecera Authorization: Bearer.

El rol del usuario (asesor, coordinador o administrador) viaja como custom claim dentro del token firmado por Firebase, no como un campo del cuerpo de la petición, de modo que el cliente no puede escalar privilegios. El servidor verifica el token comprobando revocación, ignora deliberadamente los campos sensibles que envía el dispositivo (asesorUid, scoreLead, revision), valida forma, tipos y rangos de toda la entrada, y recalcula el puntaje del lead. Las reglas de Cloud Firestore y Cloud Storage parten de denegar todo y solo abren la lectura de los documentos propios de cada usuario, actuando como segunda barrera de defensa. La base local no almacena documentos de identidad ni datos financieros, y se limpia por completo al cerrar sesión.
```

---

## Antes de cerrar el formulario

1. Recorre las cuatro pestañas y confirma que ningún campo quedó vacío.
2. Pulsa **Exportar Proyecto a PDF** y guarda el archivo: es tu comprobante de haberlo diligenciado completo.
3. No uses **Resetear Formulario** después de exportar; borraría todo lo escrito.
4. Recuerda que lo que se entrega por el buzón de Canvas es **únicamente el enlace público del repositorio**.

---

## Sobre los botones de asistencia

Los botones verdes junto a cada etiqueta cargan plantillas de ejemplo del docente. Sirven para entender qué espera cada campo, pero no conviene dejarlas como respuesta: la rúbrica penaliza explícitamente las «justificaciones genéricas sin profundizar en el problema». Los textos de este documento están escritos sobre el problema y la solución reales del proyecto.

## Referencia citada

Ministerio de Tecnologías de la Información y las Comunicaciones de Colombia. (2026). *Gobierno conectó 3,5 millones de hogares en tres años y, por primera vez, más de la mitad de los hogares rurales tienen internet*. https://www.mintic.gov.co/portal/715/w3-article-437305.html
