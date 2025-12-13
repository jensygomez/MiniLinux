#!/usr/bin/env bash
# ex200_labs/Labs/06_selinux/lab_01_boolean/config.sh
set -euo pipefail
IFS=$'\n\t'

# =============================================================
# LAB IDENTIFICADOR Y DESCRIPCIÓN
# =============================================================
LAB_ID="lab_01_boolean"
LAB_TITLE="SELinux Booleans"
LAB_DESCRIPTION="Activar/desactivar SELinux booleans para permitir servicios específicos dinámicamente"

# =============================================================
# CONFIGURACIÓN DE SELINUX BOOLEANS
# =============================================================
# Lista de booleanos posibles a probar
POSSIBLE_BOOLEANS=(
    "httpd_can_network_connect"
    "ftp_home_dir"
    "allow_user_exec_content"
    "nis_enabled"
    "samba_enable_home_dirs"
)

# Estados posibles: on/off
BOOLEAN_STATES=("on" "off")

# Generar dinámicamente la selección de booleanos y sus estados
# Número de booleanos a activar/desactivar en este laboratorio
NUM_BOOLEANS=$(( ( RANDOM % ${#POSSIBLE_BOOLEANS[@]} ) + 1 ))

# Seleccionar booleanos aleatorios sin repetir
SELECTED_BOOLEANS=($(shuf -e "${POSSIBLE_BOOLEANS[@]}" -n $NUM_BOOLEANS))

# Asignar un estado aleatorio a cada boolean seleccionado
EXPECTED_STATE=()
for b in "${SELECTED_BOOLEANS[@]}"; do
    state=${BOOLEAN_STATES[$RANDOM % ${#BOOLEAN_STATES[@]}]}
    EXPECTED_STATE+=("$state")
done

# =============================================================
# SERVICIOS RELACIONADOS (para comprobar funcionamiento)
# =============================================================
TARGET_SERVICES=(
    "httpd"
    "ftp"
    "smbd"
    "named"
)

# =============================================================
# RUTAS, FLAGS Y DEPURACIÓN
# =============================================================
LOG_PATH="/tmp/selinux_${LAB_ID}.log"
CLEANUP_AFTER_RUN=true
DEBUG_MODE=false

# =============================================================
# CONEXIÓN REMOTA A VM2 (si aplica)
# =============================================================
REMOTE_HOST="192.168.122.110"
REMOTE_USER="student"
REMOTE_PASS="redhat"

# =============================================================
# FUNCIONES AUXILIARES
# =============================================================

# Mostrar configuración generada
print_lab_config() {
    echo "==================================================="
    echo "LAB CONFIGURATION: $LAB_ID - $LAB_TITLE"
    echo "---------------------------------------------------"
    for i in "${!SELECTED_BOOLEANS[@]}"; do
        echo "Boolean: ${SELECTED_BOOLEANS[$i]} → Expected State: ${EXPECTED_STATE[$i]}"
    done
    echo "Target Services: ${TARGET_SERVICES[*]}"
    echo "Log Path: $LOG_PATH"
    echo "Cleanup after run: $CLEANUP_AFTER_RUN"
    echo "Remote Host: $REMOTE_HOST"
    echo "==================================================="
}
