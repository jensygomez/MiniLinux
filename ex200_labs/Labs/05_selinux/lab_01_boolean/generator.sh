#!/usr/bin/env bash
# ex200_labs/modules/generators/selinux_generator.sh
set -euo pipefail
IFS=$'\n\t'

# -------------------------
# Cargar configuración global y librerías
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/modules/config.sh"
source "${PROJECT_ROOT}/modules/math_utils.sh"
source "${PROJECT_ROOT}/modules/utils.sh"

generate_selinux_vars() {
    # Declarar variables globales
    declare -g LAB_ID REMOTE_HOST
    declare -g SELECTED_BOOLEANS EXPECTED_STATE

    # ID único para ticket
    LAB_ID="sel-${RANDOM}${RANDOM}"
    
    # Host remoto donde se aplicarán cambios
    REMOTE_HOST="${VM2_IP:-192.168.122.110}"

    # Seleccionar aleatoriamente 3-5 SELinux Booleans críticos
    BOOLEANS_CANDIDATES=("httpd_enable_homedirs" "ftp_home_dir" "nis_enabled" "samba_enable_home_dirs" "allow_user_mysql_connect")
    EXPECTED_STATES=("on" "off")  # posibles estados
    
    # Elegir aleatoriamente booleans y su estado esperado
    NUM_BOOLS=$((3 + RANDOM % 3)) # 3-5
    SELECTED_BOOLEANS=()
    EXPECTED_STATE=()
    for i in $(seq 1 $NUM_BOOLS); do
        idx=$((RANDOM % ${#BOOLEANS_CANDIDATES[@]}))
        bool="${BOOLEANS_CANDIDATES[$idx]}"
        state="${EXPECTED_STATES[$((RANDOM % 2))]}"
        SELECTED_BOOLEANS+=("$bool")
        EXPECTED_STATE+=("$state")
        # eliminar de candidatos para no repetir
        unset 'BOOLEANS_CANDIDATES[$idx]'
        BOOLEANS_CANDIDATES=("${BOOLEANS_CANDIDATES[@]}")
    done

    # Mostrar resumen
    log "[+] Variables generadas para SELinux Booleans:"
    for i in "${!SELECTED_BOOLEANS[@]}"; do
        log "    ${SELECTED_BOOLEANS[$i]} -> ${EXPECTED_STATE[$i]}"
    done
}
