# Validación 1: /dev/loop11 es un PV
COMANDO = pvs /dev/loop11 --noheadings -o pv_name 2>/dev/null || echo 'NO_PV'
ESPERADO = /dev/loop11
TIPO = exacto
DESCRIPCION = /dev/loop11 es un Physical Volume
PESO = 3

# Validación 2: VG tiene 2 PVs
COMANDO = vgs vg_main --noheadings -o pv_count 2>/dev/null || echo '1'
ESPERADO = 2
TIPO = exacto
DESCRIPCION = VG vg_main tiene 2 PVs
PESO = 4

# Validación 3: /dev/loop11 está en vg_main
COMANDO = pvs /dev/loop11 --noheadings -o vg_name 2>/dev/null
ESPERADO = vg_main
TIPO = exacto
DESCRIPCION = /dev/loop11 pertenece a vg_main
PESO = 3

# Validación 4: Tamaño total aumentó a ~4GB
COMANDO = vgs vg_main --noheadings --units m -o vg_size 2>/dev/null || echo '0'
RANGO_MIN = 3800
RANGO_MAX = 4200
TIPO = rango_numerico
DESCRIPCION = Tamaño total del VG ~4GB (2 discos de ~2GB)
PESO = 2

# Validación 5: VG sigue activo
COMANDO = vgs vg_main --noheadings -o vg_attr 2>/dev/null || echo 'INACTIVO'
ESPERADO = wz
TIPO = contiene
DESCRIPCION = VG sigue activo después de agregar PV
PESO = 2

# ----------------------------------------------------------------------------
# LAB 007: Reducir Logical Volume (EXT4)
# ----------------------------------------------------------------------------
