#!/usr/bin/env bash
source "$(pwd)/bin/utils.sh"
LABS="$(pwd)/labs"

show_labs() {
    clear
    echo "🔬 LABORATORIOS DISPONIBLES"
    echo "=========================="
    echo "ID     | Titulo                 | Dif | Pts | Status"
    draw_line
    echo " lvm-001  | PV básico             | 1  | 20  | 🔴 Novo"
    echo " lvm-002  | VG básico             | 2  | 30  | 🔴 Novo"
    echo " users-001| Crear usuario         | 1  | 15  | 🔴 Novo"
    echo " network-001| Config IP         | 2  | 25  | 🔴 Novo"
    echo
    echo "[1-4] Practicar  [a] Agregar  [e] Editar  [x] Eliminar  [b] Volver"
}

run_lab() {
    local lab_id="$1"
    source "$(pwd)/data/vm_config.db"
    
    clear
    echo "🚀 LAB: $lab_id"
    echo "VM: $VM_USER@$VM_IP"
    echo
    echo "🔧 Preparando VM..."
    sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_IP" \
        "sudo rm -rf /tmp/lab_*; sudo mkdir -p /tmp/lab_$lab_id; sudo chown $VM_USER /tmp/lab_$lab_id" 2>/dev/null || \
        echo "⚠️  SSH falló, practica manualmente"
    
    echo "📖 ESCENARIO:"
    cat "$LABS/$lab_id/scenario.txt" 2>/dev/null || echo "Escenario faltante"
    echo
    echo "💻 ssh $VM_USER@$VM_IP"
    echo "⏳ ENTER para validar..."
    read
    
    echo "🔍 VALIDANDO..."
    if [[ -f "$LABS/$lab_id/validate.sh ]]; then
        sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_IP" "bash -s" < "$LABS/$lab_id/validate.sh" 2>/dev/null || \
            echo "⚠️  Validacion manual (ENTER=OK)"
    else
        echo "⚠️  Validacion manual"
    fi
    echo; read -p "ENTER para menu..."
}

while true; do
    show_labs
    choice=$(get_valid_input "1234aexb" "Opcion: ")
    case "${choice,,}" in
        1) run_lab "lvm-001" ;;
        2) run_lab "lvm-002" ;;
        3) run_lab "users-001" ;;
        4) run_lab "network-001" ;;
        a|e|x) echo "🔧 En desarrollo..."; sleep 2 ;;
        b) exit 0 ;;
    esac
done
