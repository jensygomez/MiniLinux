# Validación 1: LV existe
COMANDO = lvs vg_apps/lv_home --noheadings -o lv_name 2>/dev/null || echo 'NO_LV'
ESPERADO = lv_home
TIPO = exacto
DESCRIPCION = Logical Volume 'lv_home' existe
PESO = 3

# Validación 2: LV en VG correcto
COMANDO = lvs vg_apps/lv_home --noheadings -o vg_name 2>/dev/null || echo 'NO_VG'
ESPERADO = vg_apps
TIPO = exacto
DESCRIPCION = lv_home está en el VG vg_apps
PESO = 3

# Validación 3: Tamaño ~1GB
COMANDO = lvs vg_apps/lv_home --noheadings --units m -o lv_size 2>/dev/null || echo '0'
RANGO_MIN = 900
RANGO_MAX = 1100
TIPO = rango_numerico
DESCRIPCION = Tamaño aproximado 1GB (±50MB)
PESO = 4

# Validación 4: Estado del LV
COMANDO = lvs vg_apps/lv_home --noheadings -o lv_attr 2>/dev/null || echo 'NO_ATTR'
VALORES_ESPERADOS = -wi-------,-wi-a-----,-wi-ao----
TIPO = en_lista
DESCRIPCION = LV en estado válido
PESO = 2

# Validación 5: Dispositivo existe
COMANDO = test -b /dev/vg_apps/lv_home && echo 'EXISTE' || echo 'NO_EXISTE'
ESPERADO = EXISTE
TIPO = exacto
DESCRIPCION = Dispositivo /dev/vg_apps/lv_home creado
PESO = 2

# Validación 6: Espacio libre disminuyó
COMANDO = vgs vg_apps --noheadings --units m -o vg_free 2>/dev/null || echo '0'
RANGO_MIN = 2500
RANGO_MAX = 3500
TIPO = rango_numerico
DESCRIPCION = Espacio libre disminuyó apropiadamente (~1GB usado)
PESO = 1

# ----------------------------------------------------------------------------
# LAB 004: Crear filesystem y montar un LV
# ----------------------------------------------------------------------------
