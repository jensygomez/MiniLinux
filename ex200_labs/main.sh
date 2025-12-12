#!/usr/bin/env bash
# ex200_labs/main.sh
# Menú principal del proyecto EX200 Labs

set -euo pipefail
IFS=$'\n\t'

# =====================================================
#   1. Determinar la ruta del proyecto (PROJECT_ROOT)
# =====================================================
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =====================================================
#   2. Cargar TODOS los módulos automáticamente
# =====================================================
for module in "${PROJECT_ROOT}"/modules/*.sh; do
    # Evitar cargar archivos vacíos
    [ -s "$module" ] && source "$module"
done

# =====================================================
#   3. Cargar submódulos de Labs si existen
# =====================================================
for module in "${PROJECT_ROOT}"/Labs/*/*.sh; do
    [ -s "$module" ] && source "$module"
done

# =====================================================
#   4. MENU PRINCIPAL
# =====================================================
menu_principal() {
    while true; do
        clear
        echo "========================================="
        echo "        EX200 - LABS PRINCIPALES"
        echo "========================================="
        echo "1) Essential Tools"
        echo "2) Manage Software"
        echo "3) Storage"
        echo "4) Networking"
        echo "5) SELinux"
        echo "0) Salir"
        echo "-----------------------------------------"
        echo -n "Seleccione una opción: "
        read opcion

        case "$opcion" in
            1) menu_essential ;;
            2) menu_software ;;
            3) menu_storage ;;   # <<< viene del submenú Storage
            4) menu_networking ;;
            5) menu_selinux ;;
            0) exit 0 ;;
            *)
                echo "Opción inválida..."
                sleep 1
                ;;
        esac
    done
}

menu_principal
