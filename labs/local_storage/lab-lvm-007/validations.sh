# Validación 1: LV reducido a ~700MB
COMANDO = lvs vg_ext/lv_home --noheadings --units m -o lv_size 2>/dev/null || echo '0'
RANGO_MIN = 650
RANGO_MAX = 750
TIPO = rango_numerico
DESCRIPCION = LV reducido de 1GB a ~700MB
PESO = 4

# Validación 2: Filesystem EXT4 íntegro
COMANDO = fsck.ext4 -n /dev/vg_ext/lv_home 2>&1 | grep -q 'clean' && echo 'FS_OK' || echo 'FS_CORRUPTO'
ESPERADO = FS_OK
TIPO = exacto
DESCRIPCION = Filesystem EXT4 íntegro después de reducir
PESO = 5

# Validación 3: Se puede montar después de reducir
COMANDO = mount /dev/vg_ext/lv_home /mnt/home_ext 2>&1 && echo 'MONTABLE' || echo 'NO_MONTABLE'; umount /mnt/home_ext 2>/dev/null
ESPERADO = MONTABLE
TIPO = exacto
DESCRIPCION = LV montable después de reducción
PESO = 4

# Validación 4: Filesystem usa tamaño reducido
COMANDO = mount /dev/vg_ext/lv_home /mnt/home_ext 2>/dev/null; df -B1M /mnt/home_ext 2>/dev/null | tail -1 | awk '{print $2}' || echo '0'; umount /mnt/home_ext 2>/dev/null
RANGO_MIN = 650
RANGO_MAX = 750
TIPO = rango_numerico
DESCRIPCION = Filesystem usa el nuevo tamaño reducido
PESO = 3

# Validación 5: Datos preservados (archivo de prueba)
COMANDO = mount /dev/vg_ext/lv_home /mnt/home_ext 2>/dev/null; test -d /mnt/home_ext/lost+found && echo 'DATOS_OK' || echo 'DATOS_PERDIDOS'; umount /mnt/home_ext 2>/dev/null
ESPERADO = DATOS_OK
TIPO = exacto
DESCRIPCION = Estructura de datos básica preservada
PESO = 2

# ----------------------------------------------------------------------------
# LAB 008: Extender un LV lleno al 100%
# ----------------------------------------------------------------------------
