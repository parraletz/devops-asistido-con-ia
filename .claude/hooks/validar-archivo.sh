#!/usr/bin/env bash
# Hook PostToolUse (Edit|Write): valida cada archivo que Claude acaba de escribir.
# Si el linter falla, sale con código 2: el error vuelve a Claude y lo corrige
# en el mismo turno, sin que una persona tenga que copiar y pegar el error.
set -euo pipefail

archivo=$(jq -r '.tool_input.file_path // ""')
[[ -n "$archivo" && -f "$archivo" ]] || exit 0

# Los archivos "antes" de las demos tienen errores a propósito.
[[ "$archivo" == *.antes* ]] && exit 0

correr() {
  local salida
  if ! salida=$("$@" 2>&1); then
    printf 'El archivo %s no pasa la validación:\n%s\nCorrígelo antes de continuar.\n' "$archivo" "$salida" >&2
    exit 2
  fi
}

# shellcheck disable=SC2016  # $1 se expande dentro del sh -c, a propósito
case "$archivo" in
  *Dockerfile*)
    if command -v hadolint >/dev/null; then correr hadolint "$archivo"
    else correr sh -c 'docker run --rm -i hadolint/hadolint:v2.12.0 < "$1"' _ "$archivo"; fi ;;
  *.sh)
    correr shellcheck "$archivo" ;;
  *.tf)
    correr terraform fmt -check -diff "$archivo"
    correr sh -c 'cd "$(dirname "$1")" && terraform validate -no-color' _ "$archivo" ;;
  */kubernetes/*.yaml|*/k8s/*.yaml|*/manifests/*.yaml)
    if command -v kubeconform >/dev/null; then correr kubeconform -strict "$archivo"
    else correr sh -c 'docker run --rm -i ghcr.io/yannh/kubeconform:v0.6.7 -strict - < "$1"' _ "$archivo"; fi ;;
esac

exit 0
