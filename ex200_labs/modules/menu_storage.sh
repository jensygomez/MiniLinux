#!/usr/bin/env bash
# ex200_labs/Labs/03_storage/menu_storage.sh
set -euo pipefail
IFS=$'\n\t'


# =============================================================
#   RESOLVER RUTA RAÍZ DEL PROYECTO
# =============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../" && pwd)"



# =============================================================
#   CARGA DINÁMICA DE MÓDULOS AL INICIAR STORAGE
# =============================================================
storage_load_modules() {
    # Cargar LVM labs
    source "${SCRIPT_DIR}/crear_pv.sh"
    source "${SCRIPT_DIR}/crear_vg.sh"
    source "${SCRIPT_DIR}/crear_lv.sh"
    source "${SCRIPT_DIR}/expandir_lv_fs.sh"
    source "${SCRIPT_DIR}/reducir_lv_fs.sh"
    source "${SCRIPT_DIR}/migrar_pvmove.sh"

    # Cargar módulos comunes
    source "${ROOT_DIR}/modules/math_utils.sh"
    source "${ROOT_DIR}/modules/utils.sh"
}

# =============================================================
#   MENÚ STORAGE
# =============================================================
storage_menu() {

    # 1. Cargar módulos necesarios SOLO al acceder al menú
    storage_load_modules

    # 2. Ejecutar menú
    while true; do
        clear
        echo "========================================="
        echo "             STORAGE - LABS"
        echo "========================================="
        echo "1) Crear Physical Volumes"
        echo "2) Crear Volume Group"
        echo "3) Crear Logical Volume"
        echo "4) Expandir LV + FS"
        echo "5) Reducir LV + FS (avanzado)"
        echo "6) Migración de discos con pvmove"
        echo "0) Volver"
        echo "-----------------------------------------"
        read -p "Seleccione una opción: " opcion_storage

        case "$opcion_storage" in
            1) storage__crear_pv ;;
            2) storage__crear_vg ;;
            3) storage__crear_lv ;;
            4) storage__expandir_lv_fs ;;
            5) storage__reducir_lv_fs ;;
            6) storage__migrar_pvmove ;;
            0) return ;;
            *) 
                echo "Opción inválida"
                sleep 1 
                ;;
        esac

        echo
        read -p "Presione ENTER para continuar..."
    done
}
