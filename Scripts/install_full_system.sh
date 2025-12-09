#!/usr/bin/env bash
# install_full_system.sh
# Instala / actualiza MiniLinux: módulos, scripts y DB (BASH puro)
set -euo pipefail

BASE="$HOME/MiniLinux"
BIN="$BASE/bin"
DATA="$BASE/data"
LABS="$BASE/labs"
SCRIPTS="$BASE/Scripts"

echo "Instalando/actualizando MiniLinux en: $BASE"

mkdir -p "$BIN" "$DATA" "$LABS" "$SCRIPTS" "$BASE/logs/lab_runs" "$BASE/system"

# ------------------------
# Crear estructura de módulos (carpetas)
# ------------------------
declare -a MODULES=( \
  "local_storage" \
  "users_groups" \
  "networking" \
  "security" \
  "containers" \
  "scripting" \
)

for m in "${MODULES[@]}"; do
  mkdir -p "$LABS/$m"
done

# ------------------------
# Crear base de datos inicial (si no existe)
# ------------------------
: > "$DATA/labs_index.db"      # truncar o crear
if ! grep -q "^# created=" "$DATA/metadata.db" 2>/dev/null; then
  cat > "$DATA/metadata.db" <<EOF
# created=$(date +"%F %T %z")
system_name=RHCSA Mini Linux
version=1.0
EOF
fi

: > "$DATA/progress.db"
: > "$DATA/stats.db"

# ------------------------
# Instalar menu_modulos.sh (sincronizado con carpetas)
# ------------------------
cat > "$BIN/menu_modulos.sh" <<'EOF'
#!/usr/bin/env bash
# menu_modulos.sh — devuelve MODULO_ID y MODULE_DIR_NAME y MODULO_NOMBRE
select_modulo() {
  clear
  echo "============================================================="
  echo "             RHCSA MINI LINUX — SELECCIONAR MÓDULO"
  echo "============================================================="
  echo ""
  echo "Seleccione a qué módulo pertenece el laboratorio:"
  echo ""
  echo "  1) Local Storage (LVM, FS, Mounts)"
  echo "  2) Users & Groups"
  echo "  3) Networking"
  echo "  4) Security (SELinux/Firewalld)"
  echo "  5) Containers"
  echo "  6) Scripting / Automation"
  echo ""
  echo "  0) Volver"
  echo ""
  read -rp "Digite la opción: " opc
  case "$opc" in
    1) MODULO_ID=1; MODULE_DIR_NAME="local_storage"; MODULO_NOMBRE="Local Storage" ;;
    2) MODULO_ID=2; MODULE_DIR_NAME="users_groups"; MODULO_NOMBRE="Users & Groups" ;;
    3) MODULO_ID=3; MODULE_DIR_NAME="networking"; MODULO_NOMBRE="Networking" ;;
    4) MODULO_ID=4; MODULE_DIR_NAME="security"; MODULO_NOMBRE="Security" ;;
    5) MODULO_ID=5; MODULE_DIR_NAME="containers"; MODULO_NOMBRE="Containers" ;;
    6) MODULO_ID=6; MODULE_DIR_NAME="scripting"; MODULO_NOMBRE="Scripting" ;;
    0) return 1 ;;
    *) echo "Opción inválida."; sleep 1; select_modulo; return ;;
  esac
  return 0
}
EOF
chmod +x "$BIN/menu_modulos.sh"

# ------------------------
# Instalar add_lab.sh (parser + instalador desde archivo temporal)
# ------------------------
cat > "$BIN/add_lab.sh" <<'EOF'
#!/usr/bin/env bash
# add_lab.sh — abrir nano, permitir pegar varios LAB_XXX, parsear e instalar
set -euo pipefail

BASE_DIR="$HOME/MiniLinux"
LABS_DIR="$BASE_DIR/labs"
DATA_DIR="$BASE_DIR/data"
TMP_FILE="/tmp/new_lab_$$.lab"

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

# detectar bloques [LAB_###] en orden de aparición
LAB_TAGS=$(grep -oE '^\[LAB_[0-9]{3}\]' "$TMP_FILE" | sed 's/\[//;s/\]//' | uniq)

if [ -z "$LAB_TAGS" ]; then
  echo "No se detectaron bloques [LAB_###]. Asegúrate del formato."
  rm -f "$TMP_FILE"
  exit 1
fi

echo "Se detectaron los siguientes bloques:"
echo "$LAB_TAGS"
echo

