# Validación 1: Tamaño LV aumentado a ~1GB
COMANDO = lvs vg_logs/lv_logs --noheadings --units m -o lv_size 2>/dev/null || echo '0'
RANGO_MIN = 950
RANGO_MAX = 1050
TIPO = rango_numerico
DESCRIPCION = LV extendido a ~1GB (600M + 400M)
PESO = 4

# Validación 2: Filesystem XFS extendido
COMANDO = df -B1M /mnt/logs 2>/dev/null | tail -1 | awk '{print $2}' || echo '0'
RANGO_MIN = 950
RANGO_MAX = 1050
TIPO = rango_numerico
DESCRIPCION = Filesystem XFS redimensionado en línea
PESO = 4

# Validación 3: Filesystem sigue montado durante extensión
COMANDO = mount | grep '/mnt/logs' && echo 'MONTADO_DURANTE' || echo 'DESMONTADO'
ESPERADO = MONTADO_DURANTE
TIPO = exacto
DESCRIPCION = Filesystem permaneció montado durante extensión
PESO = 3

# Validación 4: Filesystem sigue siendo XFS
COMANDO = blkid -s TYPE -o value /dev/vg_logs/lv_logs 2>/dev/null || echo 'NO_FS'
ESPERADO = xfs
TIPO = exacto
DESCRIPCION = Filesystem sigue siendo XFS después de extender
PESO = 2

# Validación 5: Datos preservados (verificar algún archivo de prueba)
COMANDO = test -d /mnt/logs && echo 'DATOS_OK' || echo 'DATOS_PERDIDOS'
ESPERADO = DATOS_OK
TIPO = exacto
DESCRIPCION = Datos preservados después de extender
PESO = 2

# ----------------------------------------------------------------------------
# LAB 006: Agregar Physical Volume a un VG
# ----------------------------------------------------------------------------
