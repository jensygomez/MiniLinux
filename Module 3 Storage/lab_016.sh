#!/usr/bin/env bash
# lab_setup_and_validate.sh
# Prepara entorno LVM (2 discos) en VM2, muestra ticket, pausa y luego valida los items del ticket.
# Uso: sudo bash lab_setup_and_validate.sh [--no-clean] [--debug]
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

CLEAN_LOCAL=true     # --no-clean para preservar las imágenes
DEBUG=0

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

log() { printf "%s\n" "$*"; }
dbg() { if [ "$DEBUG" -eq 1 ]; then printf "[DEBUG] %s\n" "$*"; fi }

require_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Ejecuta como root: sudo bash $0"
    exit 1
  fi
}

rand_from_list() { local arr=("$@"); printf "%s" "${arr[RANDOM % ${#arr[@]}]}"; }
rand_size_mb() { local range=$((MAX_MB - MIN_MB + 1)); printf "%d" $(( (RANDOM % range) + MIN_MB )); }
percent_random() { echo $(( (RANDOM % 41) + 60 )); }  # 60..100

mb_to_gb() {
  local mb=$1
  local gb=$(echo "scale=2; $mb / 1024" | bc)
  printf "%s" "$gb"
}

ensure_sshpass_local() {
  if ! command -v sshpass &>/dev/null; then
    log "[*] sshpass no encontrado en VM1 — intentando instalar..."
    if command -v apt-get &>/dev/null; then
      apt-get update -y && apt-get install -y sshpass || true
    elif command -v dnf &>/dev/null; then
      dnf install -y epel-release sshpass || true
    elif command -v yum &>/dev/null; then
      yum install -y epel-release sshpass || true
    fi
    if ! command -v sshpass &>/dev/null; then
      echo "ERROR: sshpass no pudo instalarse. Instálalo manualmente en VM1."
      exit 1
    fi
  fi
}

ensure_bc_local() {
  if ! command -v bc &>/dev/null; then
    log "[*] bc no encontrado en VM1 — intentando instalar..."
    if command -v apt-get &>/dev/null; then
      apt-get update -y && apt-get install -y bc || true
    elif command -v dnf &>/dev/null; then
      dnf install -y bc || true
    elif command -v yum &>/dev/null; then
      yum install -y bc || true
    fi
    if ! command -v bc &>/dev/null; then
      echo "ERROR: bc no pudo instalarse. Instálalo manualmente en VM1."
      exit 1
    fi
  fi
}

# =============== GENERAR VARIABLES ALEATORIAS (UNA VEZ) ===============
generate_vars() {
  # Declarar todas las variables como globales
  declare -g ID VG_NAME LV_NAME DEPARTAMENTO NOMBRE_USUARIO IMG1 IMG2
  declare -g DISK1_MB DISK2_MB DISK1_GB DISK2_GB TOTAL_MB TOTAL_GB
  declare -g LV_SIZE_MB LV_SIZE LV_SIZE_GB REMOTE_WORKDIR
  
  ID="lab-$(date +%s | sha256sum | cut -c1-6)"
  
  # Seleccionar aleatoriamente de las listas
  VG_NAME="$(rand_from_list "${VG_CANDIDATES[@]}")"
  LV_NAME="$(rand_from_list "${LV_CANDIDATES[@]}")"
  DEPARTAMENTO="$(rand_from_list "${DEPARTAMENTOS[@]}")"
  NOMBRE_USUARIO="$(rand_from_list "${USUARIOS[@]}")"
  
  # Asegurar que VG y LV no sean iguales
  [[ "$VG_NAME" == "$LV_NAME" ]] && LV_NAME="${LV_NAME}_lv"
  
  # Generar nombres de imágenes
  IMG1="d1_${ID}.img"
  IMG2="d2_${ID}.img"
  
  # Calcular tamaños de discos
  DISK1_MB=$(rand_size_mb)
  DISK2_MB=$(rand_size_mb)
  
  # Calcular tamaños en GB para display
  DISK1_GB=$(mb_to_gb "$DISK1_MB")
  DISK2_GB=$(mb_to_gb "$DISK2_MB")
  TOTAL_MB=$((DISK1_MB + DISK2_MB))
  TOTAL_GB=$(mb_to_gb "$TOTAL_MB")
  
  # Calcular tamaño del LV (60-100% del disco más pequeño)
  PCT=$(percent_random)
  if [ "$DISK1_MB" -le "$DISK2_MB" ]; then
    LV_SIZE_MB=$(( DISK1_MB * PCT / 100 ))
  else
    LV_SIZE_MB=$(( DISK2_MB * PCT / 100 ))
  fi
  LV_SIZE="${LV_SIZE_MB}M"
  LV_SIZE_GB=$(mb_to_gb "$LV_SIZE_MB")
  
  REMOTE_WORKDIR="${REMOTE_WORKDIR_BASE}_${ID}"
  
  # Mostrar resumen de variables generadas
  log "[+] Variables generadas para esta sesión:"
  log "    ID: ${ID}"
  log "    VG: ${VG_NAME}"
  log "    LV: ${LV_NAME}"
  log "    Departamento: ${DEPARTAMENTO}"
  log "    Usuario: ${NOMBRE_USUARIO}"
  log "    Disk1: ${DISK1_MB}MB (${DISK1_GB}GB)"
  log "    Disk2: ${DISK2_MB}MB (${DISK2_GB}GB)"
  log "    Total VG: ${TOTAL_MB}MB (${TOTAL_GB}GB)"
  log "    LV Size: ${LV_SIZE} (${LV_SIZE_GB}GB)"
}

# =============== MOSTRAR TICKET (USANDO VARIABLES GENERADAS) ===============
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
mostrar_ticket() {
    clear
    echo -e "${RED}=======================================================================${NC}"
    echo -e "${RED}                        🚨 TICKET #URG-${ID: -6} 🚨${NC}"
    echo -e "${RED}=======================================================================${NC}"
    echo -e "${YELLOW}PRIORIDAD: CRÍTICA | ETA: 90 MINUTOS${NC}"
    echo ""
    echo -e "${YELLOW}📋 ASUNTO: Base de datos ${DEPARTAMENTO} colapsa${NC}"
    echo -e "${YELLOW}👤 Reportado por: ${NOMBRE_USUARIO} (Jefe ${DEPARTAMENTO})${NC}"
    echo -e "${YELLOW}📧 Email: ${NOMBRE_USUARIO}@empresa.local${NC}"
    echo -e "${YELLOW}📞 Ext: $((1000 + RANDOM % 9000))${NC}"
    echo ""
    echo -e "${RED}🔥 PROBLEMA:${NC}"
    echo "La base de datos PostgreSQL de ${DEPARTAMENTO} está saturando los discos."
    echo "Los reportes mensuales tardan 45 minutos en lugar de 5 minutos."
    echo "El CFO está furioso y exige solución HOY."
    echo ""
    
    # Estado actual del sistema (usando variables generadas)
    echo -e "${BLUE}💻 ESTADO ACTUAL DE VM2 (${VM2_IP}):${NC}"
    echo -e "${CYAN}✅ Discos disponibles: /dev/loop0 (${DISK1_GB}GB) y /dev/loop1 (${DISK2_GB}GB)${NC}"
    echo -e "${RED}❌ Volume Group '${VG_NAME}' NO EXISTE aún${NC}"
    echo -e "${RED}❌ Logical Volume '${LV_NAME}' NO EXISTE aún${NC}"
    echo ""
    
    echo -e "${GREEN}💻 TAREAS PENDIENTES:${NC}"
    echo "1. Crear Physical Volumes en /dev/loop0 y /dev/loop1"
    echo "2. Crear Volume Group: ${VG_NAME} usando ambos PVs (${TOTAL_GB}GB total)"
    echo "3. Crear Logical Volume: ${LV_NAME} de tamaño ~ ${LV_SIZE} (${LV_SIZE_GB}GB)"
    echo "   - Configurar en modo STRIPED (-i2) para usar ambos discos"
    echo "4. Formatear con XFS"
    echo "5. Montar en /var/lib/pgsql/data con opciones noatime,nodiratime"
    echo "6. Agregar montaje permanente a /etc/fstab"
    echo ""
    
    echo -e "${RED}⚠️ RIESGOS:${NC}"
    echo "- Si no está striped: rendimiento no mejorará"
    echo "- Si no es XFS: riesgo de pérdida de datos"
    echo "- Espacio limitado: ${TOTAL_GB}GB disponible en total"
    echo "- Tiempo crítico: 90 minutos para solución"
    echo ""
    
    echo -e "${GREEN}✅ CRITERIOS DE ACEPTACIÓN:${NC}"
    echo "- 'sudo pvs' muestra 2 PVs (/dev/loop0 y /dev/loop1) en ${VG_NAME}"
    echo "- 'sudo vgs' confirma ${VG_NAME} con ~${TOTAL_GB}GB y espacio reducido tras crear el LV"
    echo "- 'sudo lvs' muestra ${LV_NAME} con segtype 'striped' y 2 stripes"
    echo "- 'df -T' muestra montado en /var/lib/pgsql/data con XFS"
    echo "- '/etc/fstab' contiene entrada permanente para el montaje"
    echo ""
    
    echo -e "${RED}⏰ PRESIÓN ADICIONAL:${NC}"
    echo "El Directorio Ejecutivo entra en 90 minutos a presentar resultados."
    echo "¡NO PUEDE FALLAR!"
    echo -e "${RED}=======================================================================${NC}"
}

