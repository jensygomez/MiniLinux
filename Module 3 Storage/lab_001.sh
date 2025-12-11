#!/usr/bin/env bash
# lab_basic_disk.sh - VERSIÓN CORREGIDA
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
SETUP_EXITOSO=false

# =============== FUNCIONES AUXILIARES ===============
log() { printf "[+] %s\n" "$*"; }
error() { printf "[❌] %s\n" "$*" >&2; }
info() { printf "[ℹ️] %s\n" "$*"; }
success() { printf "[✅] %s\n" "$*"; }

rand_from_list() { 
    local arr=("$@")
    printf "%s" "${arr[RANDOM % ${#arr[@]}]}"
}

verificar_conexion_vm() {
    info "Verificando conexión a VM..."
    if sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no \
        -o ConnectTimeout=5 "${VM_USER}@${VM_IP}" "echo 'Conexión OK'" &>/dev/null; then
        success "Conexión a ${VM_USER}@${VM_IP} establecida"
        return 0
    else
        error "No se pudo conectar a ${VM_USER}@${VM_IP}"
        error "Verifica:"
        error "  1. La VM está encendida"
        error "  2. La IP es correcta: $VM_IP"
        error "  3. Las credenciales: usuario=$VM_USER, password=$VM_PASS"
        return 1
    fi
}

# =============== GENERAR VARIABLES ALEATORIAS ===============
generate_vars() {
    ID="lab-$(date +%s | sha256sum | cut -c1-6)"
    DEPARTAMENTO=$(rand_from_list "${DEPARTAMENTOS[@]}")
    USUARIO=$(rand_from_list "${USUARIOS[@]}")
    FILESYSTEM=$(rand_from_list "${FILESYSTEMS[@]}")
    MOUNT_POINT=$(rand_from_list "${MOUNT_POINTS[@]}")
    DISK_SIZE_MB=$(rand_from_list "${DISK_SIZES[@]}")
    
    success "Variables generadas para esta sesión:"
    log "  🆔 ID: ${ID}"
    log "  🏢 Departamento: ${DEPARTAMENTO}"
    log "  👤 Usuario: ${USUARIO}"
    log "  💾 Filesystem: ${FILESYSTEM}"
    log "  📂 Mount Point: ${MOUNT_POINT}"
    log "  💿 Disk Size: ${DISK_SIZE_MB}MB ($((DISK_SIZE_MB/1024))GB)"
}

