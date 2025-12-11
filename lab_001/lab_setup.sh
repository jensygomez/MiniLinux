#!/usr/bin/env bash
# lab_setup.sh - Wrapper simple para mantener compatibilidad
# Este script llama al nuevo main.sh modularizado



SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ejecutar el main modularizado
exec bash "${SCRIPT_DIR}/main.sh" "$@"