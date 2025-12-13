#!/usr/bin/env bash
# ex200_labs/modules/menu_selinux.sh
set -euo pipefail
IFS=$'\n\t'

# =============================================================
# DEFINIR ROOT_DIR DESDE ESTE MÓDULO
# =============================================================
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# =============================================================
# CARGA DINÁMICA DE MÓDULOS
# =============================================================
selinux_load_modules() {
    source "${ROOT_DIR}/modules/config.sh"
    source "${ROOT_DIR}/modules/utils.sh"
    source "${ROOT_DIR}/modules/math_utils.sh"
    source "${ROOT_DIR}/modules/display.sh"
    source "${ROOT_DIR}/modules/remote_ops.sh"
    source "${ROOT_DIR}/modules/validator.sh"
}

# =============================================================
# MENÚ PRINCIPAL DE SELINUX
# =============================================================
selinux_menu() {

    selinux_load_modules

    while true; do
        clear
        echo "========================================="
        echo "               SELINUX - LABS"
        echo "========================================="
        echo "1) Lab 01 - Boolean"
        echo "2) Lab 02 - (pendiente)"
        echo "3) Lab 03 - (pendiente)"
        echo "4) Lab 04 - (pendiente)"
        echo "5) Lab 05 - (pendiente)"
        echo "6) Lab 06 - (pendiente)"
        echo "0) Volver al menú principal"
        echo "-----------------------------------------"
        read -p "Seleccione una opción: " opcion_selinux

        case "$opcion_selinux" in
            1)
                # Lab Boolean
                source "${ROOT_DIR}/Labs/05_selinux/lab_01_boolean/generator.sh"
                generate_selinux_vars   # genera variables dinámicas
                
                source "${ROOT_DIR}/Labs/05_selinux/lab_01_boolean/config.sh"
                print_lab_config        # muestra config (opcional)

                source "${ROOT_DIR}/Labs/05_selinux/lab_01_boolean/lab.sh"
                bash lab.sh             # ejecuta el laboratorio en VM2

                source "${ROOT_DIR}/Labs/05_selinux/lab_01_boolean/ticket.sh"
                mostrar_ticket          # muestra ticket al usuario

                source "${ROOT_DIR}/Labs/05_selinux/lab_01_boolean/validator.sh"
                run_validation          # valida la VM2 contra las variables generadas
                ;;
            0)
                return
                ;;
            *)
                echo "Opción inválida"
                ;;
        esac

        echo
        read -p "Presione ENTER para continuar..."
    done
}