# =============== CREAR IMÁGENES LOCALES ===============
create_local_images() {
  mkdir -p "${LOCAL_DISKS_DIR}"
  log "[+] Creando imágenes locales en ${LOCAL_DISKS_DIR}:"
  log "    ${IMG1} (${DISK1_MB} MB / ${DISK1_GB} GB)"
  log "    ${IMG2} (${DISK2_MB} MB / ${DISK2_GB} GB)"

  dd if=/dev/zero of="${LOCAL_DISKS_DIR}/${IMG1}" bs=1M count="${DISK1_MB}" status=none
  dd if=/dev/zero of="${LOCAL_DISKS_DIR}/${IMG2}" bs=1M count="${DISK2_MB}" status=none

  log "[✓] Imágenes creadas."
}

# =============== PREPARAR SCRIPT REMOTO (VM2) ===============
prepare_remote_script() {
  TMP_REMOTE_SCRIPT="/tmp/remote_setup_${ID}.sh"
  cat > "${TMP_REMOTE_SCRIPT}" <<'REMOTE_EOF'
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PASS='__VM2_PASS__'
REMOTE_DISKS_DIR='__REMOTE_DISKS_DIR__'
VG='__VG__'
IMG1='__IMG1__'
IMG2='__IMG2__'

# Información del ticket para logs
echo "[REMOTE] === INFORMACIÓN DEL TICKET ==="
echo "[REMOTE] VG a configurar: ${VG}"
echo "[REMOTE] Discos: ${IMG1}, ${IMG2}"

# Crear directorio remoto
mkdir -p "${REMOTE_DISKS_DIR}"
chmod 700 "${REMOTE_DISKS_DIR}" || true

D1="${REMOTE_DISKS_DIR}/${IMG1}"
D2="${REMOTE_DISKS_DIR}/${IMG2}"

if [ ! -f "$D1" ] || [ ! -f "$D2" ]; then
  echo "ERROR: alguna imagen no está presente en $REMOTE_DISKS_DIR"
  ls -l "$REMOTE_DISKS_DIR" || true
  exit 2
fi

# Si el VG ya existe: avisar y salir (no modificamos trabajo del alumno)
if echo "$PASS" | sudo -S vgs --noheadings -o vg_name 2>/dev/null | grep -qw "$VG"; then
  echo "[REMOTE] ⚠️ Volume Group '$VG' ya existe en el host remoto."
  echo "[REMOTE] ⚠️ NO se modificarán discos para preservar trabajo existente."
  echo "=== CURRENT VGS ==="
  echo "$PASS" | sudo -S vgs || true
  echo "=== CURRENT PVS ==="
  echo "$PASS" | sudo -S pvs || true
  exit 0
fi

echo "[REMOTE] Asociando imágenes a loop devices..."
LOOP1=$(echo "$PASS" | sudo -S losetup -f --show "$D1")
LOOP2=$(echo "$PASS" | sudo -S losetup -f --show "$D2")
echo "[REMOTE] loops creados: $LOOP1, $LOOP2"

echo "[REMOTE] Limpiando firmas previas en loops..."
echo "$PASS" | sudo -S wipefs -a "$LOOP1" || true
echo "$PASS" | sudo -S wipefs -a "$LOOP2" || true

echo "[REMOTE] ✅ Configuración base completada (discos listos para PV/VG)"
echo "=== VALIDATOR OUTPUT BEGIN ==="
echo "PV_LIST:"
echo "$PASS" | sudo -S pvs --noheadings -o pv_name,vg_name,size 2>/dev/null || true
echo "VG_LIST:"
echo "$PASS" | sudo -S vgs --noheadings -o vg_name,vg_size,vg_free 2>/dev/null || true
echo "=== VALIDATOR OUTPUT END ==="
REMOTE_EOF

  sed -i "s|__VM2_PASS__|${VM2_PASS}|g" "${TMP_REMOTE_SCRIPT}"
  sed -i "s|__REMOTE_DISKS_DIR__|${REMOTE_DISKS_DIR}|g" "${TMP_REMOTE_SCRIPT}"
  sed -i "s|__VG__|${VG_NAME}|g" "${TMP_REMOTE_SCRIPT}"
  sed -i "s|__IMG1__|${IMG1}|g" "${TMP_REMOTE_SCRIPT}"
  sed -i "s|__IMG2__|${IMG2}|g" "${TMP_REMOTE_SCRIPT}"

  chmod +x "${TMP_REMOTE_SCRIPT}"
  dbg "Script remoto preparado: ${TMP_REMOTE_SCRIPT}"
}

