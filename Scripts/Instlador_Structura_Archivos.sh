#!/usr/bin/env bash

# =======================================================
#  RHCSA MINI LINUX — INSTALADOR COMPLETO OFICIAL
#  Autor: Jensy Gomez (2025) - Versión Full con Labs + SSH
#  100% Bash puro - RHCSA Trainer Automático
# =======================================================

BASE="/opt/rhcsa-mini-linux"

echo "🚀 Instalando RHCSA Mini Linux FULL em: $BASE"
sudo mkdir -p "$BASE"

# ==========================
# Criando estructura completa
# ==========================
echo "🔧 Criando diretórios..."
sudo mkdir -p "$BASE/bin"
sudo mkdir -p "$BASE/data"
sudo mkdir -p "$BASE/labs"
sudo mkdir -p "$BASE/logs/lab_runs"
sudo mkdir -p "$BASE/system"
sudo mkdir -p "$BASE/vm_scripts"

# ==========================
# Base de dados inicial
# ==========================
echo "📁 Criando base de dados..."
sudo tee "$BASE/data/labs_index.db" >/dev/null <<'EOF'
# id_lab=path|title|difficulty|points
lvm-001|/opt/rhcsa-mini-linux/labs/lvm-001|PV básico|1|20
lvm-002|/opt/rhcsa-mini-linux/labs/lvm-002|VG básico|2|30
users-001|/opt/rhcsa-mini-linux/labs/users-001|Crear usuário|1|15
network-001|/opt/rhcsa-mini-linux/labs/network-001|Configurar IP|2|25
EOF

sudo tee "$BASE/data/vm_config.db" >/dev/null <<'EOF'
VM_IP="192.168.122.143"
VM_USER="student"
VM_PASS="student"
EOF

sudo tee "$BASE/data/progress.db" >/dev/null <<'EOF'
# user_lab_id=attempts|completed|score
EOF

# ==========================
# UTILS - Funciones base
# ==========================
sudo tee "$BASE/bin/utils.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash

BASE="/opt/rhcsa-mini-linux"
DATA="$BASE/data"
BIN="$BASE/bin"
LABS="$BASE/labs"

draw_line() {
    printf '%*s\n' "${1:-50}" '' | tr ' ' '-'
}

print_table_header() {
    echo "ID    | Título                    | Dific. | Pts"
    draw_line 50
}

print_labs_table() {
    grep -v "^#" "$DATA/labs_index.db" | while IFS='|' read -r id path title diff pts; do
        echo " $id   | $title                  | $diff   | $pts"
    done
}

get_valid_input() {
    local valid_opts="$1"
    local prompt="$2"
    local choice
    
    while true; do
        read -p "$prompt" -n1 choice
        echo
        if [[ "${choice,,}" =~ ^[$valid_opts]$ ]]; then
            echo "$choice"
            return 0
        fi
        echo "❌ Opção inválida! Use: [$valid_opts]"
        sleep 1
    done
}

ssh_exec() {
    source "$DATA/vm_config.db"
    sshpass -p "$VM_PASS" ssh -o StrictHostKeyChecking=no "$VM_USER@$VM_IP" "$1" 2>/dev/null
}

ssh_setup_lab() {
    local lab_id="$1"
    echo "🔧 Configurando lab $lab_id na VM..."
    ssh_exec "sudo rm -rf /tmp/lab_* 2>/dev/null"
    ssh_exec "sudo mkdir -p /tmp/lab_$lab_id"
    ssh_exec "sudo chown $VM_USER:$VM_USER /tmp/lab_$lab_id"
}

ssh_validate_lab() {
    local lab_id="$1"
    local validation_script="$LABS/$lab_id/validate.sh"
    if [[ -f "$validation_script" ]]; then
        ssh_exec "bash -s" < "$validation_script"
    else
        echo "❌ Script de validação não encontrado"
    fi
}
EOF
sudo chmod +x "$BASE/bin/utils.sh"

# ==========================
# MENU PRINCIPAL SIMPLIFICADO
# ==========================
sudo tee "$BASE/bin/menu.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash

source "$BASE/bin/utils.sh"

show_main_menu() {
    clear
    echo "==============================================="
    echo "      🚀 RHCSA MINI LINUX — MENU PRINCIPAL"
    echo "==============================================="
    echo "[t] Treinamento (Labs + VM SSH)"
    echo "[p] Progresso"
    echo "[c] Configurar VM SSH"
    echo "[s] Sair"
    echo
}

while true; do
    show_main_menu
    choice=$(get_valid_input "tpc s" "Escolha (t,p,c,s): ")
    
    case "${choice,,}" in
        t) bash "$BASE/bin/labs_menu.sh" ;;
        p) bash "$BASE/bin/show_progress.sh" ;;
        c) bash "$BASE/bin/vm_config.sh" ;;
        s) exit 0 ;;
    esac
done
EOF
sudo chmod +x "$BASE/bin/menu.sh"

# ==========================
# MENU DE LABORATORIOS (CRUD + SSH)
# ==========================
sudo tee "$BASE/bin/labs_menu.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash

source "$BASE/bin/utils.sh"

show_labs_menu() {
    clear
    echo "🔬 LABORATÓRIOS DISPONÍVEIS"
    echo "=========================="
    print_table_header
    print_labs_table
    echo
    echo "[1-9] Estudar lab     [a] Adicionar"
    echo "[e] Editar            [x] Excluir"
    echo "[b] Voltar"
}

lab_select() {
    local lab_id="$1"
    echo "🚀 Iniciando $lab_id..."
    
    # 1. Configurar VM
    ssh_setup_lab "$lab_id"
    
    # 2. Mostrar cenário
    if [[ -f "$LABS/$lab_id/scenario.txt" ]]; then
        echo "📖 Cenário:"
        cat "$LABS/$lab_id/scenario.txt"
    fi
    
    echo "💻 Conecte: ssh $VM_USER@$VM_IP"
    echo "Execute os comandos e pressione ENTER para validar..."
    read
    
    # 3. Validar
    ssh_validate_lab "$lab_id"
    read -p "ENTER para continuar..."
}

while true; do
    show_labs_menu
    choice=$(get_valid_input "123456789aexb" "Opção: ")
    
    case "${choice,,}" in
        1) lab_select "lvm-001" ;;
        2) lab_select "lvm-002" ;;
        3) lab_select "users-001" ;;
        4) lab_select "network-001" ;;
        a) echo "Adicionar lab... (futuro)" ; sleep 2 ;;
        e) echo "Editar lab... (futuro)" ; sleep 2 ;;
        x) echo "Excluir lab... (futuro)" ; sleep 2 ;;
        b) exit 0 ;;
    esac
done
EOF
sudo chmod +x "$BASE/bin/labs_menu.sh"

# ==========================
# CONFIGURACION VM SSH
# ==========================
sudo tee "$BASE/bin/vm_config.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash

source "$BASE/bin/utils.sh"
source "$DATA/vm_config.db" 2>/dev/null || true

echo "🔧 CONFIGURAÇÃO VM SSH"
draw_line

if [[ -z "$VM_IP" ]]; then
    echo "🔧 Primeira configuração:"
    read -p "IP/Host: " VM_IP
    read -p "Usuário: " VM_USER
    read -s -p "Senha: " VM_PASS; echo
else
    echo "Atual: $VM_USER@$VM_IP"
    read -p "IP [$VM_IP]: " new_ip
    [[ -n "$new_ip" ]] && VM_IP="$new_ip"
    
    read -p "Usuário [$VM_USER]: " new_user
    [[ -n "$new_user" ]] && VM_USER="$new_user"
    
    read -s -p "Senha [Enter=mantém]: " new_pass; echo
    [[ -n "$new_pass" ]] && VM_PASS="$new_pass"
fi

cat > "$DATA/vm_config.db" << EOF
VM_IP="$VM_IP"
VM_USER="$VM_USER"
VM_PASS="$VM_PASS"
EOF

echo "✅ Configurado: $VM_USER@$VM_IP"
echo "💡 Teste: sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no $VM_USER@$VM_IP 'whoami'"
sleep 3
EOF
sudo chmod +x "$BASE/bin/vm_config.sh"

# ==========================
# PROGRESSO
# ==========================
sudo tee "$BASE/bin/show_progress.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash

source "$BASE/bin/utils.sh"

clear
echo "📊 PROGRESSO RHCSA"
draw_line
echo "Total labs: $(grep -v '^#' "$DATA/labs_index.db" | wc -l)"
echo "Completos: 0 (futuro)"
echo
print_table_header
print_labs_table
echo
read -p "ENTER para voltar..."
EOF
sudo chmod +x "$BASE/bin/show_progress.sh"

# ==========================
# TEMPLATES DE LABS
# ==========================
sudo tee "$BASE/labs/lvm-001/scenario.txt" >/dev/null <<'EOF'
Crie um Physical Volume básico:
$ sudo pvcreate /dev/loop1
$ pvs
EOF

sudo tee "$BASE/labs/lvm-001/validate.sh" >/dev/null <<'EOF'
#!/usr/bin/env bash
if pvs | grep -q loop1; then
    echo "✅ PV criado corretamente!"
else
    echo "❌ PV não encontrado"
fi
EOF

sudo chmod +x "$BASE/labs/lvm-001/validate.sh"

# ==========================
# SSHpass (requerido)
# ==========================
sudo apt update >/dev/null 2>&1
sudo apt install -y sshpass >/dev/null 2>&1

# ==========================
# Startup script
# ==========================
sudo tee /usr/local/bin/rhcsa-mini >/dev/null <<'EOF'
#!/bin/bash
cd /opt/rhcsa-mini-linux/bin
bash menu.sh
EOF
sudo chmod +x /usr/local/bin/rhcsa-mini

echo "✅ INSTALAÇÃO COMPLETA!"
echo "======================"
echo "👉 rhcsa-mini          # Menu principal"
echo "👉 rhcsa-mini → c       # Configurar VM"
echo "👉 rhcsa-mini → t → 1   # Lab LVM-001"
echo ""
echo "💻 VM padrão: student@192.168.122.143"
echo "🔧 Edite: /opt/rhcsa-mini-linux/data/vm_config.db"
