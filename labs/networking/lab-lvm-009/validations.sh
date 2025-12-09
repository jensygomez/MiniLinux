# Validación 1: mount -a no produce errores
COMANDO = mount -a 2>&1 | grep -v 'already mounted' | wc -l
RANGO_MIN = 0
RANGO_MAX = 1
TIPO = rango_numerico
DESCRIPCION = mount -a no produce errores significativos
PESO = 3

# Validación 2: /mnt/cfg montado correctamente
COMANDO = mount | grep '/mnt/cfg' | grep -q 'vg_fstab' && echo 'MONTADO_OK' || echo 'NO_MONTADO'
ESPERADO = MONTADO_OK
TIPO = exacto
DESCRIPCION = /mnt/cfg montado correctamente
PESO = 4

# Validación 3: Entrada en fstab no usa UUID incorrecto
COMANDO = grep '/mnt/cfg' /etc/fstab | grep -q 'WRONG-UUID' && echo 'UUID_MALO' || echo 'UUID_OK'
ESPERADO = UUID_OK
TIPO = exacto
DESCRIPCION = Entrada en fstab no usa UUID incorrecto
PESO = 3

# Validación 4: Entrada en fstab es válida (usa dispositivo o UUID correcto)
COMANDO = grep '/mnt/cfg' /etc/fstab | egrep -q '(^/dev/|UUID=[a-f0-9-]+)' && echo 'ENTRADA_VALIDA' || echo 'ENTRADA_INVALIDA'
ESPERADO = ENTRADA_VALIDA
TIPO = exacto
DESCRIPCION = Entrada en fstab es válida (dispositivo o UUID)
PESO = 4

# Validación 5: Persistencia después de reboot simulado
COMANDO = umount /mnt/cfg 2>/dev/null; mount -a 2>&1; mount | grep '/mnt/cfg' && echo 'PERSISTENTE' || echo 'NO_PERSISTENTE'
ESPERADO = PERSISTENTE
TIPO = exacto
DESCRIPCION = Montaje persistente (sobrevive a umount + mount -a)
PESO = 2

# ----------------------------------------------------------------------------
# LAB 010: Extender filesystem XFS
# ----------------------------------------------------------------------------