# =============== DEPLOY Y EJECUCIÓN REMOTA ===============
deploy_and_execute_remote() {
  log "[+] Preparando VM2 (${VM2_USER}@${VM2_IP})..."

  # crear directorios remotos (discos + workdir)
  sshpass -p "${VM2_PASS}" ssh -o StrictHostKeyChecking=no "${VM2_USER}@${VM2_IP}" \
    "mkdir -p ${REMOTE_DISKS_DIR} && chmod 700 ${REMOTE_DISKS_DIR} && mkdir -p ${REMOTE_WORKDIR} && chmod 700 ${REMOTE_WORKDIR}" || {
    echo "ERROR: no se pudieron crear directorios en VM2"
    exit 3
  }

  log "[+] Copiando imágenes a VM2..."
  sshpass -p "${VM2_PASS}" scp -o StrictHostKeyChecking=no "${LOCAL_DISKS_DIR}/${IMG1}" "${VM2_USER}@${VM2_IP}:${REMOTE_DISKS_DIR}/" || { echo "ERROR scp img1"; exit 4; }
  sshpass -p "${VM2_PASS}" scp -o StrictHostKeyChecking=no "${LOCAL_DISKS_DIR}/${IMG2}" "${VM2_USER}@${VM2_IP}:${REMOTE_DISKS_DIR}/" || { echo "ERROR scp img2"; exit 4; }

  log "[+] Subiendo script remoto y ejecutando..."
  sshpass -p "${VM2_PASS}" scp -o StrictHostKeyChecking=no "${TMP_REMOTE_SCRIPT}" "${VM2_USER}@${VM2_IP}:${REMOTE_WORKDIR}/remote_setup.sh" || { echo "ERROR scp remote script"; exit 5; }

  # ejecutar remoto y mostrar salida (incluye VALIDATOR OUTPUT)
  sshpass -p "${VM2_PASS}" ssh -o StrictHostKeyChecking=no "${VM2_USER}@${VM2_IP}" \
    "chmod +x ${REMOTE_WORKDIR}/remote_setup.sh && bash ${REMOTE_WORKDIR}/remote_setup.sh" || {
    echo "ERROR: ejecución remota fallida"
    exit 6
  }
}

