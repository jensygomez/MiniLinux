# Validación 1: LV extendido (>500MB)
COMANDO = lvs vg_xfs/lv_xdata --noheadings --units m -o lv_size 2>/dev/null || echo '0'
RANGO_MIN = 550
RANGO_MAX = 1500
TIPO = rango_numerico
DESCRIPCION = LV extendido más allá de 500MB
PESO = 3

# Validación 2: xfs_growfs ejecutado (filesystem extendido)
COMANDO = df -B1M /mnt/xdata 2>/dev/null | tail -1 | awk '{print $2}' || echo '0'
RANGO_MIN = 550
RANGO_MAX = 1500
TIPO = rango_numerico
DESCRIPCION = Filesystem XFS redimensionado con xfs_growfs
PESO = 4

# Validación 3: xfs_growfs no produjo errores (filesystem montado)
COMANDO = mount | grep '/mnt/xdata' && echo 'MONTADO_DURANTE' || echo 'DESMONTADO'
ESPERADO = MONTADO_DURANTE
TIPO = exacto
DESCRIPCION = Filesystem permaneció montado durante xfs_growfs
PESO = 3

# Validación 4: Filesystem sigue siendo XFS
COMANDO = blkid -s TYPE -o value /dev/vg_xfs/lv_xdata 2>/dev/null || echo 'NO_FS'
ESPERADO = xfs
TIPO = exacto
DESCRIPCION = Filesystem sigue siendo XFS
PESO = 2

# Validación 5: Datos preservados
COMANDO = test -d /mnt/xdata && echo 'DATOS_OK' || echo 'DATOS_PERDIDOS'
ESPERADO = DATOS_OK
TIPO = exacto
DESCRIPCION = Datos preservados después de extender XFS
PESO = 2

# Validación 6: Se puede escribir después de extender
COMANDO = touch /mnt/xdata/test_after_grow && echo 'ESCRIBIBLE' || echo 'NO_ESCRIBIBLE'
ESPERADO = ESCRIBIBLE
TIPO = exacto
DESCRIPCION = Se puede escribir después de xfs_growfs
PESO = 1

# ----------------------------------------------------------------------------
# LAB 011: Actualizar UUID en /etc/fstab
# ----------------------------------------------------------------------------
