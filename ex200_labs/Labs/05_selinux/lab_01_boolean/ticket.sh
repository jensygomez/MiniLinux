#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# =============== MOSTRAR TICKET SELINUX BOOLEANS ===============
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
mostrar_ticket() {

    # Cargar variables dinámicas si no están definidas
    if [ -z "${LAB_ID:-}" ]; then
        source ./config.sh
    fi

    clear
    echo -e "${RED}=======================================================================${NC}"
    echo -e "${RED}                        🚨 TICKET #SEL-${LAB_ID: -6} 🚨${NC}"
    echo -e "${RED}=======================================================================${NC}"
    echo -e "${YELLOW}PRIORIDAD: CRÍTICA | ETA: 45 MINUTOS${NC}"
    echo ""
    echo -e "${YELLOW}📋 ASUNTO: Configuración SELinux Booleans${NC}"
    echo -e "${YELLOW}👤 Reportado por: Seguridad TI${NC}"
    echo ""
    echo -e "${RED}🔥 PROBLEMA:${NC}"
    echo "Algunos servicios críticos no funcionan correctamente debido a SELinux Booleans mal configurados."
    echo ""
    echo -e "${BLUE}💻 ESTADO ACTUAL DE VM2 (${REMOTE_HOST}):${NC}"
    for i in "${!SELECTED_BOOLEANS[@]}"; do
        echo -e "${CYAN}❌ ${SELECTED_BOOLEANS[$i]} = DESCONOCIDO${NC}"
    done
    echo ""
    echo -e "${GREEN}💻 TAREAS PENDIENTES:${NC}"
    for i in "${!SELECTED_BOOLEANS[@]}"; do
        echo "1.$((i+1)) Ajustar boolean: ${SELECTED_BOOLEANS[$i]} → ${EXPECTED_STATE[$i]}"
    done
    echo ""
    echo -e "${GREEN}✅ CRITERIOS DE ACEPTACIÓN:${NC}"
    for i in "${!SELECTED_BOOLEANS[@]}"; do
        echo "- 'getsebool ${SELECTED_BOOLEANS[$i]}' devuelve ${EXPECTED_STATE[$i]}"
    done
    echo ""
    echo -e "${RED}⏰ PRESIÓN ADICIONAL:${NC}"
    echo "Tiempo límite: 45 minutos. Cambios deben persistir tras reinicio."
    echo -e "${RED}=======================================================================${NC}"
}
