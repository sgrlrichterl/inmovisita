# Presentación del proyecto

| Archivo | Uso |
|---|---|
| `InmoVisita-Presentacion.pdf` | Versión para lectura y entrega |
| `InmoVisita-Presentacion.pptx` | Versión editable (PowerPoint / Keynote / Google Slides) |
| `build_deck.js` | Script que genera las diapositivas de forma reproducible |

## Contenido (14 diapositivas)

1. Portada
2. El problema — proceso actual y su costo
3. Pregunta problema y metas medibles
4. Objetivo general bajo criterio SMART
5. Objetivos específicos — los tres pasos metodológicos
6. La solución — seis capacidades
7. Arquitectura en la nube
8. El motor de sincronización — cuatro mecanismos
9. Modelo de calificación de leads
10. Seguridad por capas
11. Calidad de ingeniería — pruebas y CI
12. Costos de operación y presupuesto
13. Resultado esperado — línea base vs. metas
14. Proyección investigativa

## Regenerar las diapositivas

```bash
cd presentacion
node build_deck.js                     # produce el .pptx
soffice --headless --convert-to pdf InmoVisita-Presentacion.pptx
```

Requiere `pptxgenjs` (`npm install pptxgenjs`) y LibreOffice para la exportación a PDF.
Las notas del orador están incluidas en cada diapositiva del `.pptx`.
