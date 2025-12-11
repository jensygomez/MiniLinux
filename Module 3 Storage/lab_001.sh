#!/usr/bin/env bash
# lab_setup_and_validate.sh
# Prepara entorno LVM (2 discos) en VM2, muestra ticket, pausa y luego valida los items del ticket.
# Uso: sudo bash lab_setup_and_validate.sh [--no-clean] [--debug]
set -euo pipefail
IFS=$'\n\t'


# =============== CARGAR CONFIGURACIÓN ===============
source ./config.sh
source ./utils.sh
source ./generators.sh
source ./display.sh
source ./disk_ops.sh
source ./remote_ops.sh


# =============== VARIABLES GLOBALES ===============
# Estas se llenarán en generate_vars()
ID=""
VG_NAME=""
LV_NAME=""
DEPARTAMENTO=""
NOMBRE_USUARIO=""
IMG1=""
IMG2=""
DISK1_MB=0
DISK2_MB=0
DISK1_GB=""
DISK2_GB=""
TOTAL_MB=0
TOTAL_GB=""
LV_SIZE_MB=0
LV_SIZE=""
LV_SIZE_GB=""
REMOTE_WORKDIR=""

# =============== ARRAYS PARA VARIABLES ALEATORIAS ===============
# Listas de nombres
VG_CANDIDATES=(vg_system vg_backup vg_data vg_app vg_servidor vg_web vg_temp vg_qa)
LV_CANDIDATES=(lv_root lv_swap lv_production lv_cache lv_home lv_logs lv_metadata lv_config)
DEPARTAMENTOS=("FINANZAS" "RRHH" "VENTAS" "IT" "OPERACIONES" "MARKETING" "LOGISTICA")
USUARIOS=("ana" "carlos" "luis" "maria" "juan" "sofia" "pedro" "laura")

# Rango de tamaños
MIN_MB=512
MAX_MB=3072

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --no-clean) CLEAN_LOCAL=false ;;
    --debug) DEBUG=1 ;;
    *) ;;
  esac
done













# =============== MAIN ===============
main() {
  require_root
  ensure_sshpass_local
  ensure_bc_local
  
  log "🚀 Iniciando generación de entorno de prácticas..."
  log "================================================"
  
  # Generar todas las variables UNA VEZ
  generate_vars
  
  # Crear imágenes locales
  create_local_images
  
  # Desplegar setup remoto en VM2
  prepare_remote_script
  deploy_and_execute_remote
  
  # Guardar configuración
  save_json
  
  # Limpiar local si se requiere
  cleanup_local
  
  # Mostrar ticket al usuario
  mostrar_ticket
  read -p "Si deseas ver las intrucciones presiona ENTER: " _ENTER
  clear
  mostrar_instrucciones
  read -p "Cuando termines la tarea en VM2 presiona ENTER para ejecutar el validador: " _ENTER
  echo ""
  echo -e "${YELLOW}================================================================${NC}"
  clear
  
 
}

main "$@"