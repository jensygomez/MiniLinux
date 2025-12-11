#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'



# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuración
PROJECT_DIR="${1:-.}"
declare -a IGNORE_DIRS=(".git" "node_modules" "__pycache__" ".idea" ".vscode")
declare -a IGNORE_FILES=("*.log" "*.tmp" "*.swp" "*.bak")

print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                ANALIZADOR DE PROYECTO BASH                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
}

print_item() {
    echo -e "  ${GREEN}▶${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_function() {
    echo -e "    ${PURPLE}ƒ${NC} $1"
}

get_file_type() {
    local file="$1"
    case "$file" in
        *.sh) echo "Bash Script" ;;
        *.bash) echo "Bash Script" ;;
        *.py) echo "Python" ;;
        *.js) echo "JavaScript" ;;
        *.json) echo "JSON" ;;
        *.yml|*.yaml) echo "YAML" ;;
        *.md) echo "Markdown" ;;
        *.txt) echo "Texto" ;;
        *) echo "Otro" ;;
    esac
}

count_lines() {
    local file="$1"
    if [ -f "$file" ]; then
        wc -l < "$file" | tr -d ' '
    else
        echo "0"
    fi
}

extract_functions_from_bash() {
    local file="$1"
    # Patrones para funciones en bash:
    # 1. function nombre() {
    # 2. nombre() {
    # 3. function nombre {
    grep -E '^(function\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)|function\s+[a-zA-Z_][a-zA-Z0-9_]*|[a-zA-Z_][a-zA-Z0-9_]*\s*\(\))\s*\{' "$file" 2>/dev/null | \
    sed -E 's/^function\s+//; s/\s*\(\)\s*\{.*$//; s/\s*\{.*$//; s/^\s*//; s/\s*$//' | \
    sort | uniq
}

extract_functions_from_python() {
    local file="$1"
    grep -E '^def\s+[a-zA-Z_][a-zA-Z0-9_]*' "$file" 2>/dev/null | \
    sed 's/^def\s*//; s/(.*$//' | \
    sort | uniq
}

extract_functions_from_js() {
    local file="$1"
    grep -E '^(function\s+[a-zA-Z_][a-zA-Z0-9_]*|const\s+[a-zA-Z_][a-zA-Z0-9_]*\s*=\s*\(|let\s+[a-zA-Z_][a-zA-Z0-9_]*\s*=\s*\()' "$file" 2>/dev/null | \
    sed -E 's/^function\s+//; s/^const\s+//; s/^let\s+//; s/\s*=.*$//; s/\s*\(.*$//' | \
    sort | uniq
}

analyze_file() {
    local file="$1"
    local rel_path="${file#$PROJECT_DIR/}"
    local file_type=$(get_file_type "$file")
    local line_count=$(count_lines "$file")
    
    echo -e "${YELLOW}▌ ${rel_path}${NC}"
    echo -e "  Tipo: ${file_type} | Líneas: ${line_count}"
    
    # Extraer funciones basado en el tipo de archivo
    case "$file_type" in
        "Bash Script")
            local functions=$(extract_functions_from_bash "$file")
            if [ -n "$functions" ]; then
                echo -e "  Funciones:"
                while IFS= read -r func; do
                    print_function "$func"
                done <<< "$functions"
            else
                print_warning "No se encontraron funciones"
            fi
            ;;
        "Python")
            local functions=$(extract_functions_from_python "$file")
            if [ -n "$functions" ]; then
                echo -e "  Funciones:"
                while IFS= read -r func; do
                    print_function "$func"
                done <<< "$functions"
            fi
            ;;
        "JavaScript")
            local functions=$(extract_functions_from_js "$file")
            if [ -n "$functions" ]; then
                echo -e "  Funciones:"
                while IFS= read -r func; do
                    print_function "$func"
                done <<< "$functions"
            fi
            ;;
    esac
    
    # Contar variables globales en bash (patrón simple)
    if [ "$file_type" = "Bash Script" ]; then
        local global_vars=$(grep -E '^[A-Z_][A-Z0-9_]*=' "$file" 2>/dev/null | \
                           sed 's/=.*//' | sort | uniq | wc -l)
        if [ "$global_vars" -gt 0 ]; then
            echo -e "  Variables globales: ${global_vars}"
        fi
        
        # Mostrar shebang si existe
        local shebang=$(head -1 "$file" | grep -E '^#!')
        if [ -n "$shebang" ]; then
            echo -e "  Shebang: ${shebang}"
        fi
    fi
    
    echo ""
}

