#!/usr/bin/env bash
# Crea el profile "curso-devops" del Docker MCP Gateway con tres servidores del
# catálogo oficial (hub.docker.com/mcp): terraform, kubernetes y github-official.
#
# Requiere Docker Desktop con MCP Toolkit (4.59+) o el plugin docker-mcp.
# Uso: scripts/mcp-setup.sh [ruta_kubeconfig]
#   ruta_kubeconfig: kubeconfig que verá el servidor de Kubernetes (default: ~/.kube/config).
#   Recomendado: uno de un ServiceAccount de SOLO LECTURA, no el de admin.
set -euo pipefail

readonly PERFIL="curso-devops"
readonly CATALOGO="mcp/docker-mcp-catalog"
readonly KUBECONFIG_MCP="${1:-$HOME/.kube/config}"

if ! docker mcp version >/dev/null 2>&1; then
  echo "Falta 'docker mcp': actualiza Docker Desktop (4.59+) y activa MCP Toolkit." >&2
  exit 1
fi
[[ -r "$KUBECONFIG_MCP" ]] || { echo "No puedo leer el kubeconfig: $KUBECONFIG_MCP" >&2; exit 1; }

echo "== catálogo oficial"
docker mcp catalog pull "$CATALOGO"

echo "== profile $PERFIL"
docker mcp profile create --name "$PERFIL" \
  --server "catalog://$CATALOGO/terraform" \
  --server "catalog://$CATALOGO/kubernetes" \
  --server "catalog://$CATALOGO/github-official"

echo "== kubeconfig para el servidor de kubernetes"
docker mcp profile config "$PERFIL" --set "kubernetes.config_path=$KUBECONFIG_MCP"

# Primera capa de guardrails: herramientas peligrosas apagadas en el gateway.
# La IA ni siquiera las ve. (.claude/settings.json las niega también: segunda capa.)
echo "== herramientas deshabilitadas"
docker mcp profile tools "$PERFIL" \
  --disable kubernetes.kubectl_delete \
  --disable kubernetes.kubectl_generic \
  --disable kubernetes.exec_in_pod \
  --disable kubernetes.node_management \
  --disable kubernetes.cleanup \
  --disable kubernetes.install_helm_chart \
  --disable kubernetes.upgrade_helm_chart \
  --disable kubernetes.uninstall_helm_chart \
  --disable github-official.merge_pull_request \
  --disable github-official.delete_file \
  --disable github-official.push_files \
  --disable github-official.create_repository \
  --disable github-official.fork_repository

cat <<'EOF'

Listo. Falta autorizar GitHub (OAuth) una sola vez:
  docker mcp oauth --help        # o Docker Desktop → MCP Toolkit → github-official → OAuth

Verificar:
  docker mcp profile show curso-devops
  docker mcp tools ls
  claude   →  /mcp   (servidor "docker-mcp" conectado)
EOF
