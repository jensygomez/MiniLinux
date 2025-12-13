#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

selinux_load_modules() {
    source "${ROOT_DIR}/modules/config.sh"
    source "${ROOT_DIR}/modules/utils.sh"
    source "${ROOT_DIR}/modules/display.sh"
    source "${ROOT_DIR}/modules/validator.sh"
}

selinux_menu() {
    selinux_load_modules

    while true; do
        clear
        echo "========================================="
        echo "             SELinux - LABS"
        echo "========================================="
        echo "1) Enforcing vs Permissive"
        echo "2) File Contexts"
        echo "3) Booleans"
        echo "4) Ports"
        echo "5) Custom Policy"
        echo "6) Troubleshooting"
        echo "0) Volver al menú principal"
        echo "-----------------------------------------"
        read -p "Seleccione una opción: " opcion_selinux

        case "$opcion_selinux" in
            1) source "${ROOT_DIR}/05_selinux/lab_01_enforcing_permissive.sh"; lab_01; source "${ROOT_DIR}/05_selinux/validator/validate_lab_01.sh"; validate_lab_01 ;;
            2) source "${ROOT_DIR}/05_selinux/lab_02_file_contexts.sh"; lab_02; source "${ROOT_DIR}/05_selinux/validator/validate_lab_02.sh"; validate_lab_02 ;;
            3) source "${ROOT_DIR}/05_selinux/lab_03_booleans.sh"; lab_03; source "${ROOT_DIR}/05_selinux/validator/validate_lab_03.sh"; validate_lab_03 ;;
            4) source "${ROOT_DIR}/05_selinux/lab_04_ports.sh"; lab_04; source "${ROOT_DIR}/05_selinux/validator/validate_lab_04.sh"; validate_lab_04 ;;
            5) source "${ROOT_DIR}/05_selinux/lab_05_custom_policy.sh"; lab_05; source "${ROOT_DIR}/05_selinux/validator/validate_lab_05.sh"; validate_lab_05 ;;
            6) source "${ROOT_DIR}/05_selinux/lab_06_troubleshooting.sh"; lab_06; source "${ROOT_DIR}/05_selinux/validator/validate_lab_06.sh"; validate_lab_06 ;;
            0) return ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac

        echo
        read -p "Presione ENTER para continuar..."
    done
}
