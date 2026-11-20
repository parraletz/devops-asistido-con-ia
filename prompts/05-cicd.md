# Demo 5 · CI/CD con IA

**Archivos:** `.github/workflows/ci.yml` y `.github/workflows/ai-pr-review.yml`

## Prompt 1: generar el pipeline
```
Genera un workflow de GitHub Actions para este repo que en cada PR:
- instale dependencias con npm ci en app/ y corra typecheck y tests (Node 22, con caché)
- valide app/Dockerfile con hadolint, demos/02-bash/backup.sh con shellcheck
  y demos/03-terraform con fmt + validate (sin backend)
- construya la imagen y haga un smoke test contra /health/live
Requisitos: permissions mínimos (contents: read), concurrency para cancelar
ejecuciones viejas y versiones fijas de las acciones.
```

## Prompt 2: auditar el pipeline (otra conversación, otro "par de ojos")
```
Audita este workflow de GitHub Actions como si fueras del equipo de seguridad:
permisos del GITHUB_TOKEN, acciones de terceros, secretos, pull_request_target,
inyección de expresiones ${{ }} en run:. Lista riesgos concretos con la línea.
```

## Modo headless: la IA como un paso más del pipeline
`claude -p` corre sin interfaz: recibe stdin, responde por stdout y se puede encadenar con pipes, igual que `jq` o `grep`.
```bash
# Revisar solo el diff del PR, salida estructurada
git diff origin/main...HEAD -- app/ demos/ .github/ \
  | claude -p "Revisa este diff con el skill devops-estandares. Responde SOLO JSON:
      {\"hallazgos\":[{\"archivo\":\"\",\"linea\":0,\"severidad\":\"alta|media|baja\",\"detalle\":\"\"}]}" \
      --output-format json --max-turns 3 \
  | jq -r '.result' | jq '.hallazgos[] | select(.severidad=="alta")'

# Explicar un terraform plan antes de aprobarlo
terraform -chdir=demos/03-terraform plan -no-color \
  | claude -p "Resume este plan en 5 líneas. Señala cualquier destroy o replacement." --max-turns 1
```
Lo mismo corre dentro de GitHub Actions: es lo que hace `anthropics/claude-code-action` por debajo.

## Demo en vivo del review con IA
1. Crear rama y meter un cambio "malo":
   ```bash
   git switch -c demo/cambio-riesgoso
   cp demos/01-dockerfile/Dockerfile.antes app/Dockerfile
   git commit -am "chore: simplificar Dockerfile" && git push -u origin HEAD
   gh pr create --fill
   ```
2. Ver cómo `ai-pr-review` comenta (secreto horneado, `latest`, root…).
3. Ver cómo `ci` falla en hadolint: **la IA opina, el pipeline decide, la persona aprueba.**

**Puntos a remarcar:**
- El job de IA solo tiene `pull-requests: write` para comentar; no puede hacer push ni merge.
- Fijar acciones por SHA (no solo por tag) para mitigar ataques a la cadena de suministro.
- Nunca usar `pull_request_target` + checkout del código del PR con secretos.
- En CI la revisión la hace **Qwen** (`qwen3.8-max`) a través de un endpoint compatible con Anthropic: mismo harness (Claude Code), otro modelo. Se configura con `ANTHROPIC_BASE_URL` + secreto `QWEN_API_KEY` en `ai-pr-review.yml`. Tarda ~4-5 min y ~11 turnos; respaldo: PR #1.
