#!/usr/bin/env bash
# ex200_labs/modules/config.sh
set -euo pipefail
IFS=$'\n\t'



# =============== CONFIGURACIÓN ===============
VM2_IP="192.168.122.110"
VM2_USER="student"
VM2_PASS="redhat"

LOCAL_DISKS_DIR="/root/disks"
REMOTE_DISKS_DIR="/home/${VM2_USER}/disks"
REMOTE_WORKDIR_BASE="/tmp/lab_remote"
SAVE_JSON_DIR="/root"


# =============== ARRAYS PARA VARIABLES ALEATORIAS ===============
# Listas de nombres
VG_CANDIDATES=(vg_system vg_backup vg_data vg_app vg_servidor vg_web vg_temp vg_qa)
LV_CANDIDATES=(lv_root lv_swap lv_production lv_cache lv_home lv_logs lv_metadata lv_config)
DEPARTAMENTOS=("FINANZAS" "RRHH" "VENTAS" "IT" "OPERACIONES" "MARKETING" "LOGISTICA")
USUARIOS=("ana" "carlos" "luis" "maria" "juan" "sofia" "pedro" "laura")

# Rango de tamaños
MIN_MB=512
MAX_MB=3072

# Colores para display
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
