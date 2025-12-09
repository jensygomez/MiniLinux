# Validación 1: LV creado en modo striped
COMANDO = lvs --noheadings -o segtype 2>/dev/null | grep -i 'striped' | head -1 || echo 'NO_STRIPED'
ESPERADO = striped
TIPO = contiene
DESCRIPCION = LV creado en modo striped
PESO = 5

# Validación 2: LV con 2 stripes
COMANDO = lvs --noheadings -o stripes 2>/dev/null | head -1 || echo '0'
ESPERADO = 2
TIPO = exacto
DESCRIPCION = LV con 2 stripes (uno por disco)
PESO = 5

# Validación 3: Tamaño ~1.5GB
COMANDO = lvs --noheadings --units m -o lv_size 2>/dev/null | head -1 | awk '{print int($1)}' || echo '0'
RANGO_MIN = 1300
RANGO_MAX = 1700
TIPO = rango_numerico
DESCRIPCION = LV con tamaño ~1.5GB
PESO = 4

# Validación 4: Filesystem XFS creado
COMANDO = blkid -s TYPE -o value $(lvs --noheadings -o lv_path 2>/dev/null | head -1) 2>/dev/null || echo 'NO_FS'
ESPERADO = xfs
TIPO = exacto
DESCRIPCION = Filesystem XFS creado en el LV
PESO = 4

# Validación 5: LV montado (si se pidió montar)
COMANDO = mount | grep 'vg_rapido' && echo 'MONTADO' || echo 'NO_MONTADO'
ESPERADO = MONTADO
TIPO = exacto
DESCRIPCION = LV striped montado y listo para usar
PESO = 3

# Validación 6: Datos distribuidos en ambos discos (verificación indirecta)
COMANDO = pvs --noheadings --units m -o pv_used /dev/loop17 2>/dev/null | awk '{print int($1)}' || echo '0'
RANGO_MIN = 450
RANGO_MAX = 950
TIPO = rango_numerico
DESCRIPCION = Datos distribuidos en /dev/loop17
PESO = 3