# =============== GUARDAR JSON ===============
save_json() {
  JSON_FILE="${SAVE_JSON_DIR}/last_lab_${ID}.json"
  cat > "${JSON_FILE}" <<-JSON
{
  "id": "${ID}",
  "departamento": "${DEPARTAMENTO}",
  "usuario": "${NOMBRE_USUARIO}",
  "vg": "${VG_NAME}",
  "lv": "${LV_NAME}",
  "lv_size_mb": ${LV_SIZE_MB},
  "lv_size": "${LV_SIZE}",
  "img1": "${LOCAL_DISKS_DIR}/${IMG1}",
  "img2": "${LOCAL_DISKS_DIR}/${IMG2}",
  "disk1_mb": ${DISK1_MB},
  "disk2_mb": ${DISK2_MB},
  "disk1_gb": "${DISK1_GB}",
  "disk2_gb": "${DISK2_GB}",
  "total_mb": ${TOTAL_MB},
  "total_gb": "${TOTAL_GB}",
  "vm2_ip": "${VM2_IP}",
  "vm2_user": "${VM2_USER}",
  "remote_dir": "${REMOTE_DISKS_DIR}",
  "remote_workdir": "${REMOTE_WORKDIR}"
}
JSON
  log "[+] Variables guardadas en ${JSON_FILE}"
  log "[+] Para consultar: cat ${JSON_FILE}"
}

# =============== LIMPIEZA LOCAL ===============
cleanup_local() {
  if [ "${CLEAN_LOCAL}" = true ]; then
    log "[+] Limpiando imágenes locales..."
    rm -f "${LOCAL_DISKS_DIR}/${IMG1}" "${LOCAL_DISKS_DIR}/${IMG2}" || true
  else
    log "[+] --no-clean activado: preservando imágenes en ${LOCAL_DISKS_DIR}"
  fi
  rm -f "${TMP_REMOTE_SCRIPT}" || true
}

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
  clear
  mostrar_ticket
  
  echo ""
  echo -e "${YELLOW}================================================================${NC}"
  echo -e "${YELLOW}                         INSTRUCCIONES                          ${NC}"
  echo -e "${YELLOW}================================================================${NC}"
  echo ""
  echo -e "${GREEN}📋 Ahora debes conectarte a VM2 y realizar la tarea del ticket.${NC}"
  echo ""
  echo -e "${CYAN}Ejemplo de comandos en VM2 (student@${VM2_IP}):${NC}"
  echo "  ssh student@${VM2_IP}"
  echo "  sudo pvcreate /dev/loop0 /dev/loop1"
  echo "  sudo vgcreate ${VG_NAME} /dev/loop0 /dev/loop1"
  echo "  sudo lvcreate -n ${LV_NAME} -L ${LV_SIZE} -i 2 ${VG_NAME}"
  echo "  sudo mkfs.xfs -f /dev/${VG_NAME}/${LV_NAME}"
  echo "  sudo mkdir -p /var/lib/pgsql/data"
  echo "  sudo mount -o noatime,nodiratime /dev/${VG_NAME}/${LV_NAME} /var/lib/pgsql/data"
  echo "  echo '/dev/${VG_NAME}/${LV_NAME} /var/lib/pgsql/data xfs defaults,noatime,nodiratime 0 0' | sudo tee -a /etc/fstab"
  echo ""
  echo -e "${YELLOW}Nota: Los tamaños mostrados en el ticket son reales y deben coincidir.${NC}"
  echo ""
  echo -e "${YELLOW}================================================================${NC}"
  read -p "Cuando termines la tarea en VM2 presiona ENTER para ejecutar el validador: " _ENTER
  echo ""
  echo -e "${YELLOW}================================================================${NC}"
  
  clear
  # Ejecutar validador remoto
  remote_validator
  
  log "================================================"
  log "✅ Proceso completado."
  log "📊 Revisa el informe de validación anterior."
}

main "$@"