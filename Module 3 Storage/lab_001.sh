#!/usr/bin/env bash
# lab_basic_disk.sh
# Laboratorio básico: Particionamiento y filesystem
# Nivel: Principiante
set -euo pipefail

# =============== CONFIGURACIÓN ===============
VM_IP="192.168.122.110"
VM_USER="student"
VM_PASS="redhat"

# Variables aleatorias para cada ejecución
DISK_SIZES_MB=(1024 2048 3072 4096)  # 1GB a 4GB
FILESYSTEMS=("ext4" "xfs" "ext3")
MOUNT_POINTS=("/backups" "/data" "/storage" "/archive")
DEPARTAMENTOS=("VENTAS" "RRHH" "IT" "MARKETING")
USUARIOS=("ana" "carlos" "luis" "maria" "juan" "sofia" "pedro" "laura")

# =============== VARIABLES GLOBALES ===============
ID=""
DEPARTAMENTO=""
USUARIO=""
FILESYSTEM=""
MOUNT_POINT=""
DISK_SIZE_MB=0
DISCO_DEVICE=""  # Para almacenar el dispositivo real encontrado

# =============== FUNCIONES AUXILIARES ===============
log() { printf "[+] %s\n" "$*"; }
error() { printf "[❌] %s\n" "$*" >&2; }
info() { printf "[ℹ️] %s\n" "$*"; }

rand_from_list() { 
    local arr=("$@")
    printf "%s" "${arr[RANDOM % ${#arr[@]}]}"
}

# =============== GENERAR VARIABLES ALEATORIAS ===============
generate_vars() {
    ID="lab-$(date +%s | sha256sum | cut -c1-6)"
    DEPARTAMENTO=$(rand_from_list "${DEPARTAMENTOS[@]}")
    USUARIO=$(rand_from_list "${USUARIOS[@]}")
    FILESYSTEM=$(rand_from_list "${FILESYSTEMS[@]}")
    MOUNT_POINT=$(rand_from_list "${MOUNT_POINTS[@]}")
    DISK_SIZE_MB=$(rand_from_list "${DISK_SIZES_MB[@]}")
    
    log "Variables generadas para esta sesión:"
    log "  ID: ${ID}"
    log "  Departamento: ${DEPARTAMENTO}"
    log "  Usuario: ${USUARIO}"
    log "  Filesystem: ${FILESYSTEM}"
    log "  Mount Point: ${MOUNT_POINT}"
    log "  Disk Size: ${DISK_SIZE_MB}MB ($((DISK_SIZE_MB/1024))GB)"
}

# =============== SETUP AUTOMÁTICO EN VM ===============
setup_vm_automatico() {
    log "Configurando VM automáticamente..."
    
    # Crear imagen de disco local
    local disk_name="disco_extra_${ID}.img"
    local disk_path="/tmp/${disk_name}"
    
    log "Creando disco de ${DISK_SIZE_MB}MB..."
    dd if=/dev/zero of="${disk_path}" bs=1M count=${DISK_SIZE_MB} status=none
    
    # Transferir a VM
    log "Enviando disco a ${VM_USER}@${VM_IP}..."
    sshpass -p "$VM_PASS" scp -o StrictHostKeyChecking=no \
        "${disk_path}" "${VM_USER}@${VM_IP}:/tmp/" 2>/dev/null || {
        error "No se pudo copiar disco a VM"
        return 1
    }
    
    # Configurar loop device en VM
    log "Configurando loop device en VM..."
    local loop_output=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no \
        "${VM_USER}@${VM_IP}" "
        # Limpiar loops previos del mismo lab si existen
        sudo losetup -j /tmp/${disk_name} 2>/dev/null | cut -d: -f1 | while read l; do
            sudo losetup -d \$l 2>/dev/null || true
        done
        
        # Crear nuevo loop device
        LOOP_DEV=\$(sudo losetup -f --show /tmp/${disk_name} 2>/dev/null)
        if [ -n \"\$LOOP_DEV\" ]; then
            echo \"LOOP_DEVICE=\$LOOP_DEV\"
            # Crear alias simbólico para simular /dev/sdb
            sudo ln -sf \$LOOP_DEV /tmp/simulated_sdb 2>/dev/null || true
            echo \"Disco preparado en \$LOOP_DEV (también accesible como /tmp/simulated_sdb)\"
        else
            echo \"ERROR: No se pudo crear loop device\"
            exit 1
        fi
        
        # Crear archivo de variables para el estudiante
        cat > /tmp/lab_vars_${ID}.txt << EOF
# ============ LABORATORIO ${ID} ============
DEPARTAMENTO=${DEPARTAMENTO}
USUARIO=${USUARIO}
FILESYSTEM=${FILESYSTEM}
MOUNT_POINT=${MOUNT_POINT}
DISK_SIZE_MB=${DISK_SIZE_MB}
DISCO_SUGERIDO=/tmp/simulated_sdb
# ==========================================
EOF
        echo \"Variables guardadas en /tmp/lab_vars_${ID}.txt\"
    " 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        error "Error en configuración remota"
        return 1
    fi
    
    # Extraer dispositivo loop
    DISCO_DEVICE=$(echo "$loop_output" | grep "LOOP_DEVICE=" | cut -d= -f2)
    
    # Limpiar local
    rm -f "${disk_path}"
    
    log "Setup completado. Disco disponible en VM."
    if [ -n "$DISCO_DEVICE" ]; then
        log "Dispositivo: $DISCO_DEVICE"
    fi
}

# =============== MOSTRAR TICKET ===============
mostrar_ticket() {
    clear
    cat << TICKET
╔══════════════════════════════════════════════════════════════════════╗
║                     🚨 TICKET DE SOPORTE #${ID: -6} 🚨                 ║
╠══════════════════════════════════════════════════════════════════════╣
║ ASUNTO: Espacio insuficiente para backups - ${DEPARTAMENTO}           ║
║ REPORTADO POR: ${USUARIO}                                            ║
║ PRIORIDAD: MEDIA │ FECHA: $(date '+%d/%m/%Y')                        ║
╠══════════════════════════════════════════════════════════════════════╣
║ 📋 DESCRIPCIÓN:                                                      ║
║ El departamento ${DEPARTAMENTO} necesita espacio adicional para      ║
║ almacenar backups diarios. El sistema actual está al 95% de capacidad║
║ y requiere expansión inmediata.                                      ║
║                                                                      ║
║ 💻 TAREAS REQUERIDAS:                                                ║
║ 1. Identificar disco nuevo disponible en el sistema                  ║
║ 2. Crear UNA partición primaria que use TODO el espacio del disco    ║
║ 3. Formatear la partición con sistema de archivos ${FILESYSTEM}      ║
║ 4. Montar en ${MOUNT_POINT}                                          ║
║ 5. Configurar montaje automático en /etc/fstab                       ║
║                                                                      ║
║ ✅ CRITERIOS DE ACEPTACIÓN:                                          ║
║ • 'lsblk' debe mostrar la nueva partición (ej: /dev/sdb1 o similar)  ║
║ • 'df -h' debe mostrar ${FILESYSTEM} montado en ${MOUNT_POINT}       ║
║ • '/etc/fstab' debe contener entrada permanente para el montaje      ║
║ • Punto de montaje debe existir y tener permisos 755                 ║
║                                                                      ║
║ 🔧 DISCO DISPONIBLE:                                                 ║
║ • Tamaño: ${DISK_SIZE_MB}MB ($((DISK_SIZE_MB/1024))GB)               ║
║ • Sugerencia: Usar /tmp/simulated_sdb (alias de loop device)         ║
║ • O buscar con: sudo fdisk -l | grep -A1 'Disk /dev/'                ║
╚══════════════════════════════════════════════════════════════════════╝

TICKET
}

# =============== MOSTRAR INSTRUCCIONES ===============
mostrar_instrucciones() {
    cat << INSTRUCCIONES

📌 INSTRUCCIONES PARA EL LABORATORIO:

1. Conectarse a la VM:
   ssh ${VM_USER}@${VM_IP}
   Contraseña: ${VM_PASS}

2. Ver variables del laboratorio:
   cat /tmp/lab_vars_${ID}.txt

3. Identificar el disco:
   sudo fdisk -l | grep -A1 'Disk /tmp/simulated_sdb'
   sudo lsblk

4. Particionar (ejemplo):
   sudo fdisk /tmp/simulated_sdb
     n → p → 1 → Enter → Enter → w

5. Formatear:
   sudo mkfs.${FILESYSTEM} /tmp/simulated_sdb1

6. Montar:
   sudo mkdir -p ${MOUNT_POINT}
   sudo mount /tmp/simulated_sdb1 ${MOUNT_POINT}

7. Hacer permanente:
   sudo blkid /tmp/simulated_sdb1
   sudo echo "UUID=xxx ${MOUNT_POINT} ${FILESYSTEM} defaults 0 0" >> /etc/fstab

8. Verificar:
   sudo mount -a
   df -h ${MOUNT_POINT}
   lsblk -f

💡 CONSEJO: Todos los comandos necesitan 'sudo'

INSTRUCCIONES
}

# =============== VALIDADOR ===============
validar_lab() {
    info "Iniciando validación remota..."
    
    local errores=()
    local aciertos=()
    
    # 1. Verificar partición
    local particion_info=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no \
        "${VM_USER}@${VM_IP}" "
        # Buscar partición en simulated_sdb
        if sudo lsblk -no NAME,TYPE /tmp/simulated_sdb 2>/dev/null | grep -q 'part\$'; then
            lsblk -no NAME,TYPE /tmp/simulated_sdb | grep 'part\$' | head -1
        else
            # Buscar cualquier partición reciente
            sudo lsblk -no NAME,TYPE | grep 'part\$' | tail -1
        fi
    " 2>/dev/null)
    
    local particion=$(echo "$particion_info" | awk '{print $1}')
    
    if [ -n "$particion" ]; then
        aciertos+=("✅ Partición encontrada: /dev/$particion")
    else
        errores+=("❌ No se encontró partición creada")
    fi
    
    # 2. Verificar filesystem
    if [ -n "$particion" ]; then
        local fs_check=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no \
            "${VM_USER}@${VM_IP}" "
            sudo blkid /dev/$particion 2>/dev/null | grep -o 'TYPE=\"[^\"]*\"' | cut -d'\"' -f2 || echo 'NO_FS'
        " 2>/dev/null)
        
        if [ "$fs_check" = "$FILESYSTEM" ]; then
            aciertos+=("✅ Filesystem correcto: $FILESYSTEM")
        else
            errores+=("❌ Filesystem incorrecto. Esperado: $FILESYSTEM, Encontrado: $fs_check")
        fi
    fi
    
    # 3. Verificar montaje
    local mount_check=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no \
        "${VM_USER}@${VM_IP}" "
        mount | grep '${MOUNT_POINT}' | head -1
    " 2>/dev/null)
    
    if [ -n "$mount_check" ]; then
        aciertos+=("✅ Correctamente montado en $MOUNT_POINT")
        
        # Verificar opciones de montaje
        if echo "$mount_check" | grep -q "noatime\|nodiratime"; then
            aciertos+=("✅ Opciones de montaje optimizadas")
        fi
    else
        errores+=("❌ No montado en $MOUNT_POINT")
    fi
    
    # 4. Verificar fstab
    local fstab_check=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no \
        "${VM_USER}@${VM_IP}" "
        sudo grep -E \"${MOUNT_POINT}|/dev/${particion:-xxx}\" /etc/fstab 2>/dev/null || true
    " 2>/dev/null)
    
    if [ -n "$fstab_check" ]; then
        aciertos+=("✅ Entrada encontrada en /etc/fstab")
    else
        errores+=("❌ No hay entrada en /etc/fstab")
    fi
    
    # 5. Verificar permisos
    local permisos=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no \
        "${VM_USER}@${VM_IP}" "
        sudo stat -c '%a' '${MOUNT_POINT}' 2>/dev/null || echo '000'
    " 2>/dev/null)
    
    if [ "$permisos" = "755" ] || [ "$permisos" = "750" ] || [ "$permisos" = "700" ]; then
        aciertos+=("✅ Permisos adecuados: $permisos")
    else
        errores+=("⚠️  Permisos no óptimos: $permisos (recomendado: 755)")
    fi
    
    # Mostrar resultados
    echo ""
    echo "══════════════════ VALIDACIÓN ══════════════════"
    
    for acierto in "${aciertos[@]}"; do
        echo "$acierto"
    done
    
    if [ ${#errores[@]} -gt 0 ]; then
        echo ""
        echo "❌ ERRORES ENCONTRADOS:"
        for error in "${errores[@]}"; do
            echo "  $error"
        done
        echo "════════════════════════════════════════════════"
        return 1
    else
        echo ""
        echo "🎉 ¡EXCELENTE! TODAS LAS TAREAS COMPLETADAS"
        echo "════════════════════════════════════════════════"
        
        # Mostrar filosofía profesional
        echo ""
        read -p "Presiona ENTER para ver la reflexión profesional... " _
        clear
        
        echo "═══════════════════════════════════════════════════════════════"
        echo "  💭 FILOSOFÍA TÉCNICA:"
        echo "  'DOMINAR EL DISCO ES DOMINAR EL CORAZÓN DEL SISTEMA:"
        echo "   CADA BYTE TIENE SU LUGAR Y PROPÓSITO'"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "📢 Esta filosofía representa que un administrador de sistemas"
        echo "   no solo ejecuta comandos, sino que diseña infraestructura."
        echo "   Cada partición, filesystem y punto de montaje debe tener"
        echo "   una razón de ser, anticipando necesidades futuras y"
        echo "   garantizando confiabilidad a largo plazo."
        echo ""
        echo "💼 En una entrevista técnica, esto demuestra:"
        echo "   • Visión arquitectónica, no solo ejecución"
        echo "   • Pensamiento en escalabilidad"
        echo "   • Comprensión del impacto empresarial"
        echo "   • Enfoque en infraestructura resiliente"
        echo "═══════════════════════════════════════════════════════════════"
        
        return 0
    fi
}

# =============== MAIN ===============
main() {
    echo "╔════════════════════════════════════════════════╗"
    echo "║      LABORATORIO BÁSICO - PARTICIONAMIENTO     ║"
    echo "╚════════════════════════════════════════════════╝"
    
    # Verificar dependencias
    if ! command -v sshpass &>/dev/null; then
        error "sshpass no encontrado. Instalando..."
        if command -v apt-get &>/dev/null; then
            apt-get update && apt-get install -y sshpass
        elif command -v dnf &>/dev/null; then
            dnf install -y sshpass
        elif command -v yum &>/dev/null; then
            yum install -y epel-release && yum install -y sshpass
        fi
    fi
    
    # 1. Generar variables aleatorias
    generate_vars
    
    # 2. Configurar VM automáticamente (sin preguntar)
    if setup_vm_automatico; then
        info "VM configurada exitosamente"
    else
        error "Error en configuración de VM. Continuando con validación manual..."
    fi
    
    # 3. Mostrar ticket con los valores ya configurados
    mostrar_ticket
    
    # 4. Mostrar instrucciones
    mostrar_instrucciones
    
    # 5. Esperar a que el usuario trabaje
    echo ""
    read -p "⚠️  Trabaja en la VM ahora. Presiona ENTER cuando termines para validar... " _
    
    # 6. Validar trabajo
    validar_lab
    
    # 7. Resumen final
    echo ""
    echo "╔════════════════════════════════════════════════╗"
    echo "║               RESUMEN DEL LABORATORIO          ║"
    echo "╠════════════════════════════════════════════════╣"
    echo "║ ID: $ID"
    echo "║ Departamento: $DEPARTAMENTO"
    echo "║ Filesystem: $FILESYSTEM"
    echo "║ Punto de Montaje: $MOUNT_POINT"
    echo "║ Tamaño Disco: ${DISK_SIZE_MB}MB"
    echo "║ VM: ${VM_USER}@${VM_IP}"
    echo "╚════════════════════════════════════════════════╝"
}

# Ejecutar
main "$@"