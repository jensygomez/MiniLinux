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

# =============== FUNCIONES AUXILIARES ===============
log() { printf "%s\n" "$*"; }
rand_from_list() { local arr=("$@"); printf "%s" "${arr[RANDOM % ${#arr[@]}]}"; }

generate_vars() {
    ID="lab-$(date +%s | sha256sum | cut -c1-6)"
    DEPARTAMENTO=$(rand_from_list "${DEPARTAMENTOS[@]}")
    USUARIO=$(rand_from_list "${USUARIOS[@]}")
    FILESYSTEM=$(rand_from_list "${FILESYSTEMS[@]}")
    MOUNT_POINT=$(rand_from_list "${MOUNT_POINTS[@]}")
    DISK_SIZE_MB=$(rand_from_list "${DISK_SIZES_MB[@]}")
    
    log "[+] Variables generadas:"
    log "    ID: ${ID}"
    log "    Departamento: ${DEPARTAMENTO}"
    log "    Usuario: ${USUARIO}"
    log "    Filesystem: ${FILESYSTEM}"
    log "    Mount Point: ${MOUNT_POINT}"
    log "    Disk Size: ${DISK_SIZE_MB}MB"
}

# =============== TICKET BÁSICO ===============
mostrar_ticket_basico() {
    clear
    cat << TICKET
╔══════════════════════════════════════════════════════════╗
║                  🚨 TICKET DE SOPORTE 🚨                 ║
╠══════════════════════════════════════════════════════════╣
║ ASUNTO: Espacio insuficiente para backups                ║
║ DEPARTAMENTO: ${DEPARTAMENTO}                            ║
║ REPORTADO POR: ${USUARIO}                                ║
║ PRIORIDAD: MEDIA                                         ║
╠══════════════════════════════════════════════════════════╣
║ 📋 DESCRIPCIÓN:                                          ║
║ El departamento ${DEPARTAMENTO} necesita espacio         ║
║ adicional para almacenar backups diarios.                ║
║                                                          ║
║ 💻 TAREAS REQUERIDAS:                                    ║
║ 1. Identificar disco nuevo (/dev/sdb o /dev/vdb)         ║
║ 2. Crear una partición primaria que use TODO el disco    ║
║ 3. Formatear con ${FILESYSTEM}                           ║
║ 4. Montar en ${MOUNT_POINT}                              ║
║ 5. Hacer montaje permanente en /etc/fstab                ║
║                                                          ║
║ ✅ CRITERIOS DE ÉXITO:                                    ║
║ • 'lsblk' muestra partición /dev/sdb1 (o similar)        ║
║ • 'df -h' muestra sistema ${FILESYSTEM} montado          ║
║ • '/etc/fstab' contiene entrada correcta                 ║
║ • Punto de montaje existe y tiene permisos 755           ║
╚══════════════════════════════════════════════════════════╝
TICKET
}

# =============== SETUP BÁSICO ===============
setup_vm_basic() {
    log "[+] Configurando VM..."
    
    # Crear imagen de disco
    local size_mb=${DISK_SIZE_MB}
    local disk_name="disco_extra_${ID}.img"
    
    log "[+] Creando disco de ${size_mb}MB..."
    dd if=/dev/zero of="/tmp/${disk_name}" bs=1M count=${size_mb} status=none
    
    # Transferir a VM
    log "[+] Enviando disco a VM..."
    sshpass -p "$VM_PASS" scp -o StrictHostKeyChecking=no "/tmp/${disk_name}" "${VM_USER}@${VM_IP}:/tmp/"
    
    # En la VM: conectar disco (simulado con loop device)
    log "[+] Configurando loop device en VM..."
    sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "${VM_USER}@${VM_IP}" "
        sudo losetup -f --show /tmp/${disk_name} > /tmp/loop_device 2>/dev/null || true
        echo '[VM] Disco de ${size_mb}MB preparado para prácticas'
        echo '[VM] Ejecuta: sudo losetup -a  para ver dispositivos loop'
    "
    
    rm -f "/tmp/${disk_name}"
    log "[✓] Setup completado."
}

