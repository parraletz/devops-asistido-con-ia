# Demo 2 · Generar, revisar y optimizar un script de automatización

**Archivo:** `demos/02-bash/backup.antes.sh` → resultado esperado parecido a `demos/02-bash/backup.sh`

## Paso 0: el linter primero (evidencia objetiva)
```bash
shellcheck demos/02-bash/backup.antes.sh
```

## Prompt
```
Este script de respaldo corre en cron en producción: demos/02-bash/backup.antes.sh
Aquí está la salida de shellcheck: <pegar salida>

1. Explica en lenguaje simple qué puede salir MAL si se ejecuta tal cual
   (piensa en: argumentos vacíos, espacios en rutas, rm -rf, secretos).
2. Reescríbelo con: set -euo pipefail, validación de argumentos, logs con timestamp,
   la contraseña leída de un archivo (BACKUP_PASSPHRASE_FILE), retención configurable.
3. No uses herramientas que no estén en una imagen Debian estándar.
```

## Validación humana
```bash
shellcheck demos/02-bash/backup.sh          # debe salir limpio
bash -n demos/02-bash/backup.sh             # sintaxis
# Prueba en un directorio temporal, NUNCA contra /backups real:
mkdir -p /tmp/demo-origen && echo hola > /tmp/demo-origen/a.txt
echo 'frase-de-prueba' > /tmp/pass.txt
BACKUP_ROOT=/tmp/demo-backups BACKUP_PASSPHRASE_FILE=/tmp/pass.txt \
  ./demos/02-bash/backup.sh /tmp/demo-origen prueba
```

**Punto a remarcar:** `rm -rf $DEST/*` con `$2` vacío. Preguntar al chat: *¿qué borra?*
