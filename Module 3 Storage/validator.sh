



#!/usr/bin/env bash
# validator.sh - Funciones de validación del estado del sistema



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
