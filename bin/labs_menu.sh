#!/usr/bin/env bash

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABS="$BASE/labs"
DATA="$BASE/data"

show_labs() {
    clear
    echo "🔬 LABORATORIOS DISPONIBLES"
    echo "=========================="
    echo "ID     | Titulo                 | Dif | Pts | Status"
    echo "--------------------------------------------------"
    echo " lvm-001  | PV básico             | 1  | 20  | 🔴 Nuevo"
    echo " lvm-002  | VG básico             | 2  | 30  | 🔴 Nuevo"
    echo " users-001| Crear usuario         | 1  | 15  | 🔴 Nuevo"
    echo " network-001| Config IP         | 2  | 25  | 🔴 Nuevo"
    echo
    echo "[1] LVM-001  [2] LVM-002  [3] Users  [4] Network"
    echo "[b] Volver al menú principal"
    echo
}

run_lab() {
    local lab_id="$1"
    source "$DATA/vm_config.db"
    
    clear
    echo "🚀 INICIANDO LAB: $lab_id"
    echo "========================"
    echo "VM: $VM_USER@$VM_IP"
    echo
    echo "🔧 Preparando VM para $lab_id..."
    echo "💻 Conéctate: ssh $VM_USER@$VM_IP"
    echo
    echo "📖 ESCENARIO:"
    cat "$LABS/$lab_id/scenario.txt" 2>/dev/null || echo "Archivo de escenario no encontrado"
    echo
    echo "⏳ Haz los comandos y presiona ENTER para validar..."
    read
    echo
    echo "🔍 VALIDANDO..."
    echo "✅ Simulación: Laboratorio completado (20 PTS)"
    echo "🎉 ¡ÉXITO!"
    sleep 2
    echo
    read -p "ENTER para volver al menú de labs..."
}

while true; do
    show_labs
    read -p "Opción (1-4,b): " -n1 choice
    echo
    
    case "${choice,,}" in
        1)
            run_lab "lvm-001"
            ;;
        2)
            run_lab "lvm-002"
            ;;
        3)
            run_lab "users-001"
            ;;
        4)
            run_lab "network-001"
            ;;
        b)
            echo "👋 Volviendo al menú principal..."
            sleep 1
            exit 0
            ;;
        *)
            echo "❌ Opción inválida. Usa: 1-4 o b"
            sleep 1
            ;;
    esac
done
