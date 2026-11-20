#!/usr/bin/env bash
# Hook PreToolUse (Bash): bloquea comandos que tocan producción.
# Claude Code envía el evento como JSON por stdin. Salir con código 2 BLOQUEA
# la herramienta y el mensaje de stderr le llega a Claude como explicación.
set -euo pipefail

comando=$(jq -r '.tool_input.command // ""')

# 1. kubectl/helm contra un contexto de producción
if grep -Eq '(^|[;&| ])(kubectl|helm)[[:space:]]' <<<"$comando"; then
  contexto=$(grep -Eo -- '--context[= ][^ ]+' <<<"$comando" | sed -E 's/--context[= ]//' || true)
  [[ -n "$contexto" ]] || contexto=$(kubectl config current-context 2>/dev/null || echo "")
  if [[ "$contexto" == *prod* ]]; then
    echo "BLOQUEADO: el contexto de Kubernetes es de producción ($contexto). Propón el comando y que lo ejecute una persona." >&2
    exit 2
  fi
fi

# 2. terraform apply sin un plan guardado y revisado
if grep -Eq '(^|[;&| ])terraform[[:space:]]+apply' <<<"$comando" && ! grep -Eq 'apply[[:space:]]+[^-][^ ]*plan' <<<"$comando"; then
  echo "BLOQUEADO: terraform apply solo con un plan guardado (terraform plan -out=tfplan && terraform apply tfplan)." >&2
  exit 2
fi

# 3. Credenciales con un valor LITERAL en la línea de comandos (VAR=sk-...).
#    No bloquea referencias (VAR=$OTRA), placeholders (VAR=...) ni texto entre comillas.
if grep -Eq '(AWS_SECRET_ACCESS_KEY|ANTHROPIC_API_KEY|ANTHROPIC_AUTH_TOKEN|QWEN_API_KEY|GITHUB_TOKEN)=[^[:space:]$.<"'"'"'{]' <<<"$comando"; then
  echo "BLOQUEADO: no pongas credenciales en la línea de comandos; usa el gestor de secretos o variables ya exportadas." >&2
  exit 2
fi

exit 0
