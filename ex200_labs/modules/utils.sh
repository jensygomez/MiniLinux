
#!/usr/bin/env bash
# utils.sh - Funciones utilitarias generales

log() { printf "%s\n" "$*"; }
dbg() { if [ "$DEBUG" -eq 1 ]; then printf "[DEBUG] %s\n" "$*"; fi }

require_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Ejecuta como root: sudo bash $0"
    exit 1
  fi
}



mb_to_gb() {
  local mb=$1
  local gb=$(echo "scale=2; $mb / 1024" | bc)
  printf "%s" "$gb"
}

ensure_sshpass_local() {
  if ! command -v sshpass &>/dev/null; then
    log "[*] sshpass no encontrado en VM1 — intentando instalar..."
    if command -v apt-get &>/dev/null; then
      apt-get update -y && apt-get install -y sshpass || true
    elif command -v dnf &>/dev/null; then
      dnf install -y epel-release sshpass || true
    elif command -v yum &>/dev/null; then
      yum install -y epel-release sshpass || true
    fi
    if ! command -v sshpass &>/dev/null; then
      echo "ERROR: sshpass no pudo instalarse. Instálalo manualmente en VM1."
      exit 1
    fi
  fi
}

ensure_bc_local() {
  if ! command -v bc &>/dev/null; then
    log "[*] bc no encontrado en VM1 — intentando instalar..."
    if command -v apt-get &>/dev/null; then
      apt-get update -y && apt-get install -y bc || true
    elif command -v dnf &>/dev/null; then
      dnf install -y bc || true
    elif command -v yum &>/dev/null; then
      yum install -y bc || true
    fi
    if ! command -v bc &>/dev/null; then
      echo "ERROR: bc no pudo instalarse. Instálalo manualmente en VM1."
      exit 1
    fi
  fi
}