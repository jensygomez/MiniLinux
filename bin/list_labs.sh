#!/usr/bin/env bash

BASE="/opt/rhcsa-mini-linux"
DB="$BASE/data/labs_index.db"

clear
echo "LISTA DE LABORATÓRIOS"
echo "====================="
grep -v "^#" "$DB" | sed '/^\s*$/d'
echo
read -p "Pressione ENTER para voltar..."
