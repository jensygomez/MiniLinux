#!/usr/bin/env bash

# =======================================================
#  RHCSA MINI LINUX — Instalador Oficial
#  Autor: Jensy Gomez (2025)
#  100% Bash puro
# =======================================================

BASE="/opt/rhcsa-mini-linux"

echo "🚀 Instalando RHCSA Mini Linux em: $BASE"
sudo mkdir -p "$BASE"

# ==========================
# Criando subpastas
# ==========================
echo "🔧 Criando diretórios..."
sudo mkdir -p "$BASE/bin"
sudo mkdir -p "$BASE/data"
sudo mkdir -p "$BASE/labs"
sudo mkdir -p "$BASE/logs/lab_runs"
sudo mkdir -p "$BASE/system"

# ==========================
# Criar base de dados inicial
# ==========================
echo "📁 Criando base de dados inicial..."
sudo tee "$BASE/data/labs_index.db" >/dev/null <<EOF
# id_lab=path
EOF

sudo tee "$BASE/data/progress.db" >/dev/null <<EOF
# progresso global dos laboratórios
EOF

sudo tee "$BASE/data/stats.db" >/dev/null <<EOF
# estatísticas globais
total_labs=0
labs_completos=0
EOF

sudo tee "$BASE/data/metadata.db" >/dev/null <<EOF
system_name=RHCSA Mini Linux
version=1.0
created=$(date +"%Y-%m-%d")
EOF


# ==========================
# Template: metadata.db
# ==========================
sudo tee "$BASE/labs/template_metadata.db" >/dev/null <<EOF
id=
title=
difficulty=
reps_required=
points=
version=1.0
EOF


# ==========================
# Template: scenario.txt
# ==========================
sudo tee "$BASE/labs/template_scenario.txt" >/dev/null <<EOF
Descreva o cenário do laboratório aqui.
EOF


# ==========================
# Template: setup.sh
# ==========================
sudo tee "$BASE/labs/template_setup.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash
# Configuração inicial do laboratório
EOF
sudo chmod +x "$BASE/labs/template_setup.sh"


# ==========================
# Template: validations.sh
# ==========================
sudo tee "$BASE/labs/template_validations.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash
# Validações do laboratório
EOF
sudo chmod +x "$BASE/labs/template_validations.sh"


# ==========================
# Script: utils.sh
# ==========================
sudo tee "$BASE/bin/utils.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash

draw_line() {
    printf '%*s\n' "${1:-40}" '' | tr ' ' '-'
}

print_table_header() {
    echo "ID   | Título"
    draw_line 40
}
EOF
sudo chmod +x "$BASE/bin/utils.sh"


# ==========================
# Script: menu.sh (menu inicial)
# ==========================
sudo tee "$BASE/bin/menu.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash

BASE="/opt/rhcsa-mini-linux"
DATA="$BASE/data"
BIN="$BASE/bin"
LABS="$BASE/labs"

while true; do
    clear
    echo "==============================================="
    echo "      RHCSA MINI LINUX — MENU PRINCIPAL"
    echo "==============================================="
    echo "1) Listar laboratórios"
    echo "2) Adicionar novo laboratório"
    echo "3) Editar laboratório"
    echo "4) Excluir laboratório"
    echo "5) Ver progresso"
    echo "6) Sair"
    echo
    read -p "Escolha uma opção: " op

    case "$op" in
        1) bash "$BIN/list_labs.sh" ;;
        2) bash "$BIN/lab_add.sh" ;;
        3) bash "$BIN/lab_edit.sh" ;;
        4) bash "$BIN/lab_delete.sh" ;;
        5) bash "$BIN/show_progress.sh" ;;
        6) exit 0 ;;
        *) echo "Opção inválida" ; sleep 1 ;;
    esac
done
EOF
sudo chmod +x "$BASE/bin/menu.sh"


# ==========================
# Script: list_labs.sh
# ==========================
sudo tee "$BASE/bin/list_labs.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash

BASE="/opt/rhcsa-mini-linux"
DB="$BASE/data/labs_index.db"

clear
echo "LISTA DE LABORATÓRIOS"
echo "====================="
grep -v "^#" "$DB" | sed '/^\s*$/d'
echo
read -p "Pressione ENTER para voltar..."
EOF
sudo chmod +x "$BASE/bin/list_labs.sh"


# ==========================
# Criar startup script simbólico
# ==========================
sudo ln -sf "$BASE/bin/menu.sh" /usr/local/bin/rhcsa-mini 2>/dev/null


echo "✅ Instalação concluída!"
echo "Para iniciar:  rhcsa-mini"
