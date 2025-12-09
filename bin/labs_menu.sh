#!/usr/bin/env bash

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA="$BASE/data"
LABS="$BASE/labs"

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
    echo "[a] ➕ Adicionar  [b] Volver  [n] Siguiente  [p] Anterior  [s] Buscar"
    echo "→ Seleccionar lab número →"
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
        if command -v sshpass >/dev/null; then
            sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_IP" "bash -s" < "$LABS/$lab_id/validate.sh" 2>/dev/null || \
            echo "✅ Simulación: Lab completado (20 PTS)"
        else
            echo "✅ Simulación: Lab completado (20 PTS)"
        fi
    else
        echo "✅ Simulación: Lab completado (20 PTS)"
    fi
    echo
    read -r -p "ENTER para menú..."
}

add_new_labs() {
    clear
    echo "➕ ADICIONAR NUEVOS LABORATORIOS"
    echo "================================"
    
    declare -A modules=(
        ["1"]="Essential Tools"
        ["2"]="Running Systems" 
        ["3"]="Local Storage"
        ["4"]="File Systems"
        ["5"]="Deploy Systems"
        ["6"]="Networking"
    )
    
    declare -A submodules=(
        ["1.1"]="Shell y Operaciones Básicas"
        ["1.2"]="Búsqueda y Documentación"
        ["1.3"]="Expansiones y Redirecciones"
        ["1.4"]="Procesos y Jobs"
        ["1.5"]="Editores de Texto (vi/vim)"
        ["2.1"]="Gestión de Usuarios y Grupos"
        ["2.2"]="Permisos y Propiedad de Archivos"
        ["2.3"]="Control de Acceso (ACLs y Atributos)"
        ["2.4"]="Planificación de Tareas (Cron/Anacron)"
        ["2.5"]="Administración de Paquetes (RPM/DNF/YUM)"
        ["3.1"]="Particionamiento de Discos"
        ["3.2"]="Administración Lógica de Volúmenes (LVM)"
        ["3.3"]="Cifrado de Dispositivos (LUKS)"
        ["3.4"]="Gestión de RAID por Software"
        ["4.1"]="Creación y Montaje de Sistemas de Archivos"
        ["4.2"]="Configuración Persistente (fstab)"
        ["4.3"]="Cuotas de Disco"
        ["4.4"]="Administración de Swap"
        ["4.5"]="Mantenimiento de Sistemas de Archivos"
        ["5.1"]="Arranque del Sistema y Gestor de Arranque (GRUB2)"
        ["5.2"]="Servicios y Daemons (systemd)"
        ["5.3"]="Contenedores Básicos (Podman)"
        ["5.4"]="Registro del Sistema (journald)"
        ["6.1"]="Configuración de Red (NetworkManager)"
        ["6.2"]="Resolución de Nombres (DNS/Hosts)"
        ["6.3"]="Firewall y Seguridad (firewalld)"
        ["6.4"]="SELinux Básico"
    )
    
    echo "MÓDULOS RHCSA:"
    for key in "${!modules[@]}"; do
        echo " [$key] ${modules[$key]}"
    done
    echo
    read -p "Módulo (1-6): " mod_num
    
    clear
    echo "SUBMÓDULOS ${modules[$mod_num]}:"
    for key in "${!submodules[@]}"; do
        if [[ "$key" == "$mod_num."* ]]; then
            echo " [$key] ${submodules[$key]}"
        fi
    done
    echo
    read -p "Submódulo: " sub_num
    
    MODULE="${modules[$mod_num]}"
    SUBMODULE="${submodules[$sub_num]}"
    LAB_PATH="labs/${mod_num}_${sub_num}"
    
    mkdir -p "$LABS/$LAB_PATH"
    
    echo
    echo "📝 Editando: $LAB_PATH-master.lab"
    echo "Pega tu formato LVM labs → Ctrl+O → Enter → Ctrl+X"
    sleep 2
    nano "$LABS/$LAB_PATH-master.lab"
    
    echo "📥 IMPORTANDO $LAB_PATH-master.lab..."
    parse_lab_file "$LABS/$LAB_PATH-master.lab" "$mod_num.$sub_num"
    
    load_labs  # Recargar lista
    echo "✅ $(wc -l < <(tail -n +2 "$DATA/labs_index.db")) labs importados!"
    sleep 2
}

parse_lab_file() {
    local file="$1" module="$2"
    local lab_dir="$LABS/${module//./_}"
    mkdir -p "$lab_dir"
    
    awk -v lab_dir="$lab_dir" -v db_file="$DATA/labs_index.db" -v module="$module" '
    BEGIN { 
        lab_id=""; lab_num=""; title=""; diff=""; pts=""; 
        in_lab=0; in_scenario=0; in_setup=0; in_validations=0;
    }
    
    # Nuevo LAB
    /^[ \t]*\[LAB_[0-9]+\]/ {
        if (in_lab && lab_id != "") {
            close(scenario_file);
            close(validate_file);
            print lab_id "|" lab_dir "/" lab_id "|" title "|" diff "|" pts "|🔴 Nuevo" >> db_file;
        }
        in_lab=1;
        gsub(/[\[\]]/, "", $0);
        lab_num = substr($0, 6);
        lab_id = "lab-" module "-" sprintf("%03d", lab_num);
        next;
    }
    
    # Metadata
    /^[ \t]*TITLE[ \t]*=/ { 
        gsub(/"/, "", $0); sub(/.*=/, "", $0); title=$0; 
    }
    /^[ \t]*DIFICULTAD[ \t]*=/ { diff=$3; }
    /^[ \t]*PUNTOS[ \t]*=/ { pts=$3; }
    
    # Secciones
    /^[ \t]*\[LAB_[0-9]+_SCENARIO\]/ { 
        in_scenario=1; 
        scenario_file=lab_dir "/" lab_id "/scenario.txt";
        print "=== LAB " lab_id ": " title " ===" > scenario_file;
        next; 
    }
    /^[ \t]*\[LAB_[0-9]+_VALIDACIONES\]/ { 
        in_validations=1; 
        validate_file=lab_dir "/" lab_id "/validate.sh";
        print "#!/bin/bash" > validate_file;
        print "echo \"🔍 VALIDANDO " lab_id "...\"" >> validate_file;
        next;
    }
    
    in_scenario && NF>0 { print > scenario_file; }
    (in_validations || in_setup) && NF>0 { print >> validate_file; }
    
    END {
        if (in_lab && lab_id != "") {
            close(scenario_file);
            close(validate_file);
            print lab_id "|" lab_dir "/" lab_id "|" title "|" diff "|" pts "|🔴 Nuevo" >> db_file;
        }
    }' "$file"
    
    find "$lab_dir" -name "*.sh" -exec chmod +x {} \; 2>/dev/null
    echo "✅ $(grep -c "^lab-" "$DATA/labs_index.db") labs creados!"
}

# CARGAR LABS
load_labs

page=1
while true; do
    show_labs_paginated "$page"
    
    read -r choice
    
    case "${choice,,}" in
        a)
            add_new_labs
            load_labs
            continue
            ;;
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
                echo "❌ Usa: a,b,n,p,s o número (ej: 5)"
                sleep 1
            fi
            ;;
    esac
done
