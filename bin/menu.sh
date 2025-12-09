#!/usr/bin/env bash
source "$(pwd)/bin/utils.sh"

show_main() {
    clear
    echo "==============================================="
    echo "      🚀 RHCSA MINI LINUX — MENÚ PRINCIPAL"
    echo "==============================================="
    echo "[t] Treinamento (Labs + VM)"
    echo "[p] Progreso" 
    echo "[c] Configuraciones"
    echo "[s] Salir"
    echo
}

while true; do
    show_main
    choice=$(get_valid_input "tpcs" "Escoge (t,p,c,s): ")
    case "${choice,,}" in
        t) bash "$(pwd)/bin/labs_menu.sh" ;;
        p) bash "$(pwd)/bin/progress.sh" ;;
        c) bash "$(pwd)/bin/config.sh" ;;
        s) exit 0 ;;
    esac
done
