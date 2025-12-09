# Validación 1: VG ahora tiene solo 1 PV
COMANDO = vgs vg_remocao --noheadings -o pv_count 2>/dev/null || echo '2'
ESPERADO = 1
TIPO = exacto
DESCRIPCION = VG reducido a 1 PV
PESO = 5

# Validación 2: /dev/loop13 NO está en el VG
COMANDO = pvs /dev/loop13 --noheadings -o vg_name 2>/dev/null
ESPERADO = 
TIPO = exacto
DESCRIPCION = /dev/loop13 ya no está en vg_remocao
PESO = 5

# Validación 3: /dev/loop12 SÍ está en el VG
COMANDO = pvs /dev/loop12 --noheadings -o vg_name 2>/dev/null
ESPERADO = vg_remocao
TIPO = exacto
DESCRIPCION = /dev/loop12 sigue en vg_remocao
PESO = 3

# Validación 4: LV sigue montado y funcionando
COMANDO = mount | grep '/mnt/remo' && echo 'LV_ACTIVO' || echo 'LV_INACTIVO'
ESPERADO = LV_ACTIVO
TIPO = exacto
DESCRIPCION = LV sigue montado después de remover PV
PESO = 4

# Validación 5: Tamaño del VG reducido apropiadamente
COMANDO = vgs vg_remocao --noheadings --units m -o vg_size 2>/dev/null | awk '{print int($1)}' || echo '0'
RANGO_MIN = 1800
RANGO_MAX = 2200
TIPO = rango_numerico
DESCRIPCION = Tamaño del VG reducido a ~2GB (1 disco)
PESO = 3

# Validación 6: Datos preservados en el LV
COMANDO = test -d /mnt/remo/lost+found && echo 'DATOS_OK' || echo 'DATOS_PERDIDOS'
ESPERADO = DATOS_OK
TIPO = exacto
DESCRIPCION = Estructura de datos preservada
PESO = 4

# ----------------------------------------------------------------------------
# LAB 014: LVM Avanzado – Reparación de un VG degradado
# ----------------------------------------------------------------------------
