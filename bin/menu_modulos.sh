#!/usr/bin/env bash
# menu_modulos.sh — devuelve MODULO_ID y MODULE_DIR_NAME y MODULO_NOMBRE
select_modulo() {
  clear
  echo "============================================================="
  echo "             RHCSA MINI LINUX — SELECCIONAR MÓDULO"
  echo "============================================================="
  echo ""
  echo "Seleccione a qué módulo pertenece el laboratorio:"
  echo ""
  echo "  1) Local Storage (LVM, FS, Mounts)"
  echo "  2) Users & Groups"
  echo "  3) Networking"
  echo "  4) Security (SELinux/Firewalld)"
  echo "  5) Containers"
  echo "  6) Scripting / Automation"
  echo ""
  echo "  0) Volver"
  echo ""
  read -rp "Digite la opción: " opc
  case "$opc" in
    1) MODULO_ID=1; MODULE_DIR_NAME="local_storage"; MODULO_NOMBRE="Local Storage" ;;
    2) MODULO_ID=2; MODULE_DIR_NAME="users_groups"; MODULO_NOMBRE="Users & Groups" ;;
    3) MODULO_ID=3; MODULE_DIR_NAME="networking"; MODULO_NOMBRE="Networking" ;;
    4) MODULO_ID=4; MODULE_DIR_NAME="security"; MODULO_NOMBRE="Security" ;;
    5) MODULO_ID=5; MODULE_DIR_NAME="containers"; MODULO_NOMBRE="Containers" ;;
    6) MODULO_ID=6; MODULE_DIR_NAME="scripting"; MODULO_NOMBRE="Scripting" ;;
    0) return 1 ;;
    *) echo "Opción inválida."; sleep 1; select_modulo; return ;;
  esac
  return 0
}
