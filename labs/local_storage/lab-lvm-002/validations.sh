# Validación 1: VG existe
COMANDO = vgs vg_data --noheadings -o vg_name 2>/dev/null || echo 'NO_VG'
ESPERADO = vg_data
TIPO = exacto
DESCRIPCION = Volume Group 'vg_data' existe
PESO = 3

# Validación 2: 2 PVs en VG
COMANDO = vgs vg_data --noheadings -o pv_count 2>/dev/null || echo '0'
ESPERADO = 2
TIPO = exacto
DESCRIPCION = VG tiene exactamente 2 PVs
PESO = 4

# Validación 3: Tamaño total ~4GB
COMANDO = vgs vg_data --noheadings --units m -o vg_size 2>/dev/null || echo '0'
RANGO_MIN = 3500
RANGO_MAX = 4500
TIPO = rango_numerico
DESCRIPCION = Tamaño total ~4GB (2 discos de ~2GB)
PESO = 2

# Validación 4: /dev/loop2 en vg_data
COMANDO = pvs /dev/loop2 --noheadings -o vg_name 2>/dev/null
ESPERADO = vg_data
TIPO = exacto
DESCRIPCION = /dev/loop2 está en vg_data
PESO = 2

# Validación 5: /dev/loop3 en vg_data
COMANDO = pvs /dev/loop3 --noheadings -o vg_name 2>/dev/null
ESPERADO = vg_data
TIPO = exacto
DESCRIPCION = /dev/loop3 está en vg_data
PESO = 2

# Validación 6: VG activo
COMANDO = vgs vg_data --noheadings -o vg_attr 2>/dev/null || echo 'NO_ATTR'
ESPERADO = wz
TIPO = contiene
DESCRIPCION = VG está activo (writable, resizeable)
PESO = 1

# ----------------------------------------------------------------------------
# LAB 003: Crear Logical Volume (LV)
# ----------------------------------------------------------------------------
