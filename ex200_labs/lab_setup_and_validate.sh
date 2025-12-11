



#!/usr/bin/env bash
# lab_setup_and_validate.sh - Mantenido para compatibilidad
# Ahora usa la estructura modular

set -euo pipefail
IFS=$'\n\t'

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "${DIR}/main.sh" "$@"