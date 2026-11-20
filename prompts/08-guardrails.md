# Demo 8 · Guardrails como código: permisos y hooks

**Archivos:** `.claude/settings.json`, `.claude/hooks/bloquear-produccion.sh`, `.claude/hooks/validar-archivo.sh`

"Supervisión humana" no es una buena intención: se configura, se versiona y se prueba.

## Capa 1: permisos (`.claude/settings.json`)
| Regla | Ejemplos | Efecto |
|---|---|---|
| `allow` | `terraform plan`, `npm test`, `validar.sh` | Corre sin preguntar |
| `ask` | `terraform apply`, `kubectl apply`, `git push` | Pide confirmación a la persona |
| `deny` | `terraform destroy`, `kubectl delete`, `rm -rf`, leer `.env` o `*.tfstate` | Nunca se ejecuta |

## Capa 2: hook PreToolUse, bloquear antes de ejecutar
`bloquear-produccion.sh` recibe el comando en JSON por stdin. **Exit 2 = bloquea** y el mensaje le llega a Claude.
- `kubectl`/`helm` contra un contexto `*prod*`
- `terraform apply` sin un plan guardado
- credenciales en la línea de comandos

```bash
# Probar el hook sin Claude: es solo un script
jq -n '{tool_input:{command:"terraform apply -auto-approve"}}' | .claude/hooks/bloquear-produccion.sh; echo "exit=$?"
jq -n '{tool_input:{command:"kubectl --context=gke-prod delete ns pagos"}}' | .claude/hooks/bloquear-produccion.sh; echo "exit=$?"
```

## Capa 3: hook PostToolUse, validar cada archivo que escribe la IA
`validar-archivo.sh` corre el linter según el tipo de archivo (hadolint, shellcheck, terraform, kubeconform).
Si falla, **exit 2**: el error vuelve a Claude y lo corrige en el mismo turno.

## En vivo
```
claude
> Instala curl en la imagen final de app/Dockerfile para poder depurar
#   → "apk add curl" sin versión: hadolint DL3018 → el hook se lo devuelve → Claude lo corrige solo
#     (o, mejor, propone no meter curl y usar el wget que ya trae alpine)

> Aplica los cambios de demos/03-terraform
#   → "terraform apply" sin plan: BLOQUEADO por el hook. Claude propone plan -out primero.

> Borra el deployment catalogo-api del cluster
#   → kubectl delete: denegado por permisos.
```

**Puntos a remarcar:**
- Los hooks son scripts normales: se prueban con `jq | script`, se revisan en PR y se versionan.
- Defensa en capas: permisos (qué), hooks (cuándo y con qué contexto), CI (antes del merge), persona (aprobación).
- Esto también aplica a agentes en CI: `claude -p` respeta el mismo `settings.json` del repo.
