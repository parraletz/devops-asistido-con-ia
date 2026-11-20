# Demo 0 · Preparar el repo para trabajar con IA

Antes de pedirle nada a la IA, le damos **contexto**, **herramientas** y **límites**.
Todo vive en el repo y viaja en git.

```
AGENTS.md                 ← contexto: stack, comandos, reglas (se carga en cada sesión)
.mcp.json                 ← herramientas: Docker MCP Gateway (profile "curso-devops")
.claude/settings.json     ← límites: permisos allow / ask / deny (Bash y herramientas MCP) + hooks
.claude/hooks/            ← guardrails programables (demo 8)
.claude/skills/           ← estándares del equipo (demo 7)
scripts/mcp-setup.sh      ← crea el profile del gateway con servidores del catálogo de Docker
```

## Herramientas: Docker MCP Catalog + Gateway
El [catálogo MCP de Docker](https://hub.docker.com/mcp) tiene 300+ servidores empaquetados como imágenes firmadas.
El **MCP Gateway** los arranca en contenedores aislados bajo demanda y los expone a la IA por un solo punto.

| Servidor del catálogo | Para qué en el curso | Configuración |
|---|---|---|
| `terraform` (HashiCorp) | Versiones reales de providers y módulos | Ninguna |
| `kubernetes` | Consultar el cluster (get, describe, logs) | kubeconfig montado (`kubernetes.config_path`) |
| `github-official` (GitHub) | PRs, commits, issues del repo | OAuth (una vez) |

```bash
# Requiere Docker Desktop 4.59+ con MCP Toolkit
scripts/mcp-setup.sh ~/.kube/config        # crea el profile curso-devops (ideal: kubeconfig de solo lectura)
docker mcp profile show curso-devops
docker mcp tools ls | head
```

`.mcp.json` solo dice "arranca el gateway con este profile":
```json
{ "mcpServers": { "docker-mcp": { "command": "docker",
  "args": ["mcp", "gateway", "run", "--profile", "curso-devops"] } } }
```
Sin Docker MCP Toolkit: `claude --mcp-config .mcp.terraform-directo.json` (solo el servidor de Terraform en un contenedor).

## En vivo
```bash
git clone https://github.com/parraletz/devops-asistido-con-ia && cd devops-asistido-con-ia
cat AGENTS.md
claude
> /mcp                         # "docker-mcp" conectado, con las herramientas de los 3 servidores
> /permissions                 # allow / ask / deny, incluidas las herramientas MCP
> ¿Qué hay en este repo y cómo corro los tests?
```

## Probar el MCP: versiones reales, no inventadas
```
Usando el MCP de Terraform, dime la última versión del provider
kreuzwerker/docker y si demos/03-terraform/main.tf tiene la restricción correcta.
```
**Respuesta esperada (verificada el 18 nov 2026):** el MCP devuelve `4.7.0`, pero `main.tf` restringe a `~> 3.0`, una versión mayor atrás. Momento para remarcar: **no subas la versión porque la IA lo dijo**. Un cambio de versión mayor puede romper cosas, así que se lee el changelog, se corre `terraform init -upgrade` y se revisa el `plan`.

Otras preguntas para mostrar los tres servidores juntos:
```
¿Qué pods corren en el namespace curso-demo y qué imagen usan?          (kubernetes)
¿Qué PRs abiertos hay en este repo y qué dijo la revisión con IA?       (github-official)
```

Versión headless, para que el chat vea las llamadas a herramientas:
```bash
claude -p "Usando el MCP de Terraform, dime la última versión del provider kreuzwerker/docker. Solo el número." \
  --allowedTools "mcp__docker-mcp__get_latest_provider_version" --max-turns 4 --output-format json \
  | jq -c '.[] | select(.type=="assistant") | .message.content[] | select(.type=="tool_use") | {tool: .name, input}'
```

Comparar: preguntar lo mismo **sin** MCP (`claude --strict-mcp-config`): la versión suele ser vieja o inventada.

**Puntos a remarcar:**
- `AGENTS.md` es el onboarding de la IA: lo que le explicarías a un nuevo integrante del equipo. Es un estándar abierto: lo leen Claude Code, GitHub Copilot, Cursor, Codex y otros. Claude Code lo carga cuando no hay `CLAUDE.md` (compruébalo con `/memory`).
- **Los servidores MCP son dependencias**: imágenes del catálogo firmadas por Docker, con SBOM, fijadas por digest, cada una en su contenedor (1 CPU / 2 GB, sin acceso al disco salvo lo que montas). El gateway bloquea secretos en llamadas y respuestas (`--block-secrets`, activo por defecto).
- **Dos capas de guardrails para MCP:** el profile apaga herramientas peligrosas (`kubectl_delete`, `exec_in_pod`, `merge_pull_request`…) y `.claude/settings.json` las niega otra vez. Los hooks de `Bash` no ven las llamadas MCP: por eso los permisos por herramienta importan.
- El servidor de Kubernetes usa **el kubeconfig que le montes**: con uno de admin, la IA tiene admin. Para la clase, un ServiceAccount de solo lectura.
