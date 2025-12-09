# Validación 1: LV extendido más allá de 300MB
COMANDO = lvs vg_full/lv_full --noheadings --units m -o lv_size 2>/dev/null || echo '0'
RANGO_MIN = 350
RANGO_MAX = 1000
TIPO = rango_numerico
DESCRIPCION = LV extendido más allá del tamaño original (300MB)
PESO = 4

# Validación 2: Filesystem extendido
COMANDO = df -B1M /mnt/full 2>/dev/null | tail -1 | awk '{print $2}' || echo '0'
RANGO_MIN = 350
RANGO_MAX = 1000
TIPO = rango_numerico
DESCRIPCION = Filesystem extendido
PESO = 4

# Validación 3: Espacio disponible > 0%
COMANDO = df /mnt/full 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//' || echo '100'
RANGO_MIN = 0
RANGO_MAX = 95
TIPO = rango_numerico
DESCRIPCION = Espacio disponible recuperado (<95% usado)
PESO = 3

# Validación 4: Filesystem sigue siendo XFS
COMANDO = blkid -s TYPE -o value /dev/vg_full/lv_full 2>/dev/null || echo 'NO_FS'
ESPERADO = xfs
TIPO = exacto
DESCRIPCION = Filesystem sigue siendo XFS
PESO = 2

# Validación 5: Se pueden escribir nuevos datos
COMANDO = dd if=/dev/zero of=/mnt/full/testfile.bin bs=1M count=10 2>&1 && echo 'ESCRIBIBLE' || echo 'NO_ESCRIBIBLE'
ESPERADO = ESCRIBIBLE
TIPO = exacto
DESCRIPCION = Se pueden escribir nuevos datos después de extender
PESO = 2


# ----------------------------------------------------------------------------
# LAB 009: Corregir entrada incorrecta en /etc/fstab
# ----------------------------------------------------------------------------
