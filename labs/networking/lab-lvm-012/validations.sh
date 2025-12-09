# Validación 1: Datos migrados de loop10 a loop11
COMANDO = pvs /dev/loop10 --noheadings --units m -o pv_used 2>/dev/null | awk '{print int($1)}' || echo '9999'
RANGO_MIN = 0
RANGO_MAX = 50
TIPO = rango_numerico
DESCRIPCION = /dev/loop10 con menos de 50MB usados (datos migrados)
PESO = 5

# Validación 2: Datos ahora en loop11
COMANDO = pvs /dev/loop11 --noheadings --units m -o pv_used 2>/dev/null | awk '{print int($1)}' || echo '0'
RANGO_MIN = 700
RANGO_MAX = 900
TIPO = rango_numerico
DESCRIPCION = /dev/loop11 con ~800MB usados (datos migrados aquí)
PESO = 5

# Validación 3: Filesystem sigue montado y accesible durante migración
COMANDO = mount | grep '/mnt/mover' && echo 'MONTADO_DURANTE' || echo 'DESMONTADO'
ESPERADO = MONTADO_DURANTE
TIPO = exacto
DESCRIPCION = Filesystem permaneció montado durante pvmove
PESO = 4

# Validación 4: Datos preservados (archivo testfile.bin)
COMANDO = test -f /mnt/mover/testfile.bin && echo 'DATOS_PRESERVADOS' || echo 'DATOS_PERDIDOS'
ESPERADO = DATOS_PRESERVADOS
TIPO = exacto
DESCRIPCION = Archivo de datos preservado después de migración
PESO = 4

# Validación 5: Filesystem sigue siendo XFS y funcional
COMANDO = blkid -s TYPE -o value /dev/vg_migracao/lv_mover 2>/dev/null || echo 'NO_FS'
ESPERADO = xfs
TIPO = exacto
DESCRIPCION = Filesystem sigue siendo XFS después de migración
PESO = 3

# Validación 6: Tamaño del LV se mantiene
COMANDO = lvs vg_migracao/lv_mover --noheadings --units m -o lv_size 2>/dev/null | awk '{print int($1)}' || echo '0'
RANGO_MIN = 700
RANGO_MAX = 900
TIPO = rango_numerico
DESCRIPCION = LV mantiene tamaño ~800MB después de migración
PESO = 3

# ----------------------------------------------------------------------------
# LAB 013: LVM Avanzado – Remover un PV de un Volume Group
# ----------------------------------------------------------------------------