# =============== VALIDADOR BÁSICO ===============
validar_lab_basico() {
    echo "🔍 Validando configuración..."
    
    local errores=()
    local aciertos=()
    
    # 1. Verificar que existe partición en disco secundario
    local particion=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "${VM_USER}@${VM_IP}" \
        "lsblk -ln -o NAME,TYPE | grep -E '^(sdb|vdb|xvdb|loop)[0-9]+.*part\$' | head -1 | cut -d' ' -f1 || true")
    
    if [ -n "$particion" ]; then
        aciertos+=("✅ Partición encontrada: /dev/$particion")
    else
        errores+=("❌ No se encontró partición en disco secundario")
        # Mostrar discos disponibles para ayuda
        sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "${VM_USER}@${VM_IP}" "lsblk" 2>/dev/null || true
    fi
    
    # 2. Verificar filesystem (solo si hay partición)
    if [ -n "$particion" ]; then
        local fs_type=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "${VM_USER}@${VM_IP}" \
            "df -T /dev/$particion 2>/dev/null | tail -1 | awk '{print \$2}' || true")
        
        if [ "$fs_type" = "$FILESYSTEM" ]; then
            aciertos+=("✅ Filesystem correcto: $FILESYSTEM")
        else
            errores+=("❌ Filesystem incorrecto. Esperado: $FILESYSTEM, Encontrado: $fs_type")
        fi
    fi
    
    # 3. Verificar montaje
    local mount_check=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "${VM_USER}@${VM_IP}" \
        "mount | grep '$MOUNT_POINT' || true")
    
    if [ -n "$mount_check" ]; then
        if echo "$mount_check" | grep -q "/dev/"; then
            aciertos+=("✅ Correctamente montado en $MOUNT_POINT")
        else
            errores+=("⚠️  Montado pero posiblemente dispositivo incorrecto")
        fi
    else
        errores+=("❌ No montado en $MOUNT_POINT")
    fi
    
    # 4. Verificar fstab
    local fstab_check=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "${VM_USER}@${VM_IP}" \
        "grep '$MOUNT_POINT' /etc/fstab 2>/dev/null || true")
    
    if [ -n "$fstab_check" ]; then
        aciertos+=("✅ Entrada encontrada en /etc/fstab")
    else
        errores+=("❌ No hay entrada en /etc/fstab")
    fi
    
    # 5. Verificar permisos del punto de montaje
    local permisos=$(sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "${VM_USER}@${VM_IP}" \
        "stat -c '%a' '$MOUNT_POINT' 2>/dev/null || echo '0'")
    
    if [ "$permisos" = "755" ] || [ "$permisos" = "750" ] || [ "$permisos" = "700" ]; then
        aciertos+=("✅ Permisos adecuados: $permisos")
    else
        errores+=("⚠️  Permisos no óptimos: $permisos (recomendado: 755)")
    fi
    
    # Mostrar resultados
    echo ""
    echo "══════════════ RESULTADO ══════════════"
    
    for acierto in "${aciertos[@]}"; do
        echo "$acierto"
    done
    
    if [ ${#errores[@]} -gt 0 ]; then
        echo ""
        echo "❌ ERRORES ENCONTRADOS:"
        for error in "${errores[@]}"; do
            echo "   $error"
        done
        echo "══════════════════════════════════════"
        return 1
    else
        echo ""
        echo "🎉 ¡TODAS LAS TAREAS COMPLETADAS CORRECTAMENTE!"
        echo "══════════════════════════════════════"
        
        # ============ FRASE FILOSÓFICA ============
        echo ""
        read -p "Presiona ENTER para ver la reflexión profesional... " _
        clear
        
        # VERSIÓN ENTREVISTA:
        echo "================================================================="
        echo "  💭 FILOSOFÍA TÉCNICA PARA ENTREVISTADOR:"
        echo "  'DOMINAR EL DISCO ES DOMINAR EL CORAZÓN DEL SISTEMA:"
        echo "   CADA BYTE TIENE SU LUGAR Y PROPÓSITO'"
        echo "================================================================="
        echo ""
        echo "📢 Explicación: Esta frase representa mi enfoque de administración de"
        echo "   sistemas: cada recurso debe asignarse con intención y visión"
        echo "   arquitectónica, anticipando necesidades y creando infraestructura"
        echo "   resiliente, no solo cumpliendo tareas técnicas."
        
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        
        return 0
    fi
}

# =============== MENÚ INTERACTIVO BÁSICO ===============
mostrar_menu_ayuda() {
    cat << AYUDA

💡 COMANDOS DE AYUDA PARA EL LABORATORIO:

🔍 IDENTIFICAR DISCOS:
   sudo fdisk -l
   lsblk
   cat /proc/partitions

📐 PARTICIONAR (ejemplo con /dev/sdb):
   sudo fdisk /dev/sdb
     Comandos dentro de fdisk:
     n → nueva partición
     p → primaria
     1 → número de partición
     Enter → primer sector (default)
     Enter → último sector (todo el disco)
     w → escribir y salir

🎨 FORMATEAR:
   sudo mkfs.$FILESYSTEM /dev/sdb1

📂 MONTAR:
   sudo mkdir -p $MOUNT_POINT
   sudo mount /dev/sdb1 $MOUNT_POINT

🔧 HACER PERSISTENTE:
   sudo blkid /dev/sdb1  # obtener UUID
   echo "UUID=xxxxxxx $MOUNT_POINT $FILESYSTEM defaults 0 0" | sudo tee -a /etc/fstab

🔄 VERIFICAR:
   sudo mount -a  # prueba fstab sin reiniciar
   df -h
   lsblk -f

AYUDA
}

# =============== MAIN ===============
main() {
    echo "🚀 INICIANDO LABORATORIO BÁSICO DE DISCOS"
    echo "========================================="
    
    # Verificar sshpass
    if ! command -v sshpass &>/dev/null; then
        echo "Instalando sshpass..."
        if command -v apt-get &>/dev/null; then
            apt-get update && apt-get install -y sshpass
        elif command -v dnf &>/dev/null; then
            dnf install -y sshpass
        elif command -v yum &>/dev/null; then
            yum install -y epel-release && yum install -y sshpass
        fi
    fi
    
    # Generar variables aleatorias
    generate_vars
    
    # Mostrar ticket
    mostrar_ticket_basico
    
    echo ""
    echo "¿Deseas configurar el disco en la VM? (s/N)"
    read -p "Elección: " respuesta
    
    if [[ "$respuesta" =~ ^[Ss]$ ]]; then
        setup_vm_basic
    else
        echo "Saltando configuración automática..."
        echo "Asume que ya hay un disco disponible en la VM."
    fi
    
    echo ""
    echo "══════════════════════════════════════════════════════"
    echo "📋 Ahora conecta a la VM y realiza las tareas:"
    echo "  ssh $VM_USER@$VM_IP"
    echo "  Contraseña: $VM_PASS"
    echo ""
    echo "💡 Para ver ayuda de comandos, ejecuta en la VM:"
    echo "  cat /tmp/ayuda_lab.txt"
    
    # Crear archivo de ayuda en la VM
    sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "${VM_USER}@${VM_IP}" \
        "echo 'FILESYSTEM=$FILESYSTEM' > /tmp/ayuda_lab.txt; \
         echo 'MOUNT_POINT=$MOUNT_POINT' >> /tmp/ayuda_lab.txt; \
         echo 'TICKET_ID=$ID' >> /tmp/ayuda_lab.txt"
    
    echo ""
    read -p "Cuando termines las tareas en la VM, presiona ENTER para validar... " _
    
    # Ejecutar validador
    validar_lab_basico
    
    echo ""
    echo "🏁 Laboratorio completado."
    echo "ID de sesión: $ID"
    echo "Departamento: $DEPARTAMENTO"
}

# Ejecutar main
main "$@"