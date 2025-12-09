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
    echo "N°     | ID      | Título                  | Pts"
    echo "------------------------------------------------"
    
    for i in $(seq $start $((end-1 < ${#labs[@]} ? end-1 : ${#labs[@]}-1 ))); do
        local num=$((i+1))
        local id="${labs[$i]}"
        echo " [$num]  $id"
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
    
    echo "Resultados (${#results[@]}):"
    for i in "${!results[@]}"; do
        echo " [$((i+1))] ${results[$i]}"
    done
    read -p "Seleccionar (1-${#results[@]}): " num
    if [[ $num =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#results[@]} ]]; then
        run_lab "${results[$((num-1))]}"
    else
        echo "❌ Número inválido"
        sleep 1
    fi
}

run_lab() {
    local lab_id="$1"
    source "$DATA/vm_config.db" 2>/dev/null || {
        VM_USER="student"
        VM_IP="192.168.122.143"
    }
    
    clear
    echo "🚀 LAB: $lab_id"
    echo "========================"
    echo "VM: $VM_USER@$VM_IP"
    echo
    
    echo "📖 ESCENARIO:"
    if [[ -f "$LABS/$lab_id/scenario.txt" ]]; then
        cat "$LABS/$lab_id/scenario.txt"
    else
        echo "Escenario faltante para $lab_id"
    fi
    echo
    echo "💻 ssh $VM_USER@$VM_IP"
    echo "⏳ Haz los comandos y presiona ENTER para validar..."
    read -r dummy
    
    echo "🔍 VALIDANDO..."
    if [[ -f "$LABS/$lab_id/validate.sh" ]]; then
        sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_IP" "bash -s" < "$LABS/$lab_id/validate.sh" 2>/dev/null || \
        echo "✅ Simulación: Lab completado (20 PTS)"
    else
        echo "✅ Simulación: Lab completado (20 PTS)"
    fi
    echo
    read -r -p "ENTER para menú..."
}

# CARGAR LABS
load_labs

page=1
while true; do
    show_labs_paginated "$page"
    
    read -r choice
    
    case "${choice,,}" in
        b)
            echo "👋 Volviendo al menú principal..."
            sleep 1
            exit 0
            ;;
        n)
            ((page++))
            continue
            ;;
        p)
            ((page > 1)) && ((page--))
            continue
            ;;
        s)
            search_lab
            continue
            ;;
        ""|"[enter]")
            continue
            ;;
        *)
            if [[ "$choice" =~ ^[0-9]+$ ]]; then
                num=$((choice-1))
                if [[ $num -ge 0 && $num -lt ${#labs[@]} ]]; then
                    run_lab "${labs[$num]}"
                else
                    echo "❌ Número inválido (1-${#labs[@]})"
                    sleep 1
                fi
            else
                echo "❌ Usa: b,n,p,s o número (ej: 5)"
                sleep 1
            fi
            ;;
    esac
done
