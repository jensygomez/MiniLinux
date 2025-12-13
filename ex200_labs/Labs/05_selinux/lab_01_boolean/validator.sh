#!/usr/bin/env bash
# ex200_labs/Labs/05_selinux/lab_01_boolean/validator.sh
set -euo pipefail
IFS=$'\n\t'

# =============================================================
# CARGAR CONFIGURACIÓN
# =============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# =============================================================
# FUNCIONES AUXILIARES
# =============================================================

# Función para ejecutar comandos remotos en VM2
run_remote() {
    local cmd="$1"
    sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" "$cmd"
}

# Función para validar un boolean
validate_boolean() {
    local boolean_name="$1"
    local expected_state="$2"
    
    local actual_state
    actual_state=$(run_remote "getsebool ${boolean_name}" | awk '{print $3}')
    
    if [[ "$actual_state" == "$expected_state" ]]; then
        echo "✅ Boolean ${boolean_name}: ${actual_state} (OK)"
        return 0
    else
        echo "❌ Boolean ${boolean_name}: ${actual_state} (Expected: ${expected_state})"
        return 1
    fi
}

# =============================================================
# VALIDACIÓN DEL LABORATORIO
# =============================================================
run_validation() {
    echo "==================================================="
    echo "VALIDACIÓN LAB: $LAB_ID - $LAB_TITLE"
    echo "---------------------------------------------------"

    local failures=0
    for i in "${!SELECTED_BOOLEANS[@]}"; do
        boolean="${SELECTED_BOOLEANS[$i]}"
        expected="${EXPECTED_STATE[$i]}"
        if ! validate_boolean "$boolean" "$expected"; then
            ((failures++))
        fi
    done

    echo "---------------------------------------------------"
    if [[ $failures -eq 0 ]]; then
        echo "🎉 RESULTADO: APROBADO - Todos los booleanos correctos"
    else
        echo "⚠ RESULTADO: FALLIDO - $failures booleanos incorrectos"
    fi
    echo "==================================================="
}

# =============================================================
# EJECUCIÓN
# =============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_validation
fi
