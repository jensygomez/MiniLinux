# Validación 1: /dev/loop16p1 ahora es un PV
COMANDO = pvs /dev/loop16p1 --noheadings -o pv_name 2>/dev/null || echo 'NO_PV'
ESPERADO = /dev/loop16p1
TIPO = exacto
DESCRIPCION = /dev/loop16p1 convertido a Physical Volume
PESO = 4

# Validación 2: VG creado con el PV
COMANDO = pvs /dev/loop16p1 --noheadings -o vg_name 2>/dev/null
ESPERADO = vg_convertido
TIPO = contiene
DESCRIPCION = PV asignado a un Volume Group
PESO = 3

# Validación 3: LV creado con tamaño similar
COMANDO = lvs --noheadings --units m -o lv_size 2>/dev/null | head -1 | awk '{print int($1)}' || echo '0'
RANGO_MIN = 1800
RANGO_MAX = 2200
TIPO = rango_numerico
DESCRIPCION = LV creado con tamaño ~2GB
PESO = 4

# Validación 4: Nuevo punto de montaje /mnt/nuevo_legacy creado
COMANDO = test -d /mnt/nuevo_legacy && echo 'DIR_EXISTE' || echo 'DIR_NO_EXISTE'
ESPERADO = DIR_EXISTE
TIPO = exacto
DESCRIPCION = Nuevo directorio de montaje /mnt/nuevo_legacy creado
PESO = 3

# Validación 5: Datos migrados (archivo data.bin presente)
COMANDO = test -f /mnt/nuevo_legacy/data.bin && echo 'DATOS_MIGRADOS' || echo 'DATOS_FALTANTES'
ESPERADO = DATOS_MIGRADOS
TIPO = exacto
DESCRIPCION = Archivo data.bin migrado al nuevo filesystem
PESO = 5

# Validación 6: Tamaño del archivo preservado (~50MB)
COMANDO = test -f /mnt/nuevo_legacy/data.bin && du -m /mnt/nuevo_legacy/data.bin | cut -f1 || echo '0'
RANGO_MIN = 40
RANGO_MAX = 60
TIPO = rango_numerico
DESCRIPCION = Archivo data.bin mantiene tamaño ~50MB
PESO = 4

# Validación 7: Filesystem montado y accesible
COMANDO = mount | grep '/mnt/nuevo_legacy' && echo 'MONTADO' || echo 'DESMONTADO'
ESPERADO = MONTADO
TIPO = exacto
DESCRIPCION = Nuevo filesystem montado
PESO = 3

# ----------------------------------------------------------------------------
# LAB 016: LVM Avanzado – LV dividido en varias particiones (striped LV)
# ----------------------------------------------------------------------------
