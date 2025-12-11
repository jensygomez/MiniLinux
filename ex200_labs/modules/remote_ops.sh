



#!/usr/bin/env bash
# remote_ops.sh - Funciones para operaciones remotas (SSH/SCP)

set -euo pipefail
IFS=$'\n\t'

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