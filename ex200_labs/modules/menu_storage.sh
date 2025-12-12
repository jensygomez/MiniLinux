#!/usr/bin/env bash
# ex200_labs/modules/menu_storage.sh
set -euo pipefail
IFS=$'\n\t'

# =============================================================
# DEFINIR ROOT_DIR
# =============================================================
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# =============================================================
# CARGA DINÁMICA DE MÓDULOS
# =============================================================
storage_load_modules() {

    source "${ROOT_DIR}/modules/config.sh"
    source "${ROOT_DIR}/modules/utils.sh"
    source "${ROOT_DIR}/modules/math_utils.sh"
    source "${ROOT_DIR}/modules/display.sh"
    source "${ROOT_DIR}/modules/remote_ops.sh"
    source "${ROOT_DIR}/modules/validator.sh"
    source "${ROOT_DIR}/modules/generators/lvm_generator.sh"
}

# =============================================================
# MENÚ STORAGE
# =============================================================
storage_menu() {

    storage_load_modules

    while true; do
        clear
        echo "========================================="
        echo "               STORAGE - LABS"
        echo "========================================="
        echo "1) Crear Physical Volumes"
        echo "2) Crear Volume Group"
        echo "3) Crear Logical Volume"
        echo "4) Expandir LV + FS"
        echo "5) Reducir LV + FS"
        echo "6) Migración con pvmove"
        echo "0) Volver al menú principal"
        echo "-----------------------------------------"
        read -p "Seleccione una opción: " opcion_storage

        case "$opcion_storage" in
            1)
                source "${ROOT_DIR}/Labs/03_storage/crear_pv.sh"
                storage__crear_pv
                ;;
            2)
                source "${ROOT_DIR}/Labs/03_storage/crear_vg.sh"
                storage__crear_vg
                ;;
            3)
                source "${ROOT_DIR}/Labs/03_storage/crear_lv.sh"
                storage__crear_lv
                ;;
            4)
                source "${ROOT_DIR}/Labs/03_storage/expandir_lv_fs.sh"
                storage__expandir_lv_fs
                ;;
            5)
                source "${ROOT_DIR}/Labs/03_storage/reducir_lv_fs.sh"
                storage__reducir_lv_fs
                ;;
            6)
                source "${ROOT_DIR}/Labs/03_storage/migrar_pvmove.sh"
                storage__migrar_pvmove
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
