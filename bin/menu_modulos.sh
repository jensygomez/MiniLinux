# Para importar desde cualquier lugar copia esta linea:
# source "$HOME/MiniLinux/bin/menu_modulos.sh"
# select_modulo
# echo "Seleccionado: $MODULO_ID - $MODULO_NOMBRE"


#!/bin/bash

# ===============================================================
#  RHCSA MINI LINUX — MENÚ DE MÓDULOS
#  Este menú es reutilizado por: add_lab, edit_lab, filtros, etc.
# ===============================================================

select_modulo() {

    clear
    echo "============================================================="
    echo "             RHCSA MINI LINUX — SELECCIONAR MÓDULO"
    echo "============================================================="
    echo ""
    echo "Seleccione a qué módulo pertenece el laboratorio:"
    echo ""
    echo "  1) Essential Tools"
    echo "  2) Operating Running Systems"
    echo "  3) Configuring Local Storage (LVM, FS, Mounts)"
    echo "  4) Creating, Deploying, Configuring, and Maintaining Systems"
    echo "  5) Managing Users and Groups"
    echo "  6) Managing Security"
    echo ""
    echo "  0) Volver"
    echo ""

    read -rp "Digite la opción: " opc

    case "$opc" in
        1) MODULO_ID=1; MODULO_NOMBRE="Essential Tools" ;;
        2) MODULO_ID=2; MODULO_NOMBRE="Operating Running Systems" ;;
        3) MODULO_ID=3; MODULO_NOMBRE="Configuring Local Storage" ;;
        4) MODULO_ID=4; MODULO_NOMBRE="Creating, Deploying, Configuring, and Maintaining Systems" ;;
        5) MODULO_ID=5; MODULO_NOMBRE="Managing Users and Groups" ;;
        6) MODULO_ID=6; MODULO_NOMBRE="Managing Security" ;;
        0) return 1 ;;  # Cancelar
        *)
            echo ""
            echo "Opción inválida."
            sleep 1
            select_modulo
            return
            ;;
    esac

    return 0
}

