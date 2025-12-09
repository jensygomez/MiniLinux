# Validación 1: Filesystem actualmente montado
COMANDO = mount | grep '/mnt/uuidtest' && echo 'MONTADO' || echo 'DESMONTADO'
ESPERADO = MONTADO
TIPO = exacto
DESCRIPCION = Filesystem permanece montado durante el ejercicio
PESO = 3

# Validación 2: UUID en fstab coincide con UUID actual
COMANDO = CURRENT_UUID=$(blkid -s UUID -o value /dev/vg_uuid/lv_uuid 2>/dev/null); grep '/mnt/uuidtest' /etc/fstab | grep -q "UUID=${CURRENT_UUID}" && echo 'UUID_CORRECTO' || echo 'UUID_INCORRECTO'
ESPERADO = UUID_CORRECTO
TIPO = exacto
DESCRIPCION = UUID en fstab coincide con UUID actual del filesystem
PESO = 5

# Validación 3: mount -a funciona sin errores
COMANDO = mount -a 2>&1 | grep -v 'already mounted' | wc -l
RANGO_MIN = 0
RANGO_MAX = 1
TIPO = rango_numerico
DESCRIPCION = mount -a no produce errores
PESO = 3

# Validación 4: Persistencia después de reboot simulado
COMANDO = umount /mnt/uuidtest 2>/dev/null; mount -a 2>&1; mount | grep '/mnt/uuidtest' && echo 'PERSISTENTE' || echo 'NO_PERSISTENTE'
ESPERADO = PERSISTENTE
TIPO = exacto
DESCRIPCION = Montaje funciona después de umount + mount -a
PESO = 3

# Validación 5: UUID antiguo NO está en fstab
COMANDO = OLD_UUID=$(grep 'WRONG-UUID\|ORIGINAL' /etc/fstab 2>/dev/null | head -1 | grep -o 'UUID=[^ ]*' | cut -d= -f2); if [ -z "$OLD_UUID" ]; then echo 'UUID_ANTIGUO_ELIMINADO'; else echo 'UUID_ANTIGUO_PRESENTE'; fi
ESPERADO = UUID_ANTIGUO_ELIMINADO
TIPO = exacto
DESCRIPCION = UUID antiguo no está presente en fstab
PESO = 2

# ----------------------------------------------------------------------------
# LAB 012: LVM Avanzado – Migración de datos con pvmove
# ----------------------------------------------------------------------------
