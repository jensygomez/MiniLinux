#!/usr/bin/env bash
BASE="$(pwd)"
DATA="$BASE/data"
BIN="$BASE/bin"
LABS="$BASE/labs"

draw_line() { printf '=%.0s' {1..50}; echo; }
get_valid_input() {
    local valid="$1" prompt="$2" choice
    while true; do
        read -p "$prompt" -n1 choice; echo
        [[ "${choice,,}" =~ ^[$valid]$ ]] && { echo "$choice"; return; }
        echo "❌ Use: [$valid]"; sleep 1
    done
}

ssh_exec() {
    source "$DATA/vm_config.db"
    command -v sshpass >/dev/null || { echo "❌ Instala: sudo apt install sshpass"; return 1; }
    sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_IP" "$1" 2>/dev/null
}
