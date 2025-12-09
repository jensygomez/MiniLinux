#!/bin/bash
# Script para mostrar estructura de directorios y archivos
# Uso: ./ver_estructura.sh [directorio] [profundidad]

# Configuración por defecto
DIRECTORIO="${1:-.}"       # Directorio actual por defecto
PROFUNDIDAD="${2:-2}"      # Profundidad por defecto: 2 niveles

# Validar que el directorio existe
if [ ! -d "$DIRECTORIO" ]; then
    echo "Error: El directorio '$DIRECTORIO' no existe."
    exit 1
fi

# Validar que la profundidad sea un número positivo
if ! [[ "$PROFUNDIDAD" =~ ^[0-9]+$ ]] || [ "$PROFUNDIDAD" -lt 1 ]; then
    echo "Error: La profundidad debe ser un número positivo."
    exit 1
fi

echo "================================================"
echo "ESTRUCTURA DE CARPETAS Y ARCHIVOS"
echo "Directorio: $(realpath "$DIRECTORIO")"
echo "Profundidad: $PROFUNDIDAD niveles"
echo "Fecha: $(date)"
echo "================================================"
echo ""

# Función recursiva para mostrar estructura
mostrar_estructura() {
    local dir="$1"
    local nivel="$2"
    local max_nivel="$3"
    
    # Si hemos alcanzado la profundidad máxima, salir
    if [ "$nivel" -gt "$max_nivel" ]; then
        return
    fi
    
    # Crear sangría basada en el nivel
    local sangria=""
    for ((i=1; i<nivel; i++)); do
        sangria="$sangria│   "
    done
    
    # Obtener nombre del directorio actual (sin ruta)
    local nombre_dir=$(basename "$dir")
    
    # Mostrar directorio actual
    if [ "$nivel" -eq 1 ]; then
        echo "📁 $nombre_dir/"
    else
        echo "${sangria}├── 📁 $nombre_dir/"
    fi
    
    # Verificar si podemos leer el directorio
    if [ ! -r "$dir" ]; then
        echo "${sangria}│   └── [Sin permisos de lectura]"
        return
    fi
    
    # Contadores para estadísticas básicas
    local contador_dir=0
    local contador_archivos=0
    
    # Ordenar por tipo (directorios primero, luego archivos)
    # y alfabéticamente
    while IFS= read -r entrada; do
        # Saltar si está vacío
        [ -z "$entrada" ] && continue
        
        ruta_completa="$dir/$entrada"
        
        # Determinar si es directorio o archivo
        if [ -d "$ruta_completa" ]; then
            # Es un directorio
            contador_dir=$((contador_dir + 1))
            
            # Crear sangría para este nivel
            local nueva_sangria="$sangria│   "
            if [ "$nivel" -eq "$max_nivel" ]; then
                nueva_sangria="$sangria    "
            fi
            
            # Mostrar directorio (recursivamente)
            if [ "$nivel" -lt "$max_nivel" ]; then
                mostrar_estructura "$ruta_completa" $((nivel + 1)) "$max_nivel"
            else
                # Si es el último nivel, mostrar solo el nombre
                echo "${sangria}│   ├── 📁 $entrada/"
            fi
            
        elif [ -f "$ruta_completa" ] || [ -L "$ruta_completa" ]; then
            # Es un archivo o enlace simbólico
            contador_archivos=$((contador_archivos + 1))
            
            # Icono según tipo de archivo
            local icono="📄"  # Archivo regular por defecto
            
            if [ -L "$ruta_completa" ]; then
                icono="🔗"  # Enlace simbólico
            elif [ -x "$ruta_completa" ]; then
                icono="⚙️ "  # Ejecutable
            elif [[ "$entrada" =~ \.(sh|bash)$ ]]; then
                icono="📜"  # Script
            elif [[ "$entrada" =~ \.(txt|md)$ ]]; then
                icono="📝"  # Texto
            elif [[ "$entrada" =~ \.(jpg|jpeg|png|gif)$ ]]; then
                icono="🖼️ "  # Imagen
            elif [[ "$entrada" =~ \.(pdf)$ ]]; then
                icono="📕"  # PDF
            elif [[ "$entrada" =~ \.(zip|tar|gz|bz2)$ ]]; then
                icono="📦"  # Comprimido
            fi
            
            # Mostrar archivo
            echo "${sangria}│   ├── $icono $entrada"
        fi
        
    done < <(cd "$dir" && ls -1A | sort)
    
    # Mostrar línea final si hay contenido
    if [ $contador_dir -gt 0 ] || [ $contador_archivos -gt 0 ]; then
        echo "${sangria}│"
    fi
    
    # Mostrar resumen básico para el directorio actual (opcional)
    if [ "$nivel" -eq 1 ] && [ "$PROFUNDIDAD" -gt 1 ]; then
        echo ""
        echo "================================================"
        echo "RESUMEN:"
        echo "  Directorios: $contador_dir"
        echo "  Archivos: $contador_archivos"
        echo "================================================"
    fi
}

# Llamar a la función principal
mostrar_estructura "$DIRECTORIO" 1 "$PROFUNDIDAD"

# Versión alternativa simple usando find (descomentar si prefieres)
# echo ""
# echo "================================================"
# echo "VERSIÓN SIMPLE (con find):"
# echo "================================================"
# find "$DIRECTORIO" -maxdepth "$PROFUNDIDAD" -type d -print | sort | sed -e "s;[^/]*/;|____;g" -e "s;____|; |;g"