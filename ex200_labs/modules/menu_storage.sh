#!/usr/bin/env bash
# ex200_labs/Labs/03_storage/menu_storage.sh
set -euo pipefail
IFS=$'\n\t'


#
# =============================================================
#   STORAGE MENU – CARGA DINÁMICA DE MÓDULOS SOLO AL ENTRAR
# =============================================================



# =============================================================
#   CARGA DINÁMICA DE MÓDULOS AL INICIAR STORAGE
# =============================================================
storage_load_modules() {
    source Labs/03_storage/crear_pv.sh
    source Labs/03_storage/crear_vg.sh
    source Labs/03_storage/crear_lv.sh
    source Labs/03_storage/expandir_lv_fs.sh
    source Labs/03_storage/reducir_lv_fs.sh
    source Labs/03_storage/migrar_pvmove.sh

    # Solo si los labs lo necesitan
    source modules/math_utils.sh
    source modules/utils.sh
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
