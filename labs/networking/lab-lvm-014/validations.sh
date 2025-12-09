# Validación 1: VG reporta solo 1 PV (el que sigue disponible)
COMANDO = vgs vg_degradado --noheadings -o pv_count 2>/dev/null || echo '2'
ESPERADO = 1
TIPO = exacto
DESCRIPCION = VG reparado con 1 PV (eliminado el faltante)
PESO = 5

# Validación 2: vgdisplay no muestra errores críticos
COMANDO = vgdisplay vg_degradado 2>&1 | grep -i 'error\\|fault\\|missing' | wc -l
RANGO_MIN = 0
RANGO_MAX = 1
TIPO = rango_numerico
DESCRIPCION = VG sin errores críticos después de reparación
PESO = 4

# Validación 3: LV sigue activo y montado
COMANDO = lvs vg_degradado/lv_dados --noheadings -o lv_attr 2>/dev/null | grep -q '^...a' && echo 'LV_ACTIVO' || echo 'LV_INACTIVO'
ESPERADO = LV_ACTIVO
TIPO = exacto
DESCRIPCION = LV activo después de reparar VG
PESO = 5

# Validación 4: Filesystem montado y accesible
COMANDO = mount | grep '/mnt/dados' && echo 'MONTADO' || echo 'DESMONTADO'
ESPERADO = MONTADO
TIPO = exacto
DESCRIPCION = Filesystem sigue montado después de reparación
PESO = 4

# Validación 5: Tamaño del VG ajustado (~2GB de 1 disco)
COMANDO = vgs vg_degradado --noheadings --units m -o vg_size 2>/dev/null | awk '{print int($1)}' || echo '0'
RANGO_MIN = 1800
RANGO_MAX = 2200
TIPO = rango_numerico
DESCRIPCION = Tamaño del VG ajustado a ~2GB (1 disco)
PESO = 3

# Validación 6: Se puede escribir en el filesystem
COMANDO = touch /mnt/dados/test_reparacion && echo 'ESCRIBIBLE' || echo 'NO_ESCRIBIBLE'
ESPERADO = ESCRIBIBLE
TIPO = exacto
DESCRIPCION = Filesystem escribible después de reparación
PESO = 3

# ----------------------------------------------------------------------------
# LAB 015: LVM Avanzado – Conversión de partición estándar a LVM
# ----------------------------------------------------------------------------
