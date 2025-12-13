#!/usr/bin/env bash
# ex200_labs/Labs/05_selinux/lab_01_boolean/validator.sh
set -euo pipefail
IFS=$'\n\t'

# =============================================================
#  VALIDATOR REMOTO – SELINUX BOOLEANS (EX200 STYLE)
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/generator.sh"

run_remote() {
    sshpass -p "${REMOTE_PASS}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" "$1"
}

remote_validator() {

    successes=()
    errors=()

    echo "[*] Iniciando validación remota en ${REMOTE_USER}@${REMOTE_HOST}..."

    for i in "${!SELECTED_BOOLEANS[@]}"; do
        boolean="${SELECTED_BOOLEANS[$i]}"
        expected="${EXPECTED_STATES[$i]}"

        # Estado actual
        actual=$(run_remote "getsebool ${boolean} 2>/dev/null" | awk '{print $3}')

        if [[ "$actual" == "$expected" ]]; then
            successes+=("✅ ${boolean} = ${actual}")
        else
            errors+=("❌ ${boolean} = ${actual} (esperado: ${expected})")
        fi

        # Persistencia
        if [[ "$REQUIRES_PERSISTENCE" == "true" ]]; then
            persistent=$(run_remote "semanage boolean -l | awk '/^${boolean}[[:space:]]/ {print \$3}'")

            if [[ "$persistent" == "$expected" ]]; then
                successes+=("✅ Persistente: ${boolean}")
            else
                errors+=("❌ ${boolean} NO persistente (semanage)")
            fi
        fi
    done

    echo ""
    echo -e "${BLUE}==================== INFORME DE VALIDACIÓN ====================${NC}"
    echo -e "${CYAN}LAB: ${LAB_ID} – ${LAB_TITLE}${NC}"
    echo -e "${CYAN}HOST: ${REMOTE_HOST}${NC}"
    echo ""

    if [ ${#successes[@]} -gt 0 ]; then
        echo -e "${GREEN}✅ LOGROS:${NC}"
        for s in "${successes[@]}"; do
            echo "  ${s}"
        done
        echo ""
    fi

    if [ ${#errors[@]} -eq 0 ]; then
        echo -e "${GREEN}🎉 RESULTADO: APROBADO${NC}"
        echo "Todos los criterios SELinux fueron cumplidos correctamente."
    else
        echo -e "${RED}❌ RESULTADO: REPROBADO${NC}"
        echo -e "${YELLOW}FALTANTES / ERRORES:${NC}"
        for e in "${errors[@]}"; do
            echo "  ${e}"
        done
    fi

    echo -e "${BLUE}===============================================================${NC}"
}

# =============================================================
# EJECUCIÓN
# =============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    generate_lab_scenario >/dev/null
    remote_validator
fi
