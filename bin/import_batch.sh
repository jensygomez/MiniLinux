#!/usr/bin/env bash
# import_batch.sh <file_with_multiple_labs>
set -euo pipefail
if [ $# -lt 1 ]; then
  echo "Uso: import_batch.sh /ruta/al/archivo.lab"
  exit 1
fi
SRC="$1"
BASE_DIR="$HOME/MiniLinux"
DATA_DIR="$BASE_DIR/data"
BIN_DIR="$BASE_DIR/bin"
LABS_DIR="$BASE_DIR/labs"

if [ ! -f "$SRC" ]; then
  echo "Archivo no encontrado: $SRC"
  exit 1
fi

# default module (ask user)
source "$BIN_DIR/menu_modulos.sh"
if ! select_modulo; then
  echo "Cancelado."
  exit 1
fi
MODULE="$MODULE_DIR_NAME"
MODULE_PATH="$LABS_DIR/$MODULE"
mkdir -p "$MODULE_PATH"

# reuse add_lab parsing logic by copying to /tmp and calling add_lab.sh with module preselected
TMPF="/tmp/import_batch_$$.lab"
cp "$SRC" "$TMPF"

# parse blocks
LAB_TAGS=$(grep -oE '^\[LAB_[0-9]{3}\]' "$TMPF" | sed 's/\[//;s/\]//' | uniq)
if [ -z "$LAB_TAGS" ]; then
  echo "No se detectaron bloques [LAB_###]"
  rm -f "$TMPF"
  exit 1
fi

for tag in $LAB_TAGS; do
  num=$(echo "$tag" | sed 's/LAB_//')
  LAB_PREFIX="LAB_${num}"
  ID=$(awk -v b="$LAB_PREFIX" ' $0 == "["b"]" {p=1; next} /^\[/ {p=0} p && /^ID[[:space:]]*=/ {sub("^[^=]*=[[:space:]]*",""); print; exit}' "$TMPF" | tr -d ' ')
  TITLE=$(awk -v b="$LAB_PREFIX" ' $0 == "["b"]" {p=1; next} /^\[/ {p=0} p && /^TITLE[[:space:]]*=/ {sub("^[^=]*=[[:space:]]*",""); print; exit}' "$TMPF")
  [ -z "$ID" ] && ID="lab-${MODULE}-${num}"
  TARGET_DIR="$MODULE_PATH/$ID"
  mkdir -p "$TARGET_DIR"
  awk "/\[$LAB_PREFIX\_SCENARIO\]/,/\[/{if(\$0 !~ /\\[$LAB_PREFIX\\_SCENARIO\\]|\\[/) print}" "$TMPF" > "$TARGET_DIR/scenario.txt" 2>/dev/null || true
  awk "/\[$LAB_PREFIX\_SETUP\]/,/\[/{if(\$0 !~ /\\[$LAB_PREFIX\\_SETUP\\]|\\[/) print}" "$TMPF" > "$TARGET_DIR/setup.sh" 2>/dev/null || true
  chmod +x "$TARGET_DIR/setup.sh" 2>/dev/null || true
  awk "/\[$LAB_PREFIX\_VALIDACIONES\]/,/\[/{if(\$0 !~ /\\[$LAB_PREFIX\\_VALIDACIONES\\]|\\[/) print}" "$TMPF" > "$TARGET_DIR/validations.sh" 2>/dev/null || true
  chmod +x "$TARGET_DIR/validations.sh" 2>/dev/null || true
  echo "${ID}|${MODULE}|${TITLE}|$(date +%F)" >> "$DATA_DIR/labs_index.db"
  echo "Importado: $ID"
done

rm -f "$TMPF"
echo "Batch import finalizado."
