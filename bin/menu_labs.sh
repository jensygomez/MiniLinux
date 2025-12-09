# bin/menu_labs.sh
#!/usr/bin/env bash

BASE_DIR="$HOME/MiniLinux"
DB="$BASE_DIR/data/labs_index.db"

while true; do
    clear
    echo "==============================================="
    echo "      RHCSA MINI LINUX — LABORATORIOS"
    echo "==============================================="
    echo

    # Mostrar primeros 20 labs
    if [ -f "$DB" ]; then
        printf "%-5s %-10s %-40s\n" "ID" "Módulo" "Nombre"
        printf "%-5s %-10s %-40s\n" "-----" "----------" "----------------------------------------"

        while IFS="|" read -r id modulo nombre _; do
            printf "%-5s %-10s %-40s\n" "$id" "$modulo" "$nombre"
        done < <(head -n 20 "$DB")

    else
        echo "(sin laboratorios registrados)"
    fi

    echo
    echo "MostrarCompleta   Adicionar   Editar   Excluir   Volver"
    echo

    read -p "Seleccione opción: " op

    case "$op" in
        MostrarCompleta|mostrar|m)
            "$BASE_DIR/bin/list_labs.sh"
            read -p "ENTER para continuar..."
        ;;
        Adicionar|adicionar|a)
            "$BASE_DIR/bin/add_lab.sh"
        ;;
        Editar|editar|e)
            "$BASE_DIR/bin/edit_lab.sh"
        ;;
        Excluir|excluir|x)
            "$BASE_DIR/bin/delete_lab.sh"
        ;;
        Volver|volver|v)
            exit 0
        ;;
        *)
            echo "Opción inválida"; sleep 1 ;;
    esac
done
