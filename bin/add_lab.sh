#!/usr/bin/env bash
# add_lab.sh — abrir nano, permitir pegar varios LAB_XXX, parsear e instalar
set -euo pipefail

BASE_DIR="$HOME/MiniLinux"
LABS_DIR="$BASE_DIR/labs"
DATA_DIR="$BASE_DIR/data"
TMP_FILE="/tmp/new_lab_$$.lab"

# ------------------------------------------
# EXTRACTOR ROBUSTO DE BLOQUES (NUEVO)
# ------------------------------------------
extract_block() {
    local file="$1"
    local section="$2"

    awk -v start="$section" '
        # Comienza cuando encuentra la sección exacta
        $0 ~ "^\\[" start "\\]" {capture=1; next}

        # Termina al encontrar otra sección
        capture && $0 ~ "^\\[[A-Z0-9_]+\\]" {exit}

        # Imprime contenido interno
        capture {print}
    ' "$file"
}

# pedir módulo
source "$BASE_DIR/bin/menu_modulos.sh" || { echo "menu_modulos missing"; exit 1; }
if ! select_modulo; then
  echo "Operación cancelada."
  exit 1
fi

MODULE="$MODULE_DIR_NAME"
MODULE_NAME="$MODULO_NOMBRE"
MODULE_PATH="$LABS_DIR/$MODULE"

mkdir -p "$MODULE_PATH"

echo
echo "Se abrirá el editor. Pegue aquí el archivo con uno o varios bloques [LAB_XXX]."
echo "Al guardar y salir, el sistema procesará el archivo y creará los labs."
read -rp "ENTER para abrir el editor..." _
: > "$TMP_FILE"
${EDITOR:-nano} "$TMP_FILE"

# validar archivo
if [ ! -s "$TMP_FILE" ]; then
  echo "Archivo vacío. Cancelando."
  rm -f "$TMP_FILE"
  exit 1
fi

# detectar bloques [LAB_###]
LAB_TAGS=$(grep -oE '^\[LAB_[0-9]{3}\]' "$TMP_FILE" | sed 's/\[//;s/\]//' | uniq)

if [ -z "$LAB_TAGS" ]; then
  echo "No se detectaron bloques [LAB_###]."
  rm -f "$TMP_FILE"
  exit 1
fi

echo "Se detectaron los siguientes bloques:"
echo "$LAB_TAGS"
echo

# FUNCIÓN extract_field
extract_field() {
  local block="$1" file="$2" key="$3"
  awk -v b="$block" -v k="$key" '
    $0 == "["b"]"{p=1; next}
    /^\[/{p=0}
    p && $0 ~ "^"k"[[:space:]]*=" {
       sub("[^=]*=[[:space:]]*","",$0); print; exit
    }
  ' "$file"
}

# procesar cada LAB
for tag in $LAB_TAGS; do
  num=$(echo "$tag" | sed 's/LAB_//')
  LAB_PREFIX="LAB_${num}"

  ID_RAW=$(extract_field "$tag" "$TMP_FILE" "ID" || true)
  ID=$(echo "$ID_RAW" | tr -d ' ')
  [ -z "$ID" ] && ID="lab-${MODULE}-${num}"

  TITLE=$(extract_field "$tag" "$TMP_FILE" "TITLE" || true)
  TITLE=${TITLE:-"Untitled"}

  TARGET_DIR="$MODULE_PATH/$ID"

  if [ -d "$TARGET_DIR" ]; then
    echo "ATENCIÓN: $TARGET_DIR ya existe."
    read -rp "Desea [O]verwrite / [S]kip / [R]ename ? (O/S/R): " choice
    case "$choice" in
      O|o) rm -rf "$TARGET_DIR" ;;
      S|s) echo "Omitiendo $ID"; continue ;;
      R|r) read -rp "Nuevo ID: " newid; ID="$newid"; TARGET_DIR="$MODULE_PATH/$ID" ;;
      *) echo "Opción inválida. Omitiendo."; continue ;;
    esac
  fi

  mkdir -p "$TARGET_DIR"

  # METADATA
  {
    echo "ID=$ID"
    echo "TITLE=$TITLE"
    echo "MODULE=$MODULE"
    echo "MODULE_NAME=$MODULE_NAME"
    echo "CREATED=$(date +%F_%T)"
  } > "$TARGET_DIR/metadata.db"

  # ------------------------------------------
  # BLOQUES CORRECTOS (NUEVO SISTEMA)
  # ------------------------------------------

  # SCENARIO
  extract_block "$TMP_FILE" "${LAB_PREFIX}_SCENARIO" > "$TARGET_DIR/scenario.txt"

  # SETUP
  extract_block "$TMP_FILE" "${LAB_PREFIX}_SETUP" > "$TARGET_DIR/setup.sh"
  chmod +x "$TARGET_DIR/setup.sh"

  # VALIDACIONES
  extract_block "$TMP_FILE" "${LAB_PREFIX}_VALIDACIONES" > "$TARGET_DIR/validations.sh"
  chmod +x "$TARGET_DIR/validations.sh"

  # actualizar índice
  echo "${ID}|${MODULE}|${TITLE}|$(date +%F)" >> "$DATA_DIR/labs_index.db"

  echo "Instalado: $ID -> $TARGET_DIR"
done

rm -f "$TMP_FILE"
echo
echo "Importación completada."
echo "Presione ENTER para volver al menú..."
read -r
