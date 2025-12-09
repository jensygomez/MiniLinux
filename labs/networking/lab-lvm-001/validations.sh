# Validación 1: PV existe
COMANDO = pvs /dev/loop1 --noheadings -o pv_name 2>/dev/null || echo 'NO_ES_PV'
ESPERADO = /dev/loop1
TIPO = exacto
DESCRIPCION = /dev/loop1 existe como Physical Volume
PESO = 3

# Validación 2: Tamaño aproximado 2GB
COMANDO = pvs /dev/loop1 --noheadings --units m -o pv_size 2>/dev/null || echo '0'
RANGO_MIN = 1800
RANGO_MAX = 2200
TIPO = rango_numerico
DESCRIPCION = Tamaño aproximado 2GB (±100MB)
PESO = 2

# Validación 3: Formato LVM2
COMANDO = pvs /dev/loop1 --noheadings -o pv_fmt 2>/dev/null || echo 'NO_FMT'
ESPERADO = lvm2
TIPO = exacto
DESCRIPCION = Formato LVM2 correcto
PESO = 2

# Validación 4: Estado válido
COMANDO = pvs /dev/loop1 --noheadings -o pv_attr 2>/dev/null || echo 'NO_ATTR'
VALORES_ESPERADOS = ---,a--
TIPO = en_lista
DESCRIPCION = PV en estado válido (--- o a--)
PESO = 1

# Validación 5: No está en VG
COMANDO = pvs /dev/loop1 --noheadings -o vg_name 2>/dev/null
ESPERADO = 
TIPO = exacto
DESCRIPCION = PV no está en ningún Volume Group (aún)
PESO = 2

# ----------------------------------------------------------------------------
# LAB 002: Crear Volume Group (VG) con 2 discos
# ----------------------------------------------------------------------------
