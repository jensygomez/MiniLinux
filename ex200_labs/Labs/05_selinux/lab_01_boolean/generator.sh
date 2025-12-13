#!/usr/bin/env bash
# ex200_labs/Labs/05_selinux/lab_01_boolean/generator.sh


# =============================================================
#  SELINUX BOOLEAN LAB – GENERATOR
# =============================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================
#  CARGAR CONFIGURACIÓN BASE
# =============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# =============================================================
#  VARIABLES GENERADAS (EXPORTADAS)
# =============================================================
declare -g SELECTED_BOOLEANS=()
declare -g EXPECTED_STATES=()
declare -g RELATED_SERVICES=()

# =============================================================
#  FUNCIONES INTERNAS
# =============================================================

# Seleccionar booleans aleatorios sin repetir
select_random_booleans() {
    local num
    num=$(shuf -i "${MIN_BOOLEANS}-${MAX_BOOLEANS}" -n 1)

    mapfile -t SELECTED_BOOLEANS < <(
        shuf -e "${AVAILABLE_BOOLEANS[@]}" -n "$num"
    )
}

# Asignar estados esperados (on / off)
assign_expected_states() {
    EXPECTED_STATES=()
    for _ in "${SELECTED_BOOLEANS[@]}"; do
        EXPECTED_STATES+=( "$(shuf -e on off -n 1)" )
    done
}

# Resolver servicios relacionados a cada boolean
map_services() {
    RELATED_SERVICES=()

    for boolean in "${SELECTED_BOOLEANS[@]}"; do
        for entry in "${SERVICE_MAP[@]}"; do
            key="${entry%%:*}"
            value="${entry##*:}"
            if [[ "$key" == "$boolean" ]]; then
                RELATED_SERVICES+=( "$value" )
            fi
        done
    done
}

# =============================================================
#  GENERADOR PRINCIPAL
# =============================================================
generate_lab_scenario() {

    echo "==================================================="
    echo " Generando escenario SELinux Booleans"
    echo "---------------------------------------------------"
    echo " LAB:        $LAB_ID"
    echo " NIVEL:      ${LAB_DIFFICULTY_NAME[$LAB_DIFFICULTY_LEVEL]}"
    echo "==================================================="

    select_random_booleans
    assign_expected_states
    map_services

    # Resumen
    for i in "${!SELECTED_BOOLEANS[@]}"; do
        echo " - ${SELECTED_BOOLEANS[$i]} → ${EXPECTED_STATES[$i]}"
    done

    if [[ "$REQUIRE_SERVICE_VALIDATION" == "true" ]]; then
        echo " Servicios relacionados:"
        for svc in "${RELATED_SERVICES[@]}"; do
            echo "   - $svc"
        done
    fi

    echo "==================================================="
}

# =============================================================
#  AUTOEJECUCIÓN (SOLO SI SE LLAMA DIRECTAMENTE)
# =============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    generate_lab_scenario
fi
