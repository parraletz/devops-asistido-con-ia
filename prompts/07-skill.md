# Demo 7 · Convertir lo aprendido en un skill para el equipo

**Archivo resultado:** `.claude/skills/devops-estandares/` (`SKILL.md` + `scripts/validar.sh`)

Ya corregimos el Dockerfile, el script, el Terraform, el Deployment y el pipeline.
Si no guardamos esas reglas, mañana la IA (o un compañero) vuelve a generar `node:latest`.
Un **skill** es una carpeta con instrucciones y scripts que Claude carga sola cuando la tarea coincide con su descripción.

## Prompt: crear el skill a partir de lo que ya corregimos
```
Revisa los pares "antes/después" de este repo:
- demos/01-dockerfile/Dockerfile.antes  vs  app/Dockerfile
- demos/02-bash/backup.antes.sh         vs  demos/02-bash/backup.sh
- demos/04-kubernetes/deployment.antes.yaml vs deployment.yaml
- .github/workflows/*.yml
- prompts/03-terraform.md (lección del bloque moved)

Con eso crea un skill de proyecto en .claude/skills/devops-estandares/:
1. SKILL.md con frontmatter (name, description). La description debe decir CUÁNDO usarlo:
   al crear o revisar Dockerfiles, scripts, Terraform, manifiestos de K8s o workflows.
2. Reglas concretas por tipo de archivo, sacadas de las correcciones (no genéricas).
3. Forma de trabajar: diagnosticar antes de reescribir, no inventar, nada destructivo sin
   una persona, secretos fuera.
4. scripts/validar.sh que corra hadolint, shellcheck, terraform fmt/validate y kubeconform
   (local o en contenedor) y falle con exit 1 si algo no pasa.
Muéstrame el SKILL.md antes de escribir el script.
```

## Probarlo en vivo
```bash
# 1. Validación directa
.claude/skills/devops-estandares/scripts/validar.sh

# 2. Que Claude lo use solo: nueva sesión de Claude Code en el repo
claude
> Crea un Dockerfile para un worker en Python que procese una cola
#   → debe salir con versión fija, multi-stage, USER no root, HEALTHCHECK
#     y terminar corriendo validar.sh
```

## Pasárselo al equipo de desarrollo
| Alcance | Dónde vive | Cómo llega |
|---|---|---|
| **Proyecto** | `.claude/skills/` dentro del repo | Va en git: todo el que clona el repo y abre Claude Code lo tiene |
| **Personal** | `~/.claude/skills/` | Cada developer lo copia para usarlo en todos sus proyectos |
| **Organización** | Un plugin en un marketplace interno | Se instala con `/plugin` y se actualiza en un solo lugar |

**Puntos a remarcar:**
- El skill es código: se revisa en PR, tiene historial y se mejora con cada incidente o postmortem.
- El mismo `validar.sh` corre en el CI (`.github/workflows/ci.yml`): la regla es la misma para el developer, para Claude y para el pipeline.
- El developer no necesita saber DevOps a fondo para producir un Dockerfile aceptable. El equipo de plataforma escribe las reglas una vez y cada PR ya llega mejor.
