#!/usr/bin/env bash
# Valida Dockerfiles, scripts, Terraform y manifiestos de K8s del repositorio.
# Uso: .claude/skills/devops-estandares/scripts/validar.sh [raiz_del_repo]
# Herramientas: usa la local si existe; si no, la corre en un contenedor.
set -euo pipefail

raiz="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$raiz"

fallos=0
ok()    { printf '  \033[32m✓\033[0m %s\n' "$1"; }
falla() { printf '  \033[31m✗\033[0m %s\n' "$1"; fallos=$((fallos + 1)); }
titulo(){ printf '\n== %s\n' "$1"; }

# Archivos "antes" de las demos tienen errores a propósito: se excluyen.
excluir='(\.antes\.|Dockerfile\.antes|/node_modules/|/\.terraform/)'

titulo "Dockerfiles (hadolint)"
while IFS= read -r f; do
  # Se decide por el código de salida; stderr (p. ej. el "docker pull") no cuenta como hallazgo.
  if command -v hadolint >/dev/null; then cmd=(hadolint -)
  else cmd=(docker run --rm -i hadolint/hadolint:v2.12.0); fi
  if salida=$("${cmd[@]}" < "$f" 2>/dev/null); then ok "$f"; else falla "$f"; printf '%s\n' "$salida" | sed 's/^/      /'; fi
done < <(git ls-files '*Dockerfile*' | grep -Ev "$excluir" || true)

titulo "Scripts de shell (shellcheck)"
while IFS= read -r f; do
  if command -v shellcheck >/dev/null; then cmd=(shellcheck "$f")
  else cmd=(docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:v0.10.0 "$f"); fi
  if salida=$("${cmd[@]}" 2>&1); then ok "$f"; else falla "$f"; printf '%s\n' "$salida" | sed 's/^/      /'; fi
done < <(git ls-files '*.sh' | grep -Ev "$excluir" || true)

titulo "Terraform (fmt + validate)"
while IFS= read -r d; do
  if (cd "$d" && terraform fmt -check -recursive >/dev/null && terraform init -backend=false -input=false >/dev/null && terraform validate -no-color >/dev/null); then
    ok "$d"
  else
    falla "$d (corre: cd $d && terraform fmt -check && terraform validate)"
  fi
done < <(git ls-files '*.tf' | xargs -r -n1 dirname | sort -u)

titulo "Kubernetes (kubeconform)"
while IFS= read -r f; do
  if command -v kubeconform >/dev/null; then cmd=(kubeconform -strict -summary -)
  else cmd=(docker run --rm -i ghcr.io/yannh/kubeconform:v0.6.7 -strict -summary -); fi
  if salida=$("${cmd[@]}" < "$f" 2>/dev/null); then ok "$f"; else falla "$f"; printf '%s\n' "$salida" | sed 's/^/      /'; fi
done < <(git ls-files '*.yaml' '*.yml' | grep -E '(k8s|kubernetes|manifests)/' | grep -Ev "$excluir" || true)

titulo "Secretos evidentes"
patron='(sk-live-|sk-ant-|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|-----BEGIN [A-Z ]*PRIVATE KEY-----)'
if coincidencias=$(git grep -nIE "$patron" -- ':!*.antes*' ':!.claude/' ':!prompts/' 2>/dev/null); then
  falla "posibles secretos:"; printf '%s\n' "$coincidencias" | sed 's/^/      /'
else
  ok "sin patrones de secretos conocidos"
fi

printf '\n'
if (( fallos > 0 )); then echo "Resultado: $fallos verificación(es) con problemas"; exit 1; fi
echo "Resultado: todo en orden"