should_ignore() {
    local item="$1"
    for pattern in "${IGNORE_DIRS[@]}" "${IGNORE_FILES[@]}"; do
        if [[ "$item" == $pattern ]] || [[ "$item" =~ $pattern ]]; then
            return 0
        fi
    done
    return 1
}

analyze_directory() {
    local dir="$1"
    local depth="${2:-0}"
    
    # Listar archivos y directorios
    local items=()
    while IFS= read -r item; do
        items+=("$item")
    done < <(find "$dir" -maxdepth 1 -mindepth 1 | sort)
    
    for item in "${items[@]}"; do
        local basename=$(basename "$item")
        
        # Saltar elementos ignorados
        if should_ignore "$basename"; then
            continue
        fi
        
        if [ -d "$item" ]; then
            # Es un directorio
            local dir_size=$(du -sh "$item" 2>/dev/null | cut -f1)
            echo -e "${BLUE}📁 ${basename}/${NC} (${dir_size})"
            analyze_directory "$item" $((depth + 1))
        elif [ -f "$item" ]; then
            # Es un archivo
            analyze_file "$item"
        fi
    done
}

generate_summary() {
    print_section "RESUMEN DEL PROYECTO"
    
    # Estadísticas generales
    local total_files=$(find "$PROJECT_DIR" -type f ! -path "*/.git/*" | wc -l)
    local bash_files=$(find "$PROJECT_DIR" -name "*.sh" -o -name "*.bash" | wc -l)
    local total_dirs=$(find "$PROJECT_DIR" -type d ! -path "*/.git/*" | wc -l)
    local total_size=$(du -sh "$PROJECT_DIR" 2>/dev/null | cut -f1)
    
    echo -e "📊 ${GREEN}Estadísticas:${NC}"
    print_item "Directorio analizado: $(realpath "$PROJECT_DIR")"
    print_item "Tamaño total: ${total_size}"
    print_item "Total directorios: ${total_dirs}"
    print_item "Total archivos: ${total_files}"
    print_item "Archivos Bash: ${bash_files}"
    
    # Contar funciones totales
    local total_functions=0
    while IFS= read -r file; do
        local func_count=$(extract_functions_from_bash "$file" | wc -l)
        total_functions=$((total_functions + func_count))
    done < <(find "$PROJECT_DIR" -name "*.sh" -o -name "*.bash")
    
    print_item "Funciones Bash encontradas: ${total_functions}"
    
    # Mostrar archivos ejecutables
    echo ""
    echo -e "🚀 ${GREEN}Archivos ejecutables:${NC}"
    find "$PROJECT_DIR" -type f -name "*.sh" -executable | while read -r file; do
        local rel_path="${file#$PROJECT_DIR/}"
        print_item "$rel_path"
    done
    
    # Mostrar README si existe
    echo ""
    if [ -f "$PROJECT_DIR/README.md" ]; then
        echo -e "📖 ${GREEN}README.md encontrado:${NC}"
        head -10 "$PROJECT_DIR/README.md" | while read -r line; do
            echo "  $line"
        done
    fi
}

check_bash_best_practices() {
    print_section "BUENAS PRÁCTICAS BASH"
    
    local has_issues=0
    
    # Verificar archivos bash
    while IFS= read -r file; do
        local issues=()
        
        # 1. Check for shebang
        if ! head -1 "$file" | grep -q '^#!/'; then
            issues+=("Sin shebang")
        fi
        
        # 2. Check for set -euo pipefail
        if ! grep -q 'set -euo pipefail' "$file" 2>/dev/null; then
            issues+=("Sin 'set -euo pipefail'")
        fi
        
        # 3. Check for function documentation
        if [ ${#issues[@]} -gt 0 ]; then
            echo -e "${YELLOW}▌ $(basename "$file")${NC}"
            for issue in "${issues[@]}"; do
                print_warning "$issue"
            done
            has_issues=1
            echo ""
        fi
    done < <(find "$PROJECT_DIR" -name "*.sh" -o -name "*.bash")
    
    if [ $has_issues -eq 0 ]; then
        print_item "✅ Todos los scripts siguen buenas prácticas"
    fi
}

main() {
    print_header
    
    if [ ! -d "$PROJECT_DIR" ]; then
        print_error "El directorio '$PROJECT_DIR' no existe"
        exit 1
    fi
    
    echo -e "${GREEN}Analizando: $(realpath "$PROJECT_DIR")${NC}"
    echo ""
    
    # Mostrar estructura
    print_section "ESTRUCTURA DEL PROYECTO"
    analyze_directory "$PROJECT_DIR"
    
    # Generar resumen
    generate_summary
    
    # Verificar buenas prácticas
    check_bash_best_practices
    
    # Footer
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Análisis completado el: $(date)${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
}

# Ejecutar
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi