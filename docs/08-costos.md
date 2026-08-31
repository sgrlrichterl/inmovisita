# 8. Simulador de costos de infraestructura y publicación

## 8.1 Escenario base

| Parámetro | Valor |
|---|---|
| Asesores activos | 10 |
| Visitas por asesor por día | 6 |
| Días hábiles al mes | 22 |
| **Visitas mensuales** | **1 320** |
| Ciclos de sincronización por asesor por día | ≈ 12 (periódicos + por recuperación de red) |
| Fotos por visita | 3 (≈ 400 KB cada una tras compresión) |
| Presupuesto asignado | 300 USD |

## 8.2 Costos de publicación en tiendas

| Concepto | Proveedor | Frecuencia | USD |
|---|---|---|---:|
| Google Play Console | Google | Pago único de por vida | 25,00 |
| Apple Developer Program | Apple | Suscripción anual | 99,00 |
| **Subtotal primer año** | | | **124,00** |

A partir del segundo año el costo de tiendas baja a 99,00 USD anuales, porque la cuenta de Google Play ya no se vuelve a pagar.

## 8.3 Costos de nube (Firebase, plan Blaze)

Cálculo sobre el volumen del escenario base, descontando la capa gratuita mensual que Firebase mantiene incluso en el plan Blaze.

| Servicio | Uso mensual estimado | Capa gratuita | Excedente | USD |
|---|---|---|---|---:|
| **Firestore — escrituras** | ≈ 4 000 (1 320 visitas × 2 documentos + metadatos) | 20 000/día | 0 | 0,00 |
| **Firestore — lecturas** | ≈ 60 000 (pull delta + tableros) | 50 000/día | 0 | 0,00 |
| **Firestore — almacenamiento** | ≈ 0,4 GB | 1 GB | 0 | 0,00 |
| **Cloud Functions — invocaciones** | ≈ 32 000 (2 640 sincronizaciones + disparadores) | 2 M/mes | 0 | 0,00 |
| **Cloud Functions — cómputo** | ≈ 1,2 GB-s ×10³ | 400 000 GB-s | 0 | 0,00 |
| **Cloud Storage — almacenamiento** | ≈ 1,6 GB/mes acumulativo | 5 GB | 0 | ~0,50 |
| **Cloud Storage — descargas** | ≈ 2 GB | 1 GB/día | 0 | 0,00 |
| **Cloud Messaging** | ≈ 400 notificaciones | Ilimitado | 0 | 0,00 |
| **Egreso de red y sobrecostos** | Variable | — | — | ~14,50 |
| **Subtotal mensual (estimación conservadora)** | | | | **15,00** |

> **Lectura honesta de la tabla:** al volumen de 10 asesores, el consumo cabe holgadamente en la capa gratuita de Firebase. Los 15 USD mensuales que se presupuestan son un **margen de seguridad** frente a picos, a la carga de fotografías y al egreso de red, no un costo derivado del cálculo. Presupuestar el consumo real (≈ 0,50 USD) sería técnicamente correcto pero operativamente imprudente.

## 8.4 Total del proyecto

| Concepto | Proveedor | Frecuencia | USD |
|---|---|---|---:|
| Google Play Console | Google | Pago único | 25,00 |
| Apple Developer Program | Apple | Anual | 99,00 |
| Backend Firebase (Firestore, Functions, Storage) | Google Cloud | Mensual estimado | 15,00 |
| Cloud Messaging | Google | Mensual | 0,00 |
| **Costo total estimado del proyecto** | | | **139,00** |
| Presupuesto asignado | | | 300,00 |
| **Eficiencia presupuestal** | | | **53,7 % libre** |

## 8.5 Proyección de crecimiento

| Escenario | Asesores | Visitas/mes | Nube USD/mes | Observación |
|---|---:|---:|---:|---|
| Piloto | 10 | 1 320 | ~15 | Dentro de la capa gratuita |
| Agencia mediana | 50 | 6 600 | ~35 | Empieza a facturar Firestore y Storage |
| Red de agencias | 200 | 26 400 | ~120 | Conviene revisar el TTL de `operaciones_sync` y comprimir fotos en el dispositivo |

El costo **no crece linealmente con los usuarios** sino con el número de operaciones y de documentos leídos. Por eso la sincronización delta y el envío por lotes no son solo una mejora de rendimiento: son la principal palanca de control de costo del sistema.

## 8.6 Controles de gasto implementados

| Control | Dónde | Efecto |
|---|---|---|
| `maxInstances: 10` | `functions/src/index.ts` | Techo de concurrencia: un pico no dispara la factura |
| `memory: "256MiB"`, `timeoutSeconds: 60` | ídem | Menor costo por GB-segundo y corte de ejecuciones colgadas |
| Sincronización delta por cursor | `sync_service.ts` | Se leen solo los documentos modificados |
| Envío por lotes (hasta 500 operaciones) | `SyncRemoteDataSource.push` | Una invocación en lugar de N |
| Retroceso exponencial con jitter | `RetryPolicy` | Los reintentos no multiplican las invocaciones |
| Corte tras 5 intentos | ídem | Una operación irrecuperable deja de costar |
| Índices compuestos declarados | `firestore.indexes.json` | Evita consultas costosas sin índice |
| Alerta de presupuesto en Cloud Billing | Configuración manual | Aviso antes de superar el umbral |

## 8.7 Costo no monetario

El costo de infraestructura no es el único relevante. El proyecto también consume:

- **Datos móviles del asesor:** un ciclo de sincronización sin fotos transfiere unos pocos KB gracias al delta; con tres fotos comprimidas, alrededor de 1,2 MB. Una jornada completa se mantiene por debajo de 10 MB.
- **Batería:** el ciclo periódico de 120 s es configurable; en escenarios de baja actividad puede ampliarse a 300 s sin afectar la meta de latencia, que se cumple por el disparo al recuperar conectividad.
