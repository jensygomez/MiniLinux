#!/usr/bin/env bash

BASE="$HOME/MiniLinux"
echo "============================================"
echo "   DIAGNOSTICO MINI LINUX – RHCSA TRAINER"
echo "============================================"
echo "Fecha: $(date)"
echo "Base: $BASE"
echo

echo "--------------------------------------------"
echo "[1] Estructura completa (4 niveles)"
echo "--------------------------------------------"
tree -L 4 "$BASE" 2>/dev/null
echo

echo "--------------------------------------------"
echo "[2] Contenido de scripts principales"
echo "--------------------------------------------"

for f in add_lab.sh menu_labs.sh menu_modulos.sh utils.sh parser.sh; do
    if [ -f "$BASE/bin/$f" ]; then
        echo "---- bin/$f ----"
        sed 's/^/    /' "$BASE/bin/$f"
        echo
    fi
done

echo "--------------------------------------------"
echo "[3] Archivos de base de datos"
echo "--------------------------------------------"

for db in labs_index.db metadata.db progress.db stats.db; do
    if [ -f "$BASE/data/$db" ]; then
        echo "---- data/$db ----"
        sed 's/^/    /' "$BASE/data/$db"
    else
        echo "(no existe) data/$db"
    fi
    echo
done

echo "--------------------------------------------"
echo "[4] Archivo temporal detectado"
echo "--------------------------------------------"

TMP="/tmp/minilab_input.txt"
if [ -f "$TMP" ]; then
    echo "Archivo temporal encontrado: $TMP"
    sed 's/^/    /' "$TMP"
else
    echo "No hay archivo temporal en /tmp"
fi
echo

echo "--------------------------------------------"
echo "[5] Últimos 20 labs en labs_index.db"
echo "--------------------------------------------"
if [ -f "$BASE/data/labs_index.db" ]; then
    tail -n 20 "$BASE/data/labs_index.db" | sed 's/^/    /'
else
    echo "(no existe labs_index.db)"
fi
echo

echo "--------------------------------------------"
echo "[6] Directorios de módulos"
echo "--------------------------------------------"
ls -1 "$BASE/labs" 2>/dev/null | sed 's/^/    /'
echo

echo "--------------------------------------------"
echo "[7] Permisos de scripts"
echo "--------------------------------------------"
ls -l "$BASE/bin" | sed 's/^/    /'
echo

echo "============================================"
echo "   FIN DEL DIAGNOSTICO"
echo "============================================"

