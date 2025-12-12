#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# =============== MOSTRAR TICKET (USANDO VARIABLES GENERADAS) ===============
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
mostrar_ticket() {

        # Cargar colores desde config.sh si no están definidos
    if [ -z "${RED:-}" ]; then
        source ./config.sh
    fi

    
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




mostrar_instrucciones() {
    # Cargar colores desde config.sh si no están definidos
    if [ -z "${YELLOW:-}" ]; then
        source ./config.sh
    fi
    
    echo ""
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${YELLOW} INSTRUCCIONES ${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo ""
    echo -e "${GREEN}📋 Ahora debes conectarte a VM2 y realizar la tarea del ticket.${NC}"
    echo ""
    echo -e "${CYAN}Ejemplo de comandos en VM2 (student@${VM2_IP}):${NC}"
    echo " ssh student@${VM2_IP}"
    echo " sudo pvcreate /dev/loop0 /dev/loop1"
    echo " sudo vgcreate ${VG_NAME} /dev/loop0 /dev/loop1"
    echo " sudo lvcreate -n ${LV_NAME} -L ${LV_SIZE} -i 2 ${VG_NAME}"
    echo " sudo mkfs.xfs -f /dev/${VG_NAME}/${LV_NAME}"
    echo " sudo mkdir -p /var/lib/pgsql/data"
    echo " sudo mount -o noatime,nodiratime /dev/${VG_NAME}/${LV_NAME} /var/lib/pgsql/data"
    echo " echo '/dev/${VG_NAME}/${LV_NAME} /var/lib/pgsql/data xfs defaults,noatime,nodiratime 0 0' | sudo tee -a /etc/fstab"
    echo ""
    echo -e "${YELLOW}Nota: Los tamaños mostrados en el ticket son reales y deben coincidir.${NC}"
    echo ""
    echo -e "${YELLOW}================================================================${NC}"
}

