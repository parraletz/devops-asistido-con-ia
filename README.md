# DevOps asistido con IA

Material del curso en vivo de **Código Facilito · Semana del Aprendizaje**
📅 25 de noviembre de 2026 · 11:00–13:00 (UTC-6) · YouTube

> La IA propone y acelera; la persona valida, decide y es responsable.

## Qué hay aquí

| Ruta | Contenido |
|---|---|
| `app/` | API de ejemplo (TypeScript + Hono) con tests (Vitest) y Dockerfile "después" |
| `demos/01-dockerfile/` | Dockerfile "antes" con problemas sembrados |
| `demos/02-bash/` | Script de respaldo "antes" y "después" |
| `demos/03-terraform/` | IaC con el provider de Docker (corre local, sin nube) |
| `demos/04-kubernetes/` | Deployment "antes" y "después" endurecido |
| `demos/05-incidente/` | Logs, métricas y plantilla de postmortem de un incidente simulado |
| `.github/workflows/ci.yml` | CI: tests, hadolint, shellcheck, terraform validate, build + smoke test |
| `.github/workflows/ai-pr-review.yml` | Revisión de PR con IA (solo comenta, no aprueba) |
| `scripts/mcp-setup.sh` | Crea el profile `curso-devops` del Docker MCP Gateway (terraform, kubernetes, github-official) |
| `AGENTS.md` | Contexto del proyecto para cualquier agente (Claude Code, Copilot, Cursor, Codex…): stack, comandos y reglas |
| `.mcp.json` | Docker MCP Gateway con el profile `curso-devops` ([catálogo MCP de Docker](https://hub.docker.com/mcp)) |
| `.mcp.terraform-directo.json` | Alternativa sin Docker MCP Toolkit: solo el servidor de Terraform en un contenedor |
| `.claude/settings.json` | Permisos allow / ask / deny (comandos y herramientas MCP) y registro de hooks |
| `.claude/hooks/` | Guardrails: bloquear producción y `apply` sin plan; validar cada archivo que escribe la IA |
| `.claude/skills/devops-estandares/` | Skill de Claude con los estándares del equipo + `validar.sh` (también lo usa el CI) |
| `prompts/` | Los prompts exactos de cada demo + cómo validarlos |
## Requisitos

- Node.js 20+ y npm
- Docker (o un runtime compatible con Compose). Para los servidores MCP: Docker Desktop 4.59+ con **MCP Toolkit** y luego `scripts/mcp-setup.sh`
- Terraform 1.6+
- Opcional: `shellcheck`, `kubectl` + kind/minikube, `gh`
- [Claude Code](https://claude.com/claude-code)

## Imagen multi-arquitectura

En cada push a `main`, después de pasar tests, linters y smoke test, el job `publish` de `ci.yml` publica `ghcr.io/parraletz/catalogo-api` para **linux/amd64 y linux/arm64** con provenance y SBOM. Tags: versión de `app/package.json` (`1.0.0`), `sha-<commit>` y `latest`.

```bash
# local, igual que en CI (sin QEMU: el build corre en la arquitectura nativa)
docker buildx build --platform linux/amd64,linux/arm64 -t catalogo-api:multi app
docker buildx imagetools inspect ghcr.io/parraletz/catalogo-api:1.0.0
```

## Revisión de PR con Qwen (solo en CI)

`ai-pr-review.yml` corre Claude Code dentro de GitHub Actions con un modelo **Qwen** a través de un endpoint compatible con la API de Anthropic (`ANTHROPIC_BASE_URL`). El harness es el mismo; solo cambia el modelo que razona. Requiere el secreto `QWEN_API_KEY` en el repositorio:

```bash
gh secret set QWEN_API_KEY < ~/.secrets/qwencloud-api-key
```

## Arranque rápido

```bash
# App local
cd app && npm ci && npm test && npm run dev
curl localhost:3000/productos

# Con contenedores
docker compose up --build
curl localhost:3000/health/ready

# Con Terraform (provider Docker)
cd demos/03-terraform
terraform init && terraform plan -out=tfplan && terraform apply tfplan
curl "$(terraform output -raw url)"
terraform destroy
```

## Variables de entorno

| Variable | Uso | Default |
|---|---|---|
| `PORT` | Puerto de la API | `3000` |
| `APP_VERSION` | Versión reportada en `/health/ready` | `dev` |
| `BACKUP_ROOT` | Destino de `backup.sh` | `/backups` |
| `BACKUP_PASSPHRASE_FILE` | Archivo con la frase de cifrado de `backup.sh` | — (obligatoria) |
| `RETENCION_DIAS` | Retención de respaldos | `7` |
| `QWEN_API_KEY` | Secreto del repo para `ai-pr-review.yml` | — |
| `AI_REVIEW_MODEL` | Variable del repo: modelo de la revisión (`qwen3.8-max` más profundo, `qwen3.8-flash` ~3× más rápido) | `qwen3.8-max` |

Nunca subas secretos al repositorio. `demos/01-dockerfile/Dockerfile.antes` y `demos/02-bash/backup.antes.sh` contienen secretos **falsos** a propósito para la demo.
