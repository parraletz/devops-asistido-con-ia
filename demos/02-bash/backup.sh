#!/usr/bin/env bash
# Versión "después": revisada con IA y validada con shellcheck.
# Uso: BACKUP_PASSPHRASE_FILE=/ruta/secreto ./backup.sh <dir_origen> <nombre_respaldo>
set -euo pipefail

readonly BACKUP_ROOT="${BACKUP_ROOT:-/backups}"
readonly RETENCION_DIAS="${RETENCION_DIAS:-7}"

log() { printf '%s [%s] %s\n' "$(date -u +%FT%TZ)" "$1" "$2" >&2; }
fallar() { log ERROR "$1"; exit 1; }

[[ $# -eq 2 ]] || fallar "uso: $0 <dir_origen> <nombre_respaldo>"

readonly origen="$1"
readonly nombre="$2"

[[ -d "$origen" ]] || fallar "el directorio origen no existe: $origen"
[[ "$nombre" =~ ^[A-Za-z0-9._-]+$ ]] || fallar "nombre de respaldo inválido: $nombre"
[[ -n "${BACKUP_PASSPHRASE_FILE:-}" && -r "$BACKUP_PASSPHRASE_FILE" ]] \
  || fallar "define BACKUP_PASSPHRASE_FILE con un archivo legible"

mkdir -p "$BACKUP_ROOT"
archivo="${BACKUP_ROOT}/${nombre}-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
readonly archivo

log INFO "respaldando $origen -> $archivo"
tar -czf "$archivo" -C "$origen" .

gpg --batch --yes --pinentry-mode loopback \
  --passphrase-file "$BACKUP_PASSPHRASE_FILE" \
  -c "$archivo"
rm -f -- "$archivo"

log INFO "limpiando respaldos con más de ${RETENCION_DIAS} días"
find "$BACKUP_ROOT" -maxdepth 1 -type f -name '*.tar.gz.gpg' -mtime +"$RETENCION_DIAS" -print -delete

log INFO "respaldo listo: ${archivo}.gpg"
