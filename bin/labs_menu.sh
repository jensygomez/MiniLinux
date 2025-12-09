#!/usr/bin/env bash

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA="$BASE/data"
LABS="$BASE/labs"

# CARGAR LABS DESDE DB REAL
load_labs() {
    mapfile -t labs < <(grep -v '^#' "$DATA/labs_index.db" | cut -d'|' -f1)
}

show_labs_paginated() {
    local page=${1:-1} per_page=10
    local total=${#labs[@]} start=$(( (page-1)*per_page )) end=$(( start+per_page ))
    
    clear
    echo "🔬 LABORATORIOS ($total total) - Página $page"
    echo "========================================"
    echo "ID      | Título                  | Pts | Status"
    echo "------------------------------------------------"
    
    for i in $(seq $start $((end-1 < ${#labs[@]} ? end-1 : ${#labs[@]}-1 ))); do
        id="${labs[$i]}"
        echo " [$((i+1))] $id"
    done
    
    echo
    echo "[b] Volver  [n] Siguiente  [p] Anterior  [s] Buscar"
    echo "[ENTER] Seleccionar lab número →"
}

search_lab() {
    echo "🔍 Buscar lab (ej: lvm, user):"
    read -r query
    mapfile -t results < <(grep -i "$query" "$DATA/labs_index.db" | cut -d'|' -f1)
    
    if [[ ${#results[@]} -eq 0 ]]; then
        echo "❌ No encontrado"
        sleep 1
        return
    fi
    
    echo "Resultados:"
    for i in "${!results[@]}"; do
        echo " [$((i+1))] ${results[$i]}"
    done
    read -p "Seleccionar (1-${#results[@]}): " num
    run_lab "${results[$((num-1))]}"
}

run_lab() {
    local lab_id="$1"
    source "$DATA/vm_config.db"
    
    clear
    echo "🚀 LAB: $lab_id"
    echo "VM: $VM_USER@$VM_IP"
    
    echo "📖 ESCENARIO:"
    cat "$LABS/$lab_id/scenario.txt" 2>/dev/null || echo "Escenario faltante"
    echo
    echo "💻 ssh $VM_USER@$VM_IP"
    read -p "ENTER para validar..."
    
    echo "🔍 VALIDANDO..."
    if [[ -f "$LABS/$lab_id/validate.sh ]]; then
        sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_IP" "bash -s" < "$LABS/$lab_id/validate.sh" 2>/dev/null
    fi
    read -p "ENTER para menú..."
}

# CARGAR LABS
load_labs

page=1
while true; do
    show_labs_paginated $page
    
    read -r -p "→ " choice
    
    case "${choice,,}" in
        b) exit 0 ;;
        n) ((page++)); continue ;;
        p) ((page>1)) && ((page--)); continue ;;
        s) search_lab; continue ;;
        [0-9]*)
            num=$((choice-1))
            if [[ $num -ge 0 && $num -lt ${#labs[@]} ]]; then
                run_lab "${labs[$num]}"
            else
                echo "❌ Número inválido"
                sleep 1
            fi
            ;;
        "") continue ;;
        *) echo "❌ Usa: b,n,p,s o número"; sleep 1 ;;
    esac
done