# función auxiliar: extraer campo dentro de un bloque
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
  # extraer ID; si no existe, generar ID por numeración incremental
  ID_RAW=$(extract_field "$tag" "$TMP_FILE" "ID" || true)
  ID=$(echo "$ID_RAW" | tr -d ' ')

  if [ -z "$ID" ]; then
    # generar ID: lab-<module>-NNN (NNN = num)
    ID="lab-${MODULE}-${num}"
  fi

  # título
  TITLE=$(extract_field "$tag" "$TMP_FILE" "TITLE" || true)
  TITLE=${TITLE:-"Untitled"}

  # crear carpeta destino
  TARGET_DIR="$MODULE_PATH/$ID"
  if [ -d "$TARGET_DIR" ]; then
    echo "ATENCIÓN: $TARGET_DIR ya existe."
    read -rp "Desea [O]verwrite / [S]kip / [R]ename ? (O/S/R): " choice
    case "$choice" in
      O|o) rm -rf "$TARGET_DIR" ;;
      S|s) echo "Omitiendo $ID"; continue ;;
      R|r) 
         read -rp "Nuevo ID (ej: ${ID}_v2): " newid
         ID="$newid"
         TARGET_DIR="$MODULE_PATH/$ID"
         ;;
      *) echo "Opción inválida. Omitiendo."; continue ;;
    esac
  fi
  mkdir -p "$TARGET_DIR"

  # metadata
  {
    echo "ID=$ID"
    echo "TITLE=$TITLE"
    echo "MODULE=$MODULE"
    echo "MODULE_NAME=$MODULE_NAME"
    echo "CREATED=$(date +%F_%T)"
  } > "$TARGET_DIR/metadata.db"

  # SCENARIO: bloque [LAB_###_SCENARIO]
  awk "/\[$LAB_PREFIX\_SCENARIO\]/,/\[/{if(\$0 !~ /\\[$LAB_PREFIX\\_SCENARIO\\]|\\[/) print}" "$TMP_FILE" > "$TARGET_DIR/scenario.txt" 2>/dev/null || true

  # SETUP
  awk "/\[$LAB_PREFIX\_SETUP\]/,/\[/{if(\$0 !~ /\\[$LAB_PREFIX\\_SETUP\\]|\\[/) print}" "$TMP_FILE" > "$TARGET_DIR/setup.sh" 2>/dev/null || true
  chmod +x "$TARGET_DIR/setup.sh" 2>/dev/null || true

  # VALIDACIONES
  awk "/\[$LAB_PREFIX\_VALIDACIONES\]/,/\[/{if(\$0 !~ /\\[$LAB_PREFIX\\_VALIDACIONES\\]|\\[/) print}" "$TMP_FILE" > "$TARGET_DIR/validations.sh" 2>/dev/null || true
  chmod +x "$TARGET_DIR/validations.sh" 2>/dev/null || true

  # resumen: agregar a labs_index.db
  echo "${ID}|${MODULE}|${TITLE}|$(date +%F)" >> "$DATA_DIR/labs_index.db"
  echo "Instalado: $ID -> $TARGET_DIR"
done

# limpiar
rm -f "$TMP_FILE"
echo
echo "Importación completada."
echo "Presione ENTER para volver al menú..."
read -r
EOF
chmod +x "$BIN/add_lab.sh"

# ------------------------
# Instalar import_batch.sh (importar un archivo ya existente sin abrir nano)
# ------------------------
cat > "$BIN/import_batch.sh" <<'EOF'
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
EOF
chmod +x "$BIN/import_batch.sh"

# ------------------------
# Actualizar menu_labs.sh (mantener tu lógica, asegurar llamada a add_lab.sh)
# ------------------------
cat > "$BIN/menu_labs.sh" <<'EOF'
#!/usr/bin/env bash
BASE_DIR="$HOME/MiniLinux"
DB="$BASE_DIR/data/labs_index.db"
while true; do
  clear
  echo "==============================================="
  echo "      RHCSA MINI LINUX — LABORATORIOS"
  echo "==============================================="
  echo
  if [ -f "$DB" ]; then
    printf "%-5s %-10s %-40s\n" "ID" "Módulo" "Nombre"
    printf "%-5s %-10s %-40s\n" "-----" "----------" "----------------------------------------"
    head -n 20 "$DB" | while IFS='|' read -r id modulo nombre date; do
      printf "%-5s %-10s %-40s\n" "$id" "$modulo" "$nombre"
    done
  else
    echo "(sin laboratorios registrados)"
  fi
  echo
  echo "MostrarCompleta   Adicionar   Editar   Excluir   Volver"
  echo
  read -p "Seleccione opción: " op
  case "$op" in
    MostrarCompleta|mostrar|m) "$BASE_DIR/bin/list_labs.sh"; read -p "ENTER para continuar..." ;;
    Adicionar|adicionar|a) "$BASE_DIR/bin/add_lab.sh" ;;
    Editar|editar|e) "$BASE_DIR/bin/manage_labs.sh" ;;
    Excluir|excluir|x) "$BASE_DIR/bin/manage_labs.sh" ;;
    Volver|volver|v) exit 0 ;;
    *) echo "Opción inválida"; sleep 1 ;;
  esac
done
EOF
chmod +x "$BIN/menu_labs.sh"

# ------------------------
# Install helper scripts (minimal list_labs.sh if missing)
# ------------------------
cat > "$BIN/list_labs.sh" <<'EOF'
#!/usr/bin/env bash
DB="$HOME/MiniLinux/data/labs_index.db"
if [ ! -f "$DB" ]; then echo "No hay labs."; exit 0; fi
clear
echo "LISTA DE LABS (index)"
echo "---------------------------------"
nl -ba "$DB" | sed 's/^/    /'
echo
read -p "ENTER para volver..."
EOF
chmod +x "$BIN/list_labs.sh"

# ------------------------
# Final: permisos y mensaje
# ------------------------
chmod -R 755 "$BIN" 2>/dev/null || true
chmod -R 755 "$LABS" 2>/dev/null || true

echo "Instalación completada."
echo "Para iniciar el menú: $BIN/menu_labs.sh"
echo "Para importar un archivo ya creado: $BIN/import_batch.sh /ruta/al/archivo"
echo "Para agregar manualmente (editar/pegar): $BIN/add_lab.sh"
