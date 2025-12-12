#!/usr/bin/env bash
# ==============================================================================
#  Archivo: math_utils.sh
#  Ubicación recomendada:
#     /home/jensy/MiniLinux/ex200_labs/modules/math_utils.sh
#
#  Descripción:
#     Módulo matemático centralizado. Contiene todas las funciones relacionadas
#     con cálculos numéricos, conversiones de unidades, porcentajes, selección
#     aleatoria y validaciones aritméticas.
#
#  Uso recomendado:
#     source "/home/jensy/MiniLinux/ex200_labs/modules/math_utils.sh"
#
#  Uso relativo dentro del proyecto:
#     source "$(dirname "$0")/../math_utils.sh"
#
#  Uso autodetectando el root del proyecto:
#     PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
#     source "${PROJECT_ROOT}/modules/math_utils.sh"
#
#  Todas las funciones:
#     - NO dependen del contexto, ni variables globales.
#     - Devuelven resultados siempre por stdout.
#     - Están preparadas para ser usadas por cualquier módulo del sistema.
#
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# ==============================================================================
#  VALIDACIONES
# ==============================================================================

# ------------------------------------------------------------------------------
#  Función: is_number
#  Descripción:
#     Verifica si el argumento es un número entero válido.
#
#  Uso:
#       is_number "123"   -> return 0
#       is_number "abc"   -> return 1
#
#  Retorno:
#       0 si es número, 1 si no lo es.
# ------------------------------------------------------------------------------
is_number() {
    [[ "$1" =~ ^-?[0-9]+$ ]]
}

# ==============================================================================
#  OPERACIONES ARITMÉTICAS
# ==============================================================================

# ------------------------------------------------------------------------------
# add: suma dos números
# Ejemplo: add 3 5   -> 8
# ------------------------------------------------------------------------------
add() {
    echo $(( $1 + $2 ))
}

# ------------------------------------------------------------------------------
# sub: resta dos números
# Ejemplo: sub 10 3  -> 7
# ------------------------------------------------------------------------------
sub() {
    echo $(( $1 - $2 ))
}

# ------------------------------------------------------------------------------
# mul: multiplica dos números
# Ejemplo: mul 4 6   -> 24
# ------------------------------------------------------------------------------
mul() {
    echo $(( $1 * $2 ))
}

# ------------------------------------------------------------------------------
# div: divide dos enteros
# Nota: división entera, trunca decimales.
# Ejemplo: div 7 2   -> 3
# ------------------------------------------------------------------------------
div() {
    echo $(( $1 / $2 ))
}

# ==============================================================================
#  COMPARACIONES
# ==============================================================================

# ------------------------------------------------------------------------------
# min: devuelve el menor de los dos valores
# Ejemplo: min 10 3  -> 3
# ------------------------------------------------------------------------------
min() {
    (( $1 <= $2 )) && echo "$1" || echo "$2"
}

# ------------------------------------------------------------------------------
# max: devuelve el mayor de los dos valores
# Ejemplo: max 10 3  -> 10
# ------------------------------------------------------------------------------
max() {
    (( $1 >= $2 )) && echo "$1" || echo "$2"
}

# ==============================================================================
#  CONVERSIONES DE UNIDADES
# ==============================================================================

# ------------------------------------------------------------------------------
# mb_to_gb
# Conversión: MB → GB usando 1024
# Ejemplo: mb_to_gb 2048  -> 2
# ------------------------------------------------------------------------------
mb_to_gb() {
    echo $(( $1 / 1024 ))
}

# ------------------------------------------------------------------------------
# gb_to_mb
# Conversión: GB → MB
# Ejemplo: gb_to_mb 2  -> 2048
# ------------------------------------------------------------------------------
gb_to_mb() {
    echo $(( $1 * 1024 ))
}

# ==============================================================================
#  PORCENTAJES
# ==============================================================================

# ------------------------------------------------------------------------------
# percentage:
#   Calcula el porcentaje entero de un número base.
#
# Ejemplo:
#    percentage 200 10  -> 20
# ------------------------------------------------------------------------------
percentage() {
    echo $(( $1 * $2 / 100 ))
}

# ------------------------------------------------------------------------------
# apply_percentage:
#   Igual que percentage, alias más semántico.
# ------------------------------------------------------------------------------
apply_percentage() {
    percentage "$1" "$2"
}

# ==============================================================================
#  ALEATORIEDAD
# ==============================================================================

# ------------------------------------------------------------------------------
# rand_between:
#   Devuelve un entero aleatorio entre min y max (incluyendo ambos).
#
# Ejemplo:
#    rand_between 5 10 -> 7
# ------------------------------------------------------------------------------
rand_between() {
    local min="$1"
    local max="$2"
    echo $(( RANDOM % (max - min + 1) + min ))
}

# ------------------------------------------------------------------------------
# rand_percentage_range:
#   Permite definir rangos como 60–100%
# Ejemplo:
#    rand_percentage_range 60 100 -> 74
# ------------------------------------------------------------------------------
rand_percentage_range() {
    rand_between "$1" "$2"
}

# ------------------------------------------------------------------------------
# rand_size_mb:
#   Usa MIN_MB y MAX_MB del caller.
#   Devuelve un tamaño MB dentro del rango.
# ------------------------------------------------------------------------------
rand_size_mb() {
    local range=$(( MAX_MB - MIN_MB + 1 ))
    echo $(( RANDOM % range + MIN_MB ))
}

# ------------------------------------------------------------------------------
# percent_random:
#   Devuelve un porcentaje entre 60 y 100.
# ------------------------------------------------------------------------------
percent_random() {
    rand_percentage_range 60 100
}

# ------------------------------------------------------------------------------
# rand_from_list:
#   Devuelve un elemento al azar de un arreglo.
#
# Ejemplo:
#    rand_from_list "${COLORS[@]}"
# ------------------------------------------------------------------------------
rand_from_list() {
    local arr=("$@")
    echo "${arr[RANDOM % ${#arr[@]}]}"
}
