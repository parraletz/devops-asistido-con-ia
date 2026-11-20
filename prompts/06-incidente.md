# Demo 6 · Monitoreo y resolución de incidentes

**Archivos:** `demos/05-incidente/logs/catalogo-api.log`, `metricas.csv`, `postmortem-plantilla.md`

## Triage desde la terminal (headless, con pipes)
```bash
cd demos/05-incidente
# 1. Filtrar primero con herramientas deterministas: solo warn/error
jq -c 'select(.level!="info")' <(cut -d' ' -f2- logs/catalogo-api.log) | head -20

# 2. Pasarle a la IA SOLO lo relevante (menos ruido, menos datos sensibles)
{ grep -E '"level":"(warn|error)"|deploy|feature_flag' logs/catalogo-api.log; echo; cat metricas.csv; } \
  | claude -p "Eres SRE de guardia. Con estos logs y métricas: línea de tiempo, hipótesis de causa raíz
               con la línea de evidencia de cada una y qué dato falta para confirmarla." --max-turns 1
```

## Prompt 1: triage (sesión interactiva)
```
Eres SRE de guardia. Analiza demos/05-incidente/logs/catalogo-api.log y
demos/05-incidente/metricas.csv.
1. Línea de tiempo resumida (UTC) con los eventos clave.
2. Hipótesis de causa raíz ordenadas por probabilidad, cada una con la EVIDENCIA
   (línea del log o fila de métricas) que la soporta.
3. Qué dato adicional pedirías para confirmar o descartar cada hipótesis.
No afirmes nada que no esté en la evidencia; si es inferencia, márcalo como tal.
```

## Prompt 2: mitigación (propuesta, no ejecución)
```
Propón 3 acciones de mitigación inmediata ordenadas por riesgo (menor a mayor),
con el comando exacto y cómo revertirlo. NO ejecutes nada.
```

## Prompt 3: postmortem
```
Llena demos/05-incidente/postmortem-plantilla.md con lo que sabemos.
Formato blameless. Marca con [VERIFICAR] todo lo que no esté respaldado por los logs/métricas.
Propón acciones correctivas de tipo prevenir, detectar y mitigar.
```

## Respuestas esperadas (para el instructor)
- **Gatillo:** deploy 1.4.0 a las 14:58 + feature flag `recs_cache` con `ttl: none` y `max_entries: unbounded` (14:59).
- **Mecanismo:** cache sin límite → heap crece → event loop lag → timeouts 503 → OOMKilled (exit 137) en ambos pods → 0 endpoints listos.
- **Detección tardía:** la alerta llegó a las 15:25, ~14 min después del primer `heap alto` (15:11). Acción: alerta por memoria/heap, no solo por tasa de errores.
- **Mitigación:** apagar el flag (15:34) + rollout restart (15:35). Resuelto 15:41.
- **Trampa para el chat:** ¿la IA dijo "fue un memory leak en el código de recomendaciones"? Los logs muestran un cache sin límite; "leak en el código" es una inferencia. Ese es el `[VERIFICAR]`.
