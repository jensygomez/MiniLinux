#!/usr/bin/env bash

BASE_DIR="$HOME/MiniLinux"
DB="$BASE_DIR/data/labs_index.db"

declare -A MODULE_MAP=(
    ["1"]="module01_basics"
    ["2"]="module02_users"
    ["3"]="module03_storage"
    ["4"]="module04_networking"
    ["5"]="module05_systemctl"
    ["6"]="module06_security"
)

clear
echo "==============================================="
echo "        ADICIONAR NUEVO LABORATORIO"
echo "==============================================="
echo
echo "Seleccione el módulo:"
echo "1) Basics"
echo "2) Usuarios"
echo "3) Storage"
echo "4) Networking"
echo "5) Systemctl / Services"
echo "6) Seguridad"
echo

read -p "Opción: " mod

TARGET_MODULE="${MODULE_MAP[$mod]}"

if [ -z "$TARGET_MODULE" ]; then
    echo "Módulo inválido."
    sleep 1
    exit 1
fi

MODULE_DIR="$BASE_DIR/labs/$TARGET_MODULE"

mkdir -p "$MODULE_DIR"

TMP="/tmp/newlab.txt"

# Crear template vacío
cat > "$TMP" <<EOF
# Pegue aquí su laboratorio en formato libre.
# Ejemplo:
# ID: lab-001
# Title: Configurar LVM básico
# Scenario: ...
# Setup: ...
# Validations: ...
EOF

nano "$TMP"

# PARSING SIMPLE
LAB_ID=$(grep -i "^ID:" "$TMP" | awk '{print $2}')
LAB_TITLE=$(grep -i "^Title:" "$TMP" | cut -d':' -f2- | sed 's/^ *//')

if [ -z "$LAB_ID" ]; then
    echo "ERROR: No se encontró el ID del laboratorio."
    sleep 2
    exit 1
fi

FINAL_PATH="$MODULE_DIR/$LAB_ID.lab"

cp "$TMP" "$FINAL_PATH"

echo "$LAB_ID | $TARGET_MODULE | $LAB_TITLE" >> "$DB"

echo
echo "Laboratorio agregado:"
echo " - ID: $LAB_ID"
echo " - Modulo: $TARGET_MODULE"
echo " - Archivo: $FINAL_PATH"
echo
sleep 2
