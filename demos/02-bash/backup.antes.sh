#!/bin/bash
# Versión "antes": script de respaldo heredado.
# DEMO: pídele a la IA que lo revise con shellcheck en mente (ver prompts/02-bash.md).
# Problemas sembrados a propósito:
#  - sin set -euo pipefail
#  - variables sin comillas (rompe con espacios)
#  - rm -rf con variable que puede venir vacía
#  - contraseña en texto plano
#  - sin validación de argumentos ni de errores
#  - parsing de ls

DIR=$1
DEST=/backups/$2
PASS=SuperSecreta123

rm -rf $DEST/*
mkdir -p $DEST

for f in $(ls $DIR); do
  cp $DIR/$f $DEST
done

tar -czf $DEST.tar.gz $DEST
echo $PASS | gpg --batch --passphrase-fd 0 -c $DEST.tar.gz

find /backups -mtime +7 -exec rm {} \;
echo "Backup listo"
