# Validación 1: Filesystem ext4 creado
COMANDO = blkid -s TYPE -o value /dev/vg_storage/lv_data 2>/dev/null || echo 'NO_FS'
ESPERADO = ext4
TIPO = exacto
DESCRIPCION = Filesystem ext4 creado en el LV
PESO = 3

# Validación 2: Montado en /mnt/data
COMANDO = mount | grep '/dev/mapper/vg_storage-lv_data' | grep '/mnt/data' && echo 'MONTADO' || echo 'NO_MONTADO'
ESPERADO = MONTADO
TIPO = exacto
DESCRIPCION = LV montado en /mnt/data
PESO = 3

# Validación 3: Espacio usado aprox 800MB
COMANDO = df -B1M /mnt/data 2>/dev/null | tail -1 | awk '{print $2}' || echo '0'
RANGO_MIN = 750
RANGO_MAX = 850
TIPO = rango_numerico
DESCRIPCION = Tamaño del filesystem ~800MB
PESO = 2

# Validación 4: Entrada en /etc/fstab
COMANDO = grep '/mnt/data' /etc/fstab | grep -q 'vg_storage' && echo 'EN_FSTAB' || echo 'NO_FSTAB'
ESPERADO = EN_FSTAB
TIPO = exacto
DESCRIPCION = Entrada correcta en /etc/fstab
PESO = 4

# Validación 5: Persistencia después de desmontar/remontar
COMANDO = umount /mnt/data 2>/dev/null; mount -a 2>&1 | grep -q '/mnt/data' || echo 'OK'; mount | grep '/mnt/data' && echo 'PERSISTENTE' || echo 'NO_PERSISTENTE'
ESPERADO = PERSISTENTE
TIPO = exacto
DESCRIPCION = Montaje persistente (sobrevive a mount -a)
PESO = 3



# ----------------------------------------------------------------------------
# LAB 005: Extender Logical Volume en caliente
# ----------------------------------------------------------------------------
