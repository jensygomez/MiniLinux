#!/usr/bin/env bash
# disk_ops.sh - Funciones para operaciones con discos/imágenes

set -euo pipefail
IFS=$'\n\t'

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