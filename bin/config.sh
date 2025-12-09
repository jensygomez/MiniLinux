#!/usr/bin/env bash
source "$(pwd)/bin/utils.sh"
source "$(pwd)/data/vm_config.db" 2>/dev/null || true

clear
echo "⚙️  CONFIGURACIONES VM"
echo "====================="
echo "VM actual: ${VM_USER:-?}@${VM_IP:-?}"
echo

read -p "IP ["${VM_IP:-192.168.122.143}"]: " new_ip
[[ -n "$new_ip" ]] && VM_IP="$new_ip"

read -p "Usuario ["${VM_USER:-student}"]: " new_user  
[[ -n "$new_user" ]] && VM_USER="$new_user"

read -s -p "Senha [Enter=mantiene]: " new_pass; echo
[[ -n "$new_pass" ]] && VM_PASS="$new_pass"

cat > "$(pwd)/data/vm_config.db" << EOF
VM_IP="$VM_IP"
VM_USER="$VM_USER"
VM_PASS="$VM_PASS"
