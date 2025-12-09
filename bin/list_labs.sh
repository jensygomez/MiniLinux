listar_labs() {
    local LABS_FILE="$HOME/MiniLinux/data/labs_index.db"
    local PAGE_SIZE=20
    local page=1

    if [[ ! -f "$LABS_FILE" ]]; then
        echo "No existe el archivo $LABS_FILE"
        return
    fi

    local total_lines
    total_lines=$(wc -l < "$LABS_FILE")
    local total_pages=$(( (total_lines + PAGE_SIZE - 1) / PAGE_SIZE ))

    while true; do
        clear
        echo "==============================================="
        echo "        RHCSA MINI LINUX — LABORATÓRIOS"
        echo "==============================================="
        echo "Página $page de $total_pages"
        echo ""

        # Calcular el rango de la página actual
        local start=$(( (page - 1) * PAGE_SIZE + 1 ))
        local end=$(( start + PAGE_SIZE - 1 ))

        # Imprimir encabezado de la tabla
        printf "%-5s %-35s %-12s %-12s %-12s\n" "ID" "Nombre" "Módulo" "Dificultad" "Fecha"
        printf "%-5s %-35s %-12s %-12s %-12s\n" "-----" "-----------------------------------" "-----------" "-----------" "-----------"

        # Mostrar los laboratorios de esta página
        sed -n "${start},${end}p" "$LABS_FILE" | while IFS='|' read -r id name mod diff date; do
            printf "%-5s %-35s %-12s %-12s %-12s\n" "$id" "$name" "$mod" "$diff" "$date"
        done

        echo ""
        echo "[N] Siguiente página   [P] Anterior   [V] Volver"
        echo ""
        printf "Selecciona una opción: "
        read -r option

        case "$option" in
            N|n)
                if (( page < total_pages )); then
                    ((page++))
                fi
                ;;
            P|p)
                if (( page > 1 )); then
                    ((page--))
                fi
                ;;
            V|v)
                break
                ;;
        esac
    done
}
