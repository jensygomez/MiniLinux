#!/usr/bin/env bash
# ex200_labs/Labs/05_selinux/lab_01_boolean/main.sh
set -euo pipefail
IFS=$'\n\t'


# =============================================================
#  EX200 LAB ORCHESTRATOR
# =============================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================
#  RESOLVER DIRECTORIO DEL LAB
# =============================================================
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================
#  CARGAR CONFIGURACIÓN Y GENERADOR
# =============================================================
source "${LAB_DIR}/config.sh"
source "${LAB_DIR}/generator.sh"

# =============================================================
#  COLORES (USO GENERAL)
# =============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =============================================================
#  FUNCIONES PRINCIPALES
# =============================================================

show_header() {
    clear
    echo -e "${BLUE}==================================================${NC}"
    echo -e "${BLUE}   EX200 LAB ENVIRONMENT${NC}"
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo -e "${BLUE} LAB:        $LAB_ID${NC}"
    echo -e "${BLUE} TITLE:      $LAB_TITLE${NC}"
    echo -e "${BLUE} LEVEL:      ${LAB_DIFFICULTY_NAME[$LAB_DIFFICULTY_LEVEL]}${NC}"
    echo -e "${BLUE} TIME LIMIT: ${TIME_LIMIT_MINUTES} minutes${NC}"
    echo -e "${BLUE}==================================================${NC}"
}

show_instructions() {
    echo ""
    echo -e "${YELLOW}INSTRUCCIONES GENERALES:${NC}"
    echo " - Resuelva el ticket presentado"
    echo " - Aplique cambios directamente en el sistema objetivo"
    echo " - No modifique scripts del laboratorio"
    if [[ "$REQUIRES_PERSISTENCE" == "true" ]]; then
        echo " - Los cambios deben ser persistentes (reinicio)"
    fi
    echo ""
    read -rp "Presione ENTER para generar el escenario..."
}

wait_for_user() {
    echo ""
    echo -e "${GREEN}⏳ Laboratorio en progreso...${NC}"
    echo "Cuando termine de aplicar los cambios:"
    read -rp "Presione ENTER para validar el laboratorio..."
}

run_ticket() {
    echo ""
    echo -e "${YELLOW}📋 Generando ticket...${NC}"
    ./ticket.sh
}

run_validation() {
    echo ""
    echo -e "${YELLOW}🔎 Ejecutando validación...${NC}"
    ./validator.sh
}

# =============================================================
#  FLUJO PRINCIPAL
# =============================================================

main() {
    show_header
    show_instructions

    generate_lab_scenario
    run_ticket
    wait_for_user
    run_validation
}

# =============================================================
#  EJECUCIÓN
# =============================================================
main
