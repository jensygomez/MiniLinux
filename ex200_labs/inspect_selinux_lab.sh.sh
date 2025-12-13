#!/usr/bin/env bash
# ============================================================
#  INSPECTOR DE LABORATORIO SELINUX – EX200
#
#  Este script inspecciona la estructura y el contenido
#  de UN laboratorio SELinux específico.
#
#  Actualmente enfocado en:
#      lab_01_boolean
#
#  🔧 PARA REUTILIZAR CON OTROS LABS:
#  Cambiar únicamente la variable:
#      LAB_NAME="lab_01_boolean"
#  por:
#      lab_02_context
#      lab_03_fcontext
#      lab_04_ports
#      lab_05_enforcing
#      lab_06_troubleshooting
# ============================================================

set -euo pipefail
IFS=$'\n\t'

# ================= CONFIGURACIÓN =================
LAB_BASE_DIR="Labs/05_selinux"
LAB_NAME="lab_01_boolean"   # ← CAMBIAR AQUÍ PARA OTRO LAB
LAB_DIR="${LAB_BASE_DIR}/${LAB_NAME}"

FILES=(
  "config.sh"
  "generator.sh"
  "main.sh"
  "ticket.sh"
  "validator.sh"
)

# ================= UTILIDADES =================
print_header() {
  echo
  echo "===================================================="
  echo "   INSPECCIÓN SELINUX – ${LAB_NAME}"
  echo "===================================================="
}

print_section() {
  echo
  echo "----------------------------------------------------"
  echo "$1"
  echo "----------------------------------------------------"
}

print_error() {
  echo "✘ $1"
}

print_ok() {
  echo "✔ $1"
}

# ================= EJECUCIÓN =================
print_header

# 1. Verificar carpeta base SELinux
if [[ ! -d "${LAB_BASE_DIR}" ]]; then
  print_error "No existe ${LAB_BASE_DIR}"
  exit 1
fi
print_ok "Existe ${LAB_BASE_DIR}"

# 2. Verificar laboratorio específico
print_section "Verificando laboratorio ${LAB_NAME}"

if [[ ! -d "${LAB_DIR}" ]]; then
  print_error "No existe ${LAB_DIR}"
  exit 1
fi
print_ok "Carpeta ${LAB_NAME} existe"

# 3. Verificar y mostrar archivos
for file in "${FILES[@]}"; do
  FILE_PATH="${LAB_DIR}/${file}"

  if [[ -f "${FILE_PATH}" ]]; then
    print_ok "Archivo ${file} encontrado"
    echo
    echo ">>> CONTENIDO DE ${file}"
    echo "----------------------------------------------------"
    sed 's/^/| /' "${FILE_PATH}"
    echo "----------------------------------------------------"
  else
    print_error "Archivo ${file} NO existe"
  fi
done

# 4. Cierre
echo
echo "===================================================="
echo " INSPECCIÓN COMPLETADA PARA ${LAB_NAME}"
echo "===================================================="
