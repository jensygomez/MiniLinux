#!/usr/bin/env bash
BASE_DIR="$HOME/MiniLinux"
DB="$BASE_DIR/data/labs_index.db"
while true; do
  clear
  echo "==============================================="
  echo "      RHCSA MINI LINUX — LABORATORIOS"
  echo "==============================================="
  echo
  if [ -f "$DB" ]; then
    printf "%-5s %-10s %-40s\n" "ID" "Módulo" "Nombre"
    printf "%-5s %-10s %-40s\n" "-----" "----------" "----------------------------------------"
    head -n 20 "$DB" | while IFS='|' read -r id modulo nombre date; do
      printf "%-5s %-10s %-40s\n" "$id" "$modulo" "$nombre"
    done
  else
    echo "(sin laboratorios registrados)"
  fi
  echo
  echo "MostrarCompleta   Adicionar   Editar   Excluir   Volver"
  echo
  read -p "Seleccione opción: " op
  case "$op" in
    MostrarCompleta|mostrar|m) "$BASE_DIR/bin/list_labs.sh"; read -p "ENTER para continuar..." ;;
    Adicionar|adicionar|a) "$BASE_DIR/bin/add_lab.sh" ;;
    Editar|editar|e) "$BASE_DIR/bin/manage_labs.sh" ;;
    Excluir|excluir|x) "$BASE_DIR/bin/manage_labs.sh" ;;
    Volver|volver|v) exit 0 ;;
    *) echo "Opción inválida"; sleep 1 ;;
  esac
done
