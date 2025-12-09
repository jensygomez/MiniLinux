adicionar_lab() {
    local MODULOS=(
        "1) Storage (LVM, FS, Mounts)"
        "2) Users and Groups"
        "3) Networking"
        "4) SELinux"
        "5) Services and Systemd"
        "6) Containers"
    )

    clear
    echo "==============================================="
    echo "     RHCSA MINI LINUX — ADICIONAR LABORATORIO"
    echo "==============================================="
    echo ""
    echo "Seleccione el módulo donde se clasificará el laboratorio:"
    echo ""

    for m in "${MODULOS[@]}"; do
        echo "  $m"
    done

    echo ""
    read -rp "Ingrese número del módulo: " modulo_sel

    case "$modulo_sel" in
        1) MODULO_NAME="Storage" ;;
        2) MODULO_NAME="Users" ;;
        3) MODULO_NAME="Networking" ;;
        4) MODULO_NAME="SELinux" ;;
        5) MODULO_NAME="Services" ;;
        6) MODULO_NAME="Containers" ;;
        *)
            echo "Opción inválida."
            sleep 1
            return
            ;;
    esac

    # Archivo temporal donde el usuario pegará el laboratorio
    TEMP_FILE="/tmp/newlab_$$.txt"
    > "$TEMP_FILE"

    echo ""
    echo "==============================================="
    echo "    Ahora se abrirá NANO."
    echo " Pegue aquí el contenido completo del laboratorio."
    echo " Guardar: CTRL+O  |  Salir: CTRL+X"
    echo "==============================================="
    echo ""
    read -rp "Presione ENTER para continuar..."

    nano "$TEMP_FILE"

    # Validar contenido
    if [[ ! -s "$TEMP_FILE" ]]; then
        echo "Laboratorio vacío. Cancelando."
        rm -f "$TEMP_FILE"
        sleep 1
        return
    fi

    # Extraer título (primera línea no vacía)
    TITLE=$(grep -m1 . "$TEMP_FILE")
    TITLE=${TITLE//|/ -}  # limpiar pipes

    # Crear ID único
    local INDEX="$HOME/MiniLinux/data/labs_index.db"
    if [[ ! -f "$INDEX" ]]; then
        echo "001|PLACEHOLDER|PLACE|Easy|2025-01-01" > "$INDEX"
    fi

    local LAST_ID
    LAST_ID=$(tail -n1 "$INDEX" | cut -d '|' -f1)
    NEW_ID=$(printf "%03d" $((10#$LAST_ID + 1)))

    LAB_DIR="$HOME/MiniLinux/labs/LAB$NEW_ID"
    mkdir -p "$LAB_DIR"

    # Crear archivos
    cp "$HOME/MiniLinux/labs/template_scenario.txt" "$LAB_DIR/scenario.txt"
    cp "$HOME/MiniLinux/labs/template_setup.sh" "$LAB_DIR/setup.sh"
    cp "$HOME/MiniLinux/labs/template_validations.sh" "$LAB_DIR/validations.sh"

    # metadata.db
    cat <<EOF > "$LAB_DIR/metadata.db"
ID=$NEW_ID
TITLE=$TITLE
MODULE=$MODULO_NAME
CREATED=$(date +%F)
EOF

    # Extraer texto del usuario como scenario
    cp "$TEMP_FILE" "$LAB_DIR/scenario.txt"

    chmod +x "$LAB_DIR/setup.sh"
    chmod +x "$LAB_DIR/validations.sh"

    # Añadir al índice principal
    echo "$NEW_ID|$TITLE|$MODULO_NAME|Easy|$(date +%F)" >> "$INDEX"

    rm -f "$TEMP_FILE"

    clear
    echo "==============================================="
    echo "   Laboratorio LAB$NEW_ID fue creado con éxito"
    echo "==============================================="
    echo "Título: $TITLE"
    echo "Módulo: $MODULO_NAME"
    echo "Ubicación: $LAB_DIR"
    echo ""
    read -rp "Presione ENTER para volver..."
}
