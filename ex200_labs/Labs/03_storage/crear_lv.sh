#!/usr/bin/env bash
# ex200_labs/Labs/03_storage/crear_lv.sh
set -euo pipefail
IFS=$'\n\t'


# =============== CARGAR MÓDULOS ===============
# ===================== RUTAS BASE =====================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../.."


# ===================== CARGA DE MÓDULOS =====================
source "${ROOT_DIR}/modules/config.sh"
source "${ROOT_DIR}/modules/utils.sh"
source "${ROOT_DIR}/modules/math_utils.sh"
source "${ROOT_DIR}/modules/display.sh"
source "${ROOT_DIR}/modules/validator.sh"
source "${ROOT_DIR}/modules/remote_ops.sh"
source "${ROOT_DIR}/modules/generators/lvm_generator.sh"
source "${ROOT_DIR}/Labs/03_storage/disk_ops.sh"



# ===================== VARIABLES GLOBALES =====================
ID=""
VG_NAME=""
LV_NAME=""
DEPARTAMENTO=""
NOMBRE_USUARIO=""
IMG1=""
IMG2=""
DISK1_MB=0
DISK2_MB=0
DISK1_GB=""
DISK2_GB=""
TOTAL_MB=0
TOTAL_GB=""
LV_SIZE_MB=0
LV_SIZE=""
LV_SIZE_GB=""
REMOTE_WORKDIR=""

TMP_REMOTE_SCRIPT=""
CLEAN_LOCAL=true
DEBUG=0


# =============== FUNCIONES AUXILIARES DEL MAIN ===============
parse_arguments() {
    for arg in "$@"; do
        case "$arg" in
            --no-clean) CLEAN_LOCAL=false ;;
            --debug) DEBUG=1 ;;
            *) ;;
        esac
    done
    dbg "Argumentos parseados: CLEAN_LOCAL=${CLEAN_LOCAL}, DEBUG=${DEBUG}"
}

validate_prerequisites() {
    require_root
    ensure_sshpass_local
    ensure_bc_local
}

setup_environment() {
    log "🚀 Iniciando generación de entorno de prácticas..."
    log "================================================"
    
    # Generar todas las variables UNA VEZ
    generate_vars
    
    # Configurar TMP_REMOTE_SCRIPT con la ruta completa
    TMP_REMOTE_SCRIPT="/tmp/remote_setup_${ID}.sh"
    dbg "TMP_REMOTE_SCRIPT configurado como: ${TMP_REMOTE_SCRIPT}"
}

run_workflow() {
    # Fase 1: Preparación local
    create_local_images
    
    # Fase 2: Configuración remota
    prepare_remote_script
    deploy_and_execute_remote
    
    # Fase 3: Persistencia
    save_json
    
    # Fase 4: Limpieza local condicional
    cleanup_local
    
    # Fase 5: Presentación al usuario
    clear
    mostrar_ticket
    read -p "Si deseas ver las instrucciones presiona ENTER: " _ENTER
    
    # Fase 6: Instrucciones
    clear
    mostrar_instrucciones
    read -p "Cuando termines la tarea en VM2 presiona ENTER para ejecutar el validador: " _ENTER
    
    # Fase 7: Validación
    clear
    remote_validator
}


# =============== FUNCIÓN PRINCIPAL ===============
main() {
    # Parsear argumentos
    parse_arguments "$@"
    
    # Validar pre-requisitos
    validate_prerequisites
    
    # Configurar entorno
    setup_environment
    
    # Ejecutar flujo principal
    run_workflow
    
    log "================================================"
    log "✅ Proceso completado."
    log "📊 Revisa el informe de validación anterior."
}




# =============== EJECUCIÓN ===============
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

storage__crear_lv() {
    main "$@"
}