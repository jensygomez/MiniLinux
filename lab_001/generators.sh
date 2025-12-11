

#!/usr/bin/env bash
# generators.sh - Funciones para generar valores aleatorios

source ./library/math_utils.sh


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

