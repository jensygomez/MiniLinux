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



# =============== GENERAR VARIABLES ALEATORIAS (UNA VEZ) ===============









# =============== VALIDADOR REMOTO MEJORADO ===============
remote_validator() {
  log "[*] Iniciando validación remota en ${VM2_USER}@${VM2_IP}..."
  
  # DEBUG: Verificar que las variables tienen valores
  echo "[DEBUG] VG_NAME='${VG_NAME}', LV_NAME='${LV_NAME}'"
  
  if [ -z "${VG_NAME}" ] || [ -z "${LV_NAME}" ]; then
    echo -e "${RED}❌ ERROR: Variables VG_NAME o LV_NAME están vacías${NC}"
    echo "Esto indica que las variables no se pasaron correctamente a esta función."
    return 1
  fi
  
  # Evaluación
  errors=()
  successes=()

  # 1) Verificar PVs
  PV_INFO=$(sshpass -p "${VM2_PASS}" ssh -o StrictHostKeyChecking=no "${VM2_USER}@${VM2_IP}" \
    "echo '${VM2_PASS}' | sudo -S pvs --noheadings -o pv_name,vg_name 2>/dev/null | grep '${VG_NAME}' || true")
  
  PV1=$(echo "$PV_INFO" | grep -c '/dev/loop0' || true)
  PV2=$(echo "$PV_INFO" | grep -c '/dev/loop1' || true)
  
  if [ "$PV1" -ge 1 ] && [ "$PV2" -ge 1 ]; then
    successes+=("✅ 2 PVs (/dev/loop0 y /dev/loop1) en VG '${VG_NAME}'")
  else
    errors+=("❌ PVs incompletos en '${VG_NAME}' (esperados: /dev/loop0 y /dev/loop1)")
  fi

  # 2) Verificar VG existe
  VG_EXIST=$(sshpass -p "${VM2_PASS}" ssh -o StrictHostKeyChecking=no "${VM2_USER}@${VM2_IP}" \
    "echo '${VM2_PASS}' | sudo -S vgs --noheadings -o vg_name 2>/dev/null | grep -w '${VG_NAME}' || true")
  
  if [ -n "$VG_EXIST" ]; then
    successes+=("✅ VG '${VG_NAME}' existe")
  else
    errors+=("❌ VG '${VG_NAME}' NO existe")
  fi

  # 3) Verificar LV existe
  LV_EXIST=$(sshpass -p "${VM2_PASS}" ssh -o StrictHostKeyChecking=no "${VM2_USER}@${VM2_IP}" \
    "echo '${VM2_PASS}' | sudo -S lvs --noheadings -o lv_name ${VG_NAME} 2>/dev/null | grep -w '${LV_NAME}' || true")
  
  if [ -n "$LV_EXIST" ]; then
    successes+=("✅ LV '${LV_NAME}' existe en VG '${VG_NAME}'")
  else
    errors+=("❌ LV '${LV_NAME}' NO existe en VG '${VG_NAME}'")
  fi

  # 4) Obtener segtype y stripes
  LV_INFO=$(sshpass -p "${VM2_PASS}" ssh -o StrictHostKeyChecking=no "${VM2_USER}@${VM2_IP}" \
    "echo '${VM2_PASS}' | sudo -S lvs --noheadings -o segtype,stripes ${VG_NAME}/${LV_NAME} 2>/dev/null || true")
  
  SEGTYPE=$(echo "$LV_INFO" | awk '{print $1}' | tr -d '[:space:]')
  STRIPES=$(echo "$LV_INFO" | awk '{print $2}' | tr -d '[:space:]')

  if [ -n "$SEGTYPE" ] && [ "$SEGTYPE" != "LV" ]; then
    if [ "$SEGTYPE" = "striped" ]; then
      successes+=("✅ segtype = striped")
    else
      errors+=("❌ segtype = '$SEGTYPE' (esperado: 'striped')")
    fi
    
    if [ "$STRIPES" = "2" ]; then
      successes+=("✅ stripes = 2")
    else
      errors+=("❌ stripes = '$STRIPES' (esperado: 2)")
    fi
  else
    errors+=("❌ No se pudo obtener segtype/stripes")
  fi

  # 5) Filesystem type
  BLKID_OUT=$(sshpass -p "${VM2_PASS}" ssh -o StrictHostKeyChecking=no "${VM2_USER}@${VM2_IP}" \
    "echo '${VM2_PASS}' | sudo -S blkid /dev/${VG_NAME}/${LV_NAME} 2>/dev/null || true")
  
  if echo "$BLKID_OUT" | grep -qi 'TYPE="xfs"'; then
    successes+=("✅ Filesystem: XFS")
  else
    errors+=("❌ Filesystem NO es XFS")
  fi

  # 6) Mount point
  MOUNT_OUT=$(sshpass -p "${VM2_PASS}" ssh -o StrictHostKeyChecking=no "${VM2_USER}@${VM2_IP}" \
    "mount 2>/dev/null | grep '/var/lib/pgsql/data' || true")
  
  if echo "$MOUNT_OUT" | grep -q '/var/lib/pgsql/data'; then
    if echo "$MOUNT_OUT" | grep -q "noatime" && echo "$MOUNT_OUT" | grep -q "nodiratime"; then
      successes+=("✅ Montado en /var/lib/pgsql/data con noatime,nodiratime")
    else
      errors+=("❌ Montado pero SIN opciones noatime,nodiratime")
    fi
  else
    errors+=("❌ NO está montado en /var/lib/pgsql/data")
  fi

  # 7) fstab
  FSTAB_OUT=$(sshpass -p "${VM2_PASS}" ssh -o StrictHostKeyChecking=no "${VM2_USER}@${VM2_IP}" \
    "grep -F '/dev/${VG_NAME}/${LV_NAME}' /etc/fstab 2>/dev/null || true")
  
  if [ -n "$FSTAB_OUT" ]; then
    successes+=("✅ Entrada encontrada en /etc/fstab")
  else
    errors+=("❌ NO hay entrada en /etc/fstab")
  fi

  # Resultado final
  echo ""
  echo -e "${BLUE}==================== INFORME DE VALIDACIÓN ====================${NC}"
  echo -e "${CYAN}Ticket ID: ${ID}${NC}"
  echo -e "${CYAN}VG: ${VG_NAME}, LV: ${LV_NAME}${NC}"
  echo ""
  
  if [ ${#successes[@]} -gt 0 ]; then
    echo -e "${GREEN}✅ LOGROS:${NC}"
    for s in "${successes[@]}"; do
      echo "  ${s}"
    done
    echo ""
  fi
  
  if [ ${#errors[@]} -eq 0 ]; then
    echo -e "${GREEN}🎉 RESULTADO: APROBADO${NC}"
    echo "Todos los criterios del ticket fueron cumplidos correctamente."
  else
    echo -e "${RED}❌ RESULTADO: REPROBADO${NC}"
    echo -e "${YELLOW}FALTANTES / ERRORES:${NC}"
    for e in "${errors[@]}"; do
      echo "  ${e}"
    done
  fi
  echo -e "${BLUE}===============================================================${NC}"
}

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