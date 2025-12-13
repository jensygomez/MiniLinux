#!/usr/bin/env bash
# ex200_labs/Labs/05_selinux/lab_01_boolean/config.sh



# =============================================================
#  EX200 LAB CONFIGURATION FILE
#  LAB: lab_01_boolean
# =============================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================
#  IDENTIDAD DEL LABORATORIO
# =============================================================
LAB_ID="lab_01_boolean"
LAB_CATEGORY="selinux"
LAB_TITLE="SELinux Booleans"
LAB_DESCRIPTION="Administración y persistencia de SELinux booleans para servicios comunes"
LAB_VERSION="1.0"

# =============================================================
#  NIVELES DE DIFICULTAD
# =============================================================
# 1 = Basico
# 2 = Intermedio
# 3 = Avanzado
# 4 = Super Avanzado
LAB_DIFFICULTY_LEVEL=$(shuf -i 1-4 -n 1)

declare -A LAB_DIFFICULTY_NAME=(
    [1]="Basico"
    [2]="Intermedio"
    [3]="Avanzado"
    [4]="Super Avanzado"
)

# =============================================================
#  CONEXIÓN REMOTA (VM OBJETIVO)
# =============================================================
REMOTE_HOST="192.168.122.110"
REMOTE_USER="student"
REMOTE_PASS="redhat"

# =============================================================
#  REGLAS DEL LABORATORIO
# =============================================================
REQUIRES_PERSISTENCE=true        # Se espera uso de setsebool -P
ALLOW_TEMPORARY_CHANGES=false   # No se aceptan cambios sin persistencia
TIME_LIMIT_MINUTES=45

# =============================================================
#  POLÍTICAS SEGÚN DIFICULTAD
# =============================================================
# Estas variables son leídas por generator.sh
case "$LAB_DIFFICULTY_LEVEL" in
    1)  # BASICO
        MIN_BOOLEANS=1
        MAX_BOOLEANS=2
        REQUIRE_SERVICE_VALIDATION=false
        INCLUDE_TROUBLESHOOTING=false
        ;;
    2)  # INTERMEDIO
        MIN_BOOLEANS=2
        MAX_BOOLEANS=3
        REQUIRE_SERVICE_VALIDATION=true
        INCLUDE_TROUBLESHOOTING=false
        ;;
    3)  # AVANZADO
        MIN_BOOLEANS=3
        MAX_BOOLEANS=4
        REQUIRE_SERVICE_VALIDATION=true
        INCLUDE_TROUBLESHOOTING=true
        ;;
    4)  # SUPER AVANZADO
        MIN_BOOLEANS=4
        MAX_BOOLEANS=5
        REQUIRE_SERVICE_VALIDATION=true
        INCLUDE_TROUBLESHOOTING=true
        REQUIRE_AUDIT_LOG_ANALYSIS=true
        ;;
    *)
        echo "ERROR: Nivel de dificultad inválido"
        exit 1
        ;;
esac

# =============================================================
#  BOOLEANS DISPONIBLES (EX200-ALIGNED)
# =============================================================
# Esta lista es la única fuente permitida
AVAILABLE_BOOLEANS=(
    "httpd_can_network_connect"
    "httpd_enable_homedirs"
    "ftp_home_dir"
    "samba_enable_home_dirs"
)

# =============================================================
#  SERVICIOS RELACIONADOS
# =============================================================
SERVICE_MAP=(
    "httpd_can_network_connect:httpd"
    "httpd_enable_homedirs:httpd"
    "ftp_home_dir:vsftpd"
    "samba_enable_home_dirs:smb"
)

# =============================================================
#  FLAGS OPERATIVOS
# =============================================================
DEBUG_MODE=false
CLEANUP_AFTER_RUN=false
LOG_PATH="/tmp/selinux_${LAB_ID}.log"

# =============================================================
#  FUNCIÓN DE DEBUG (USO INTERNO)
# =============================================================
debug() {
    [[ "$DEBUG_MODE" == "true" ]] && echo "[DEBUG] $*"
}
