# catalogo-api · contexto para agentes de IA

Repositorio de demos del curso "DevOps asistido con IA". Responde en español.

## Stack
- App: TypeScript + Hono en `app/` (Node 22). Tests con Vitest.
- Contenedores: `app/Dockerfile` (multi-stage, usuario `node`), `compose.yaml`.
- IaC: Terraform con provider `kreuzwerker/docker` en `demos/03-terraform` (local, sin nube).
- Kubernetes: manifiestos en `demos/04-kubernetes`.
- CI: GitHub Actions en `.github/workflows`.

## Comandos
- Tests: `cd app && npm test` · Tipos: `npm run typecheck`
- Validación completa: `.claude/skills/devops-estandares/scripts/validar.sh`
- Terraform: `terraform fmt -check && terraform validate && terraform plan -out=tfplan`

## Reglas
- Los archivos `*.antes*` tienen errores a propósito: no los corrijas salvo que te lo pidan.
- Para estándares de Dockerfile, scripts, Terraform, K8s y workflows usa el skill `devops-estandares`.
- Nunca ejecutes `apply`, `delete` ni `push` sin confirmación; propón el comando.
