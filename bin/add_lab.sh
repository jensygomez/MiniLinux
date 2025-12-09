#!/bin/bash

BASE_DIR="$(dirname "$(realpath "$0")")/.."
LABS_DIR="$BASE_DIR/labs"
DATA_DIR="$BASE_DIR/data"
TMP_FILE="/tmp/new_lab_$$.lab"

clear
echo "==============================================="
echo "     RHCSA MINI LINUX — ADICIONAR LAB"
echo "==============================================="
echo
echo "Seleccione el módulo donde se almacenará:"
echo
echo "1) Local Storage"
echo "2) User & Groups"
echo "3) Networking"
echo "4) Firewalld & SELinux"
echo "5) Containers"
echo "6) Scripting"
echo
read -p "Opción: " MOD

case "$MOD" in
    1) MODULE="local_storage" ;;
    2) MODULE="users_groups" ;;
    3) MODULE="networking" ;;
    4) MODULE="security" ;;
    5) MODULE="containers" ;;
    6) MODULE="scripting" ;;
    *) echo "Opción inválida"; exit 1 ;;
esac

echo
echo "Se abrirá NANO. Pegue su contenido completo del laboratorio."
echo "Al guardar, se procesará automáticamente."
echo
read -p "Presione ENTER para continuar..."

nano "$TMP_FILE"
echo
echo "Procesando laboratorio..."
echo

if [ ! -s "$TMP_FILE" ]; then
    echo "Nada fue ingresado. Cancelando."
    exit 1
fi

# ---------------------------------------------------------
# DETECTAR BLOQUES DE LABORATORIOS
# ---------------------------------------------------------
LAB_IDS=$(grep -oP "^\[LAB_\K[0-9]{3}(?=\])" "$TMP_FILE")

if [ -z "$LAB_IDS" ]; then
    echo "No se detectaron LAB_XXX. Archivo inválido."
    exit 1
fi

echo "Se detectaron los siguientes LABS:"
echo "$LAB_IDS"
echo

# ---------------------------------------------------------
# PROCESAR LAB POR LAB
# ---------------------------------------------------------
for LAB_NUM in $LAB_IDS; do

    LAB_TAG="LAB_${LAB_NUM}"

    ID=$(awk -F'=' "/\[$LAB_TAG\]/,/^\[/{ if(\$1 ~ /ID/) print \$2 }" "$TMP_FILE" | tr -d ' ')
    TITLE=$(awk -F'=' "/\[$LAB_TAG\]/,/^\[/{ if(\$1 ~ /TITLE/) print \$2 }" "$TMP_FILE" | sed 's/^ //')
    SUBTITLE=$(awk -F'=' "/\[$LAB_TAG\]/,/^\[/{ if(\$1 ~ /SUBTITLE/) print \$2 }" "$TMP_FILE" | sed 's/^ //')

    LAB_DIR="$LABS_DIR/$ID"
    mkdir -p "$LAB_DIR"

    # -------------------------------
    # METADATA
    # -------------------------------
    {
        echo "ID=$ID"
        echo "TITLE=$TITLE"
        echo "SUBTITLE=$SUBTITLE"
        echo "MODULE=$MODULE"
        echo "NUM=$LAB_NUM"
    } > "$LAB_DIR/metadata.db"

    # -------------------------------
    # SCENARIO
    # -------------------------------
    awk "/\[$LAB_TAG\_SCENARIO\]/,/^\[/" "$TMP_FILE" | sed '1d;$d' > "$LAB_DIR/scenario.txt"

    # -------------------------------
    # SETUP
    # -------------------------------
    awk "/\[$LAB_TAG\_SETUP\]/,/^\[/" "$TMP_FILE" | sed '1d;$d' > "$LAB_DIR/setup.sh"
    chmod +x "$LAB_DIR/setup.sh"

    # -------------------------------
    # VALIDACIONES
    # -------------------------------
    awk "/\[$LAB_TAG\_VALIDACIONES\]/,/^\[/" "$TMP_FILE" | sed '1d;$d' > "$LAB_DIR/validations.sh"
    chmod +x "$LAB_DIR/validations.sh"

    # -------------------------------
    # Registrar en base de datos
    # -------------------------------
    echo "$ID|$MODULE|$TITLE" >> "$DATA_DIR/labs_index.db"

    echo "LAB $ID creado."
    echo

done

echo "Proceso finalizado."
echo "Los laboratorios fueron instalados correctamente."




