#!/usr/bin/env bash
# ex200_labs/main.sh
set -euo pipefail
IFS=$'\n\t'

# ----------------------------------------------------
# 1. CARGAR MÓDULOS GENERALES
# ----------------------------------------------------
for module in modules/*.sh; do
    source "$module"
done

# En esta etapa solo cargamos:
# - config.sh
# - display.sh
# - math_utils.sh
# - utils.sh
# - remote_ops.sh
# - validator.sh


# ----------------------------------------------------
# 2. MENÚ PRINCIPAL
# ----------------------------------------------------
menu_principal() {
    while true; do
        clear
        echo "================================================="
        echo "            EX200 – SISTEMA DE LABS"
        echo "================================================="
        echo "1) Essential Tools"
        echo "2) Manage Software"
        echo "3) Storage (LVM)"
        echo "4) Networking"
        echo "5) SELinux"
        echo "0) Salir"
        echo "-------------------------------------------------"
        read -p 'Seleccione una opción: ' opcion

        case "$opcion" in
            1)
                echo "Essential Tools (en construcción)"
                read -p "ENTER para continuar..."
                ;;
            2)
                echo "Manage Software (en construcción)"
                read -p "ENTER para continuar..."
                ;;
            3)
                # Aquí SÍ llamamos al submenú Storage (pero el propio storage carga sus módulos)
                storage_menu
                ;;
            4)
                echo "Networking (en construcción)"
                read -p "ENTER para continuar..."
                ;;
            5)
                echo "SELinux (en construcción)"
                read -p "ENTER para continuar..."
                ;;
            0)
                exit 0
                ;;
            *)
                echo "Opción inválida"
                sleep 1
                ;;
        esac
    done
}

# ----------------------------------------------------
# 3. LLAMADA AL PROGRAMA PRINCIPAL
# ----------------------------------------------------
menu_principal
