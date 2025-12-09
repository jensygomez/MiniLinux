#!/usr/bin/env bash

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$BASE/bin"

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
    # leemos 1 carácter
    read -p "Escoge (t,p,c,s): " -n1 choice
    echo
    case "${choice,,}" in
        t)
            bash "./labs_menu.sh"
            ;;
        p)
            bash "$BIN/progress.sh"
            ;;
        c)
            bash "$BIN/config.sh"
            ;;
        s)
            exit 0
            ;;
        *)
            echo "❌ Opción inválida. Usa: t, p, c o s"
            sleep 1
            ;;
    esac
done