# =============== SETUP AUTOMÁTICO EN VM ===============
setup_vm_automatico() {
    info "Iniciando configuración automática en VM..."
    
    # Verificar conexión primero
    if ! verificar_conexion_vm; then
        error "No se puede continuar con el setup"
        SETUP_EXITOSO=false
        return 1
    fi
    
    # Crear imagen de disco local
    local disk_name="disco_extra_${ID}.img"
    local disk_path="/tmp/${disk_name}"
    
    log "Creando disco de ${DISK_SIZE_MB}MB..."
    if ! dd if=/dev/zero of="${disk_path}" bs=1M count=${DISK_SIZE_MB} status=none; then
        error "Error creando disco local"
        SETUP_EXITOSO=false
        return 1
    fi
    
    # Transferir a VM
    log "Enviando disco a ${VM_USER}@${VM_IP}..."
    if ! sshpass -p "$VM_PASS" scp -o StrictHostKeyChecking=no \
        "${disk_path}" "${VM_USER}@${VM_IP}:/tmp/" &>/dev/null; then
        error "No se pudo copiar disco a VM"
        rm -f "${disk_path}"
        SETUP_EXITOSO=false
        return 1
    fi
    
    # Configurar loop device en VM
    log "Configurando loop device en VM..."
    local setup_result=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no \
        "${VM_USER}@${VM_IP}" "
        # Limpiar setup previo si existe
        sudo losetup -d /tmp/simulated_sdb 2>/dev/null || true
        sudo rm -f /tmp/simulated_sdb 2>/dev/null || true
        
        # Buscar loop device disponible
        LOOP_DEV=\$(sudo losetup -f)
        if [ -z \"\$LOOP_DEV\" ]; then
            echo 'ERROR: No hay loop devices disponibles'
            exit 1
        fi
        
        # Asociar disco al loop device
        if ! sudo losetup \$LOOP_DEV /tmp/${disk_name}; then
            echo 'ERROR: No se pudo asociar loop device'
            exit 1
        fi
        
        # Crear enlace simbólico
        sudo ln -sf \$LOOP_DEV /tmp/simulated_sdb
        
        # Particionar (crear tabla de particiones y una partición)
        echo -e 'o\\nn\\np\\n1\\n\\n\\nw' | sudo fdisk \$LOOP_DEV >/dev/null 2>&1
        
        # Actualizar tabla de particiones
        sudo partprobe \$LOOP_DEV 2>/dev/null || true
        
        # Crear archivo de variables
        cat > /tmp/lab_vars_${ID}.txt << EOF
# ============ LABORATORIO ${ID} ============
DEPARTAMENTO=${DEPARTAMENTO}
USUARIO=${USUARIO}
FILESYSTEM=${FILESYSTEM}
MOUNT_POINT=${MOUNT_POINT}
DISK_SIZE_MB=${DISK_SIZE_MB}
DISCO_PRINCIPAL=/tmp/simulated_sdb
PARTICION=/tmp/simulated_sdb1
FILESYSTEM_OBJETIVO=${FILESYSTEM}
# ==========================================
EOF
        
        # Crear archivo de instrucciones
        cat > /tmp/instrucciones_${ID}.txt << 'INSTR'
COMANDOS PARA EL LABORATORIO:
1. Verificar disco: sudo fdisk -l /tmp/simulated_sdb
2. Ver partición: sudo lsblk /tmp/simulated_sdb
3. Formatear: sudo mkfs.$FILESYSTEM_OBJETIVO /tmp/simulated_sdb1
4. Crear directorio: sudo mkdir -p $MOUNT_POINT
5. Montar: sudo mount /tmp/simulated_sdb1 $MOUNT_POINT
6. Hacer permanente: 
   UUID=\$(sudo blkid -s UUID -o value /tmp/simulated_sdb1)
   echo "UUID=\$UUID $MOUNT_POINT $FILESYSTEM_OBJETIVO defaults 0 0" | sudo tee -a /etc/fstab
7. Verificar: sudo mount -a && df -h $MOUNT_POINT
INSTR
        
        echo 'SUCCESS:setup_completado'
        echo \"LOOP_DEVICE:\$LOOP_DEV\"
    " 2>&1)
    
    # Verificar resultado
    if echo "$setup_result" | grep -q "SUCCESS:setup_completado"; then
        success "✅ Setup completado exitosamente en VM"
        SETUP_EXITOSO=true
        
        # Mostrar info del setup
        local loop_device=$(echo "$setup_result" | grep "LOOP_DEVICE:" | cut -d: -f2)
        log "  Disco creado: /tmp/${disk_name} (${DISK_SIZE_MB}MB)"
        log "  Loop device: $loop_device"
        log "  Acceso simulado: /tmp/simulated_sdb"
        log "  Variables en: /tmp/lab_vars_${ID}.txt"
    else
        error "❌ Error en setup remoto:"
        echo "$setup_result" | while read line; do
            error "  $line"
        done
        SETUP_EXITOSO=false
    fi
    
    # Limpiar local
    rm -f "${disk_path}"
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
║ • 'lsblk' debe mostrar la nueva partición                           ║
║ • 'df -h' debe mostrar ${FILESYSTEM} montado en ${MOUNT_POINT}       ║
║ • '/etc/fstab' debe contener entrada permanente para el montaje      ║
║ • Punto de montaje debe existir y tener permisos 755                 ║
║                                                                      ║
║ 🔧 DISCO DISPONIBLE:                                                 ║
║ • Tamaño: ${DISK_SIZE_MB}MB ($((DISK_SIZE_MB/1024))GB)               ║
TICKET
    
    if [ "$SETUP_EXITOSO" = true ]; then
        cat << TICKET
║ • Disco: /tmp/simulated_sdb (loop device)                           ║
║ • Partición: /tmp/simulated_sdb1                                    ║
║ • Variables en: /tmp/lab_vars_${ID}.txt                             ║
TICKET
    else
        cat << TICKET
║ • ⚠️  SETUP AUTOMÁTICO FALLÓ - Usa disco físico disponible           ║
║ • Buscar discos: sudo fdisk -l | grep 'Disk /dev/'                  ║
║ • Usar /dev/sdb, /dev/vdb o similar                                 ║
TICKET
    fi
    
    cat << TICKET
╚══════════════════════════════════════════════════════════════════════╝
TICKET
}

# =============== MOSTRAR INSTRUCCIONES ===============
mostrar_instrucciones() {
    echo ""
    echo "📌 INSTRUCCIONES PARA EL LABORATORIO:"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "1. Conectarse a la VM:"
    echo "   ssh ${VM_USER}@${VM_IP}"
    echo "   Contraseña: ${VM_PASS}"
    echo ""
    
    if [ "$SETUP_EXITOSO" = true ]; then
        echo "2. Ver variables del laboratorio:"
        echo "   cat /tmp/lab_vars_${ID}.txt"
        echo ""
        echo "3. El disco YA ESTÁ PARTICIONADO:"
        echo "   sudo lsblk /tmp/simulated_sdb"
        echo "   (Verás simulated_sdb1 como partición)"
        echo ""
        echo "4. Formatear con ${FILESYSTEM}:"
        echo "   sudo mkfs.${FILESYSTEM} /tmp/simulated_sdb1"
        echo ""
        echo "5. Montar en ${MOUNT_POINT}:"
        echo "   sudo mkdir -p ${MOUNT_POINT}"
        echo "   sudo mount /tmp/simulated_sdb1 ${MOUNT_POINT}"
        echo ""
        echo "6. Hacer montaje permanente:"
        echo "   sudo blkid /tmp/simulated_sdb1"
        echo "   Copia el UUID y añade a /etc/fstab:"
        echo "   echo 'UUID=xxx ${MOUNT_POINT} ${FILESYSTEM} defaults 0 0' | sudo tee -a /etc/fstab"
        echo ""
        echo "7. Verificar:"
        echo "   sudo mount -a"
        echo "   df -h ${MOUNT_POINT}"
        echo "   lsblk -f /tmp/simulated_sdb"
    else
        echo "2. ⚠️  SETUP FALLADO - Debes usar disco físico:"
        echo "   sudo fdisk -l"
        echo "   sudo lsblk"
        echo ""
        echo "3. Busca un disco disponible (ej: /dev/sdb, /dev/vdb)"
        echo ""
        echo "4. Particionar disco elegido:"
        echo "   sudo fdisk /dev/sdb"
        echo "   Comandos: n → p → 1 → Enter → Enter → w"
        echo ""
        echo "5. Formatear con ${FILESYSTEM}:"
        echo "   sudo mkfs.${FILESYSTEM} /dev/sdb1"
        echo ""
        echo "6. Montar en ${MOUNT_POINT}:"
        echo "   sudo mkdir -p ${MOUNT_POINT}"
        echo "   sudo mount /dev/sdb1 ${MOUNT_POINT}"
        echo ""
        echo "7. Hacer montaje permanente:"
        echo "   sudo blkid /dev/sdb1"
        echo "   echo 'UUID=xxx ${MOUNT_POINT} ${FILESYSTEM} defaults 0 0' | sudo tee -a /etc/fstab"
    fi
    
    echo ""
    echo "💡 CONSEJO: Todos los comandos necesitan 'sudo'"
    echo "═══════════════════════════════════════════════════════════════"
}

# =============== VALIDADOR MEJORADO ===============
validar_lab() {
    info "Iniciando validación remota..."
    
    local errores=()
    local aciertos=()
    
    # Determinar qué disco validar
    local disco_a_validar=""
    
    if [ "$SETUP_EXITOSO" = true ]; then
        disco_a_validar="/tmp/simulated_sdb"
    else
        # Intentar detectar disco físico
        disco_a_validar=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no \
            "${VM_USER}@${VM_IP}" "
            # Buscar discos que no sean el principal (vda/sda)
            for disk in /dev/sd? /dev/vd? /dev/xvd?; do
                if [ -b \"\$disk\" ] && ! echo \"\$disk\" | grep -q '[a]1\$'; then
                    # Verificar si tiene particiones
                    if ls \"\${disk}\"* 2>/dev/null | grep -q '[0-9]\$'; then
                        echo \"\$disk\"
                        break
                    fi
                fi
            done
        " 2>/dev/null | head -1)
    fi
    
    if [ -n "$disco_a_validar" ]; then
        info "Validando disco: $disco_a_validar"
    fi
    
    # 1. Verificar partición
    local particion=""
    if [ -n "$disco_a_validar" ]; then
        particion=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no \
            "${VM_USER}@${VM_IP}" "
            # Buscar partición del disco especificado
            sudo lsblk -no NAME,TYPE,MOUNTPOINT | grep \"\$(basename $disco_a_validar)\" | grep 'part' | head -1 | awk '{print \$1}'
        " 2>/dev/null)
    fi
    
    if [ -n "$particion" ]; then
        aciertos+=("✅ Partición encontrada: /dev/$particion")
    else
        errores+=("❌ No se encontró partición creada")
        info "Sugerencia: Ejecuta en la VM: sudo fdisk -l"
    fi
    
    # 2. Verificar filesystem (si hay partición)
    if [ -n "$particion" ]; then
        local fs_check=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no \
            "${VM_USER}@${VM_IP}" "
            sudo blkid /dev/$particion 2>/dev/null | grep -o 'TYPE=\"[^\"]*\"' | cut -d'\"' -f2 || echo 'NO_FS'
        " 2>/dev/null)
        
        if [ "$fs_check" = "$FILESYSTEM" ]; then
            aciertos+=("✅ Filesystem correcto: $FILESYSTEM")
        elif [ "$fs_check" = "NO_FS" ]; then
            errores+=("❌ Partición sin formatear. Ejecuta: sudo mkfs.$FILESYSTEM /dev/$particion")
        else
            errores+=("❌ Filesystem incorrecto. Esperado: $FILESYSTEM, Encontrado: $fs_check")
        fi
    fi
    
    # 3. Verificar montaje
    local mount_check=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no \
        "${VM_USER}@${VM_IP}" "
        mount | grep \"$MOUNT_POINT\" | head -1
    " 2>/dev/null)
    
    if [ -n "$mount_check" ]; then
        aciertos+=("✅ Correctamente montado en $MOUNT_POINT")
    else
        errores+=("❌ No montado en $MOUNT_POINT")
        info "Sugerencia: Ejecuta en la VM: sudo mount /dev/$particion $MOUNT_POINT"
    fi
    
    # 4. Verificar fstab
    local fstab_check=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no \
        "${VM_USER}@${VM_IP}" "
        sudo grep \"$MOUNT_POINT\" /etc/fstab 2>/dev/null || true
    " 2>/dev/null)
    
    if [ -n "$fstab_check" ]; then
        aciertos+=("✅ Entrada encontrada en /etc/fstab")
    else
        errores+=("❌ No hay entrada en /etc/fstab")
        info "Sugerencia: Añade con: echo 'UUID=\$(sudo blkid -s UUID -o value /dev/$particion) $MOUNT_POINT $FILESYSTEM defaults 0 0' | sudo tee -a /etc/fstab"
    fi
    
    # 5. Verificar permisos del punto de montaje
    local permisos=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no \
        "${VM_USER}@${VM_IP}" "
        sudo stat -c '%a' \"$MOUNT_POINT\" 2>/dev/null || echo '000'
    " 2>/dev/null)
    
    if [ "$permisos" != "000" ]; then
        aciertos+=("✅ Directorio creado con permisos: $permisos")
    else
        errores+=("❌ Directorio $MOUNT_POINT no existe")
        info "Sugerencia: Crea con: sudo mkdir -p $MOUNT_POINT && sudo chmod 755 $MOUNT_POINT"
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
        echo ""
        echo "🔧 SUGERENCIAS:"
        echo "  1. Revisa los errores arriba"
        echo "  2. Sigue las instrucciones en VM"
        echo "  3. Vuelve a ejecutar los comandos necesarios"
        echo "  4. Presiona ENTER para validar nuevamente"
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

# =============== MAIN MEJORADO ===============
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
    info "Configurando VM automáticamente..."
    setup_vm_automatico
    
    # 3. Mostrar ticket con estado real
    mostrar_ticket
    
    # 4. Mostrar instrucciones apropiadas
    mostrar_instrucciones
    
    # 5. Bucle de validación hasta éxito
    while true; do
        echo ""
        read -p "⚠️  Trabaja en la VM ahora. Presiona ENTER para validar (o 'q' para salir): " respuesta
        
        if [[ "$respuesta" == "q" || "$respuesta" == "Q" ]]; then
            info "Saliendo del laboratorio..."
            break
        fi
        
        # 6. Validar trabajo
        if validar_lab; then
            echo ""
            success "¡Laboratorio completado con éxito!"
            break
        else
            echo ""
            info "Corrige los errores y vuelve a intentar."
            echo "════════════════════════════════════════════════"
        fi
    done
    
    # 7. Resumen final
    echo ""
    echo "╔════════════════════════════════════════════════╗"
    echo "║               RESUMEN DEL LABORATORIO          ║"
    echo "╠════════════════════════════════════════════════╣"
    echo "║ 🆔 ID: $ID"
    echo "║ 🏢 Departamento: $DEPARTAMENTO"
    echo "║ 💾 Filesystem: $FILESYSTEM"
    echo "║ 📂 Punto de Montaje: $MOUNT_POINT"
    echo "║ 💿 Tamaño Disco: ${DISK_SIZE_MB}MB"
    echo "║ 🖥️  VM: ${VM_USER}@${VM_IP}"
    if [ "$SETUP_EXITOSO" = true ]; then
        echo "║ ✅ Setup: Automático (simulated_sdb)"
    else
        echo "║ ⚠️  Setup: Manual (usa disco físico)"
    fi
    echo "╚════════════════════════════════════════════════╝"
}

# Ejecutar
main "$@"