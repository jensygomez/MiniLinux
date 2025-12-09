#!/usr/bin/env bash

BASE="/opt/rhcsa-mini-linux"
DATA="$BASE/data"
BIN="$BASE/bin"
LABS="$BASE/labs"

while true; do
    clear
    echo "==============================================="
    echo "      RHCSA MINI LINUX — MENU PRINCIPAL"
    echo "==============================================="
    echo "1) Listar laboratórios"
    echo "2) Adicionar novo laboratório"
    echo "3) Editar laboratório"
    echo "4) Excluir laboratório"
    echo "5) Ver progresso"
    echo "6) Sair"
    echo
    read -p "Escolha uma opção: " op

    case "$op" in
        1) bash "$BIN/list_labs.sh" ;;
        2) bash "$BIN/lab_add.sh" ;;
        3) bash "$BIN/lab_edit.sh" ;;
        4) bash "$BIN/lab_delete.sh" ;;
        5) bash "$BIN/show_progress.sh" ;;
        6) exit 0 ;;
        *) echo "Opção inválida" ; sleep 1 ;;
    esac
done
