---
name: devops-estandares
description: Estándares DevOps del equipo para crear o revisar Dockerfiles, scripts de shell, Terraform, manifiestos de Kubernetes y workflows de GitHub Actions. Úsalo siempre que se cree, modifique o revise cualquiera de esos archivos, o cuando pidan "revisar infraestructura", "preparar para producción" o "validar antes del PR".
---

# Estándares DevOps del equipo

Estas reglas salen de revisar y corregir nuestros propios archivos (ver `demos/` y `app/`).
Aplícalas al **crear** y al **revisar**. Si una regla no aplica, dilo y explica por qué; no la ignores en silencio.

## Forma de trabajar

1. **Diagnostica antes de reescribir.** En una revisión, entrega primero una tabla: `archivo:línea | problema | severidad (alta/media/baja) | arreglo`. Reescribe solo si te lo piden.
2. **No inventes.** Si no estás seguro de un flag, un argumento de un recurso o una versión, dilo y propón cómo verificarlo. Para versiones de providers o módulos de Terraform, consulta el registro (MCP de Terraform si está disponible).
3. **Valida siempre** con `scripts/validar.sh` (en esta carpeta del skill) antes de dar algo por terminado, y reporta la salida tal cual.
4. **Nada destructivo sin una persona.** No ejecutes `terraform apply`, `kubectl apply/delete`, `docker system prune`, `rm -rf` ni `git push --force`. Propón el comando y cómo revertirlo.
5. **Secretos fuera.** Nunca escribas credenciales en código, imágenes, logs ni prompts. Si encuentras uno, márcalo como severidad alta e indica que hay que **rotarlo**, no solo borrarlo.

## Dockerfile
- Imagen base con versión fija (`node:22.12-alpine3.21`), nunca `latest`.
- Multi-stage: dependencias de desarrollo solo en el stage de build. `npm ci`, no `npm install`.
- Copia primero los manifiestos (`package*.json`) y después el código, para aprovechar la caché.
- `USER` no root, `HEALTHCHECK`, `CMD` en formato JSON.
- Sin secretos en `ENV`/`ARG`. `.dockerignore` presente.
- Validación: `hadolint`.

## Scripts de shell
- `#!/usr/bin/env bash` + `set -euo pipefail`.
- Valida número y formato de argumentos; falla con un mensaje claro.
- Todas las variables entre comillas. Nunca `rm -rf $VAR/*` sin validar que `$VAR` no esté vacía.
- No parsear `ls`; usa globs o `find`.
- Secretos desde archivo o variable de entorno (`--passphrase-file`), nunca literales.
- Logs con timestamp a stderr.
- Validación: `shellcheck` sin avisos.

## Terraform
- `required_version` y providers con restricción de versión (`~>`).
- Variables con `description`, `type` y `validation` cuando haya rangos.
- Antes de cambiar la dirección de un recurso (`count`, `for_each`, renombrar), agrega un bloque `moved {}`.
- Flujo obligatorio: `fmt -check` → `validate` → `plan -out=tfplan`. **Lee el plan**: cualquier `destroy` o `forces replacement` se reporta explícitamente.
- Nunca `apply -auto-approve` fuera de un pipeline aprobado.

## Kubernetes
- Tag de imagen fijo, nunca `latest`.
- `requests` y `limits` de memoria; aclara que los valores deben ajustarse con métricas reales.
- `livenessProbe` y `readinessProbe` contra los endpoints de salud.
- `securityContext`: `runAsNonRoot`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: ["ALL"]`, `seccompProfile: RuntimeDefault`.
- Al menos 2 réplicas con `maxUnavailable: 0` para servicios con tráfico.
- Validación: `kubeconform -strict`; con cluster, `kubectl apply --dry-run=server` y `kubectl diff`.

## GitHub Actions
- `permissions` mínimos a nivel workflow (`contents: read`) y solo lo extra que cada job necesite.
- Acciones de terceros fijadas por **SHA** con el tag en comentario (`@<sha> # v7.0.1`).
- `concurrency` para cancelar ejecuciones viejas.
- Nunca `pull_request_target` con checkout del código del PR y secretos.
- No interpolar `${{ github.event.* }}` directamente dentro de `run:`; pásalo por `env:`.
- Un job de IA solo comenta: sin `contents: write`, sin aprobar ni hacer merge.

## Formato de entrega
Al terminar, responde con:
1. Qué cambiaste (lista corta, archivo por archivo).
2. Salida de `scripts/validar.sh`.
3. Qué debe revisar una persona antes del merge (valores supuestos, riesgos, `[VERIFICAR]`).
