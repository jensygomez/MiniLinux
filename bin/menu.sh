#!/usr/bin/env bash

BASE_DIR="$HOME/MiniLinux"

while true; do
    clear
    echo "==============================================="
    echo "      RHCSA MINI LINUX — MENU PRINCIPAL"
    echo "==============================================="
    echo "1) Laboratórios"
    echo "2) Ver Progreso"
    echo "5) Configuraciones"
    echo "6) Sair"
    echo 
    read -p "Seleccione opción: " op

    case "$op" in
        1) "$BASE_DIR/bin/menu_labs.sh" ;;
        2) "$BASE_DIR/bin/show_progress.sh" ;;
        5) "$BASE_DIR/bin/menu_config.sh" ;;
        6) exit 0 ;;
        *) echo "Opción inválida"; sleep 1 ;;
    esac
done
