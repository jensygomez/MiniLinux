#!/usr/bin/env bash
DB="$HOME/MiniLinux/data/labs_index.db"
if [ ! -f "$DB" ]; then echo "No hay labs."; exit 0; fi
clear
echo "LISTA DE LABS (index)"
echo "---------------------------------"
nl -ba "$DB" | sed 's/^/    /'
echo
read -p "ENTER para volver..."
