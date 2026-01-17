#!/usr/bin/env bash
# ==============================================================================
# QuackOS - Script de Debug com QEMU + GDB
# ==============================================================================
# Inicia o QEMU em modo debug e conecta o GDB
# ==============================================================================

set -e

# Cores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
KERNEL_DIR="$PROJECT_ROOT/kernel"
DISK_IMG="$BUILD_DIR/quackos.img"
KERNEL_ELF="$KERNEL_DIR/qkern.elf"

# Configurações
GDB_PORT=1234
QEMU_LOG="$BUILD_DIR/qemu_debug.log"
GDB_SCRIPT="$BUILD_DIR/gdb_commands.txt"

# ==============================================================================
# Verificações
# ==============================================================================

if [ ! -f "$DISK_IMG" ]; then
    echo -e "${RED}ERRO: Imagem não encontrada: $DISK_IMG${NC}"
    echo "Compile primeiro com: ./scripts/build.sh"
    exit 1
fi

if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo -e "${RED}ERRO: QEMU não instalado${NC}"
    exit 1
fi

# ==============================================================================
# Criar script GDB
# ==============================================================================

mkdir -p "$BUILD_DIR"

cat > "$GDB_SCRIPT" << 'EOF'
# QuackOS - Comandos GDB

# Conectar ao QEMU
target remote localhost:1234

# Definir arquitetura
set architecture i386:x86-64

# Carregar símbolos do kernel (se existir)
# file kernel/qkern.elf

# Breakpoint no entry point do kernel (exemplo)
# break *0x100000

# Comandos úteis:
# info registers     - Ver registradores
# x/10i $rip         - Desmontar 10 instruções a partir do RIP
# x/10x $rsp         - Ver 10 words na stack
# continue           - Continuar execução
# stepi              - Step (uma instrução)
# info mem           - Ver mapeamento de memória

# Layout TUI
layout asm
layout regs

echo \n\033[1;32m=== QuackOS Debug Session ===\033[0m\n
echo Comandos úteis:\n
echo   info registers  - Ver registradores\n
echo   x/10i $rip      - Desmontar código\n
echo   continue        - Continuar\n
echo   stepi           - Step\n
echo \n
EOF

# ==============================================================================
# Função para iniciar QEMU
# ==============================================================================

start_qemu() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🦆 Iniciando QEMU em modo debug...${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}Configuração:${NC}"
    echo "  Imagem: $DISK_IMG"
    echo "  GDB Port: $GDB_PORT"
    echo "  Log: $QEMU_LOG"
    echo ""
    echo -e "${YELLOW}QEMU irá pausar e aguardar conexão do GDB${NC}"
    echo -e "${YELLOW}Em outro terminal, execute:${NC}"
    echo -e "  ${GREEN}gdb -x $GDB_SCRIPT${NC}"
    echo ""
    
    qemu-system-x86_64 \
        -drive format=raw,file="$DISK_IMG" \
        -m 256M \
        -s \
        -S \
        -d int,cpu_reset \
        -D "$QEMU_LOG" \
        -no-reboot \
        -no-shutdown
}

# ==============================================================================
# Função para iniciar com GDB automático
# ==============================================================================

start_with_gdb() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🦆 Iniciando QEMU + GDB automaticamente${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Iniciar QEMU em background
    qemu-system-x86_64 \
        -drive format=raw,file="$DISK_IMG" \
        -m 256M \
        -s \
        -S \
        -d int,cpu_reset \
        -D "$QEMU_LOG" \
        -no-reboot \
        -no-shutdown &
    
    QEMU_PID=$!
    
    echo -e "${GREEN}QEMU iniciado (PID: $QEMU_PID)${NC}"
    echo ""
    sleep 1
    
    # Iniciar GDB
    if command -v gdb &> /dev/null; then
        echo -e "${GREEN}Iniciando GDB...${NC}"
        gdb -x "$GDB_SCRIPT"
    else
        echo -e "${YELLOW}GDB não encontrado. QEMU está rodando em background.${NC}"
        echo -e "${YELLOW}Conecte manualmente com: gdb -x $GDB_SCRIPT${NC}"
        wait $QEMU_PID
    fi
    
    # Cleanup
    kill $QEMU_PID 2>/dev/null || true
}

# ==============================================================================
# Menu
# ==============================================================================

show_menu() {
    cat << EOF
${CYAN}QuackOS - Debug com QEMU + GDB${NC}

Escolha uma opção:
  1) Apenas QEMU (aguarda GDB externo)
  2) QEMU + GDB automático
  3) Ver log do QEMU
  4) Sair

EOF
    read -p "Opção: " choice
    
    case $choice in
        1)
            start_qemu
            ;;
        2)
            start_with_gdb
            ;;
        3)
            if [ -f "$QEMU_LOG" ]; then
                less "$QEMU_LOG"
            else
                echo -e "${RED}Log não encontrado: $QEMU_LOG${NC}"
            fi
            ;;
        4)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida${NC}"
            exit 1
            ;;
    esac
}

# ==============================================================================
# Main
# ==============================================================================

# Se chamado com --auto, inicia automaticamente
if [ "$1" = "--auto" ]; then
    start_with_gdb
else
    show_menu
fi
