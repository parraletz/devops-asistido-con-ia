# Demo 9 · Crear en vivo un monitor de workflows

Se construye **en la sesión de Claude Code, frente al chat**. No hay nada preparado en el repo: el monitor nace de un prompt.

## Prompt
```
Crea un monitor que me diga cómo se está comportando mi workflow y analicemos oportunidades de mejora.
```

## Si la IA no lo encamina sola, guíala con restricciones
```
Hazlo como un script scripts/ci-monitor.sh que use gh y jq (sin IA dentro), con métricas
DETERMINISTAS de los últimos N runs de cada workflow activo:
- % de éxito por workflow y por job
- duración p50 / p95 por run y por job
- los 3 pasos más lentos de cada job
- fallos recientes con el job y el paso exacto
Salida en JSON por defecto y --md para una tabla legible. Que pase shellcheck.
Después córrelo contra este repo y muéstrame el resultado.
```
Luego, el análisis:
```bash
scripts/ci-monitor.sh -n 30 | claude -p "Eres ingeniero de plataforma. Con estas métricas reales de GitHub
Actions y los workflows de .github/workflows/, dame las 5 mejores oportunidades de mejora priorizadas por
impacto/esfuerzo, con la evidencia (métrica o archivo:línea), el cambio propuesto y el riesgo. No inventes métricas." --max-turns 6
```
Con el Docker MCP Gateway activo (demo 0), la IA también puede consultar PRs y commits con `github-official`.

## Qué observar en vivo
- **El hook PostToolUse** corre shellcheck sobre el script que escribe la IA: si algo falla, lo corrige sola (demo 8 en acción).
- **Datos antes que opiniones:** la IA analiza números que calculó un script revisable, no los inventa.
- **Una persona elige** una mejora y la pide en un PR, que pasa por el mismo CI y la misma revisión con IA.

## Hallazgos reales en este repo (19 nov 2026)
Para el instructor, por si la IA no los encuentra:
| Hallazgo | Evidencia | Mejora |
|---|---|---|
| La imagen se construye dos veces en `main` | job `image` (docker build ~13 s) y `publish` (build multiarch ~41 s) | Reutilizar caché o fusionar build + smoke test |
| Commits de solo docs disparan todo el CI y publican imagen | `publish` corrió en commits que solo cambiaron `.md` | `paths-ignore: ['**.md', 'prompts/**']` en `push` |
| El job de IA es el más lento y caro | `review` p50 ~190 s | ¿Correrlo en cada `synchronize` o solo al abrir / bajo demanda? |
| `lint-infra` falla en PRs | 80 % de éxito: los fallos son del PR de demostración (esperados) | Separar ramas `demo/*` en el análisis |
