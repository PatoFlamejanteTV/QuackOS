#!/usr/bin/env bash
# ==============================================================================
# QuackOS - Script de Informações
# ==============================================================================
# Exibe informações detalhadas sobre o build do QuackOS
# ==============================================================================

set -e

# Cores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
BOOTLOADER_DIR="$PROJECT_ROOT/bootloader"
KERNEL_DIR="$PROJECT_ROOT/kernel"

# ==============================================================================
# Funções
# ==============================================================================

print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}─────────────────────────────────────────────────────────${NC}"
}

# ==============================================================================
# Informações do bootloader
# ==============================================================================

show_bootloader_info() {
    print_section "Bootloader"
    
    local MBR="$BOOTLOADER_DIR/build/boot.bin"
    local STAGE2="$BOOTLOADER_DIR/build/stage2.bin"
    
    if [ -f "$MBR" ]; then
        echo "MBR (boot.bin):"
        echo "  Arquivo: $MBR"
        echo "  Tamanho: $(stat -c%s "$MBR") bytes"
        echo "  Assinatura: 0x$(xxd -p -l 2 -s 510 "$MBR")"
    else
        echo -e "${YELLOW}MBR não compilado${NC}"
    fi
    
    echo ""
    
    if [ -f "$STAGE2" ]; then
        echo "Stage 2 (stage2.bin):"
        echo "  Arquivo: $STAGE2"
        echo "  Tamanho: $(stat -c%s "$STAGE2") bytes ($(( $(stat -c%s "$STAGE2") / 512 )) setores)"
    else
        echo -e "${YELLOW}Stage 2 não compilado${NC}"
    fi
}

# ==============================================================================
# Informações do kernel
# ==============================================================================

show_kernel_info() {
    print_section "Kernel (QKern)"
    
    local KERNEL="$KERNEL_DIR/qkern.elf"
    
    if [ ! -f "$KERNEL" ]; then
        echo -e "${YELLOW}Kernel não compilado${NC}"
        return
    fi
    
    echo "Arquivo: $KERNEL"
    echo ""
    
    echo "Formato:"
    file "$KERNEL" | sed 's/^/  /'
    echo ""
    
    echo "Entry Point:"
    readelf -h "$KERNEL" | grep "Entry point" | sed 's/^/  /'
    echo ""
    
    echo "Tamanho das seções:"
    size "$KERNEL" | sed 's/^/  /'
    echo ""
    
    echo "Seções ELF:"
    readelf -S "$KERNEL" | grep -E "^\s*\[" | sed 's/^/  /'
    echo ""
    
    echo "Símbolos principais:"
    readelf -s "$KERNEL" | grep -E "(qkern_inicio|FUNC|GLOBAL)" | head -n 10 | sed 's/^/  /'
}

# ==============================================================================
# Informações da imagem de disco
# ==============================================================================

show_disk_info() {
    print_section "Imagem de Disco"
    
    local DISK_IMG="$BUILD_DIR/quackos.img"
    
    if [ ! -f "$DISK_IMG" ]; then
        echo -e "${YELLOW}Imagem de disco não criada${NC}"
        return
    fi
    
    local size=$(stat -c%s "$DISK_IMG")
    local size_mb=$(echo "scale=2; $size / 1024 / 1024" | bc)
    
    echo "Arquivo: $DISK_IMG"
    echo "Tamanho: $size bytes (${size_mb} MB)"
    echo ""
    
    echo "Estrutura:"
    echo "  LBA 0      : MBR (boot.bin, 512 bytes)"
    echo "  LBA 1-16   : Stage 2 (stage2.bin, 8KB / 16 setores)"
    echo "  LBA 17+    : Kernel (qkern.elf)"
    echo ""
    
    echo "Verificação do MBR na imagem:"
    local mbr_sig=$(xxd -p -l 2 -s 510 "$DISK_IMG")
    if [ "$mbr_sig" = "55aa" ]; then
        echo -e "  ${GREEN}✓${NC} Assinatura de boot válida (0x55AA)"
    else
        echo -e "  ${YELLOW}⚠${NC} Assinatura: 0x$mbr_sig"
    fi
}

# ==============================================================================
# Informações do ambiente
# ==============================================================================

show_environment_info() {
    print_section "Ambiente de Desenvolvimento"
    
    echo "Ferramentas:"
    
    if command -v nasm &> /dev/null; then
        echo "  NASM: $(nasm -v)"
    else
        echo -e "  ${YELLOW}NASM: não instalado${NC}"
    fi
    
    if command -v ld &> /dev/null; then
        echo "  LD: $(ld --version | head -n1)"
    else
        echo -e "  ${YELLOW}LD: não instalado${NC}"
    fi
    
    if command -v qemu-system-x86_64 &> /dev/null; then
        echo "  QEMU: $(qemu-system-x86_64 --version | head -n1)"
    else
        echo -e "  ${YELLOW}QEMU: não instalado${NC}"
    fi
    
    if command -v gdb &> /dev/null; then
        echo "  GDB: $(gdb --version | head -n1)"
    else
        echo -e "  ${YELLOW}GDB: não instalado${NC}"
    fi
}

# ==============================================================================
# Estatísticas do projeto
# ==============================================================================

show_project_stats() {
    print_section "Estatísticas do Projeto"
    
    echo "Arquivos assembly:"
    find "$PROJECT_ROOT" -name "*.asm" -type f | while read file; do
        local lines=$(wc -l < "$file")
        echo "  $(basename "$file"): $lines linhas"
    done
    
    echo ""
    echo "Estrutura de diretórios:"
    tree -L 2 -d "$PROJECT_ROOT" 2>/dev/null || find "$PROJECT_ROOT" -maxdepth 2 -type d | sed 's/^/  /'
}

# ==============================================================================
# Menu
# ==============================================================================

show_menu() {
    cat << EOF
${CYAN}QuackOS - Informações do Sistema${NC}

Escolha uma opção:
  1) Visão geral
  2) Informações do bootloader
  3) Informações do kernel
  4) Informações da imagem de disco
  5) Ambiente de desenvolvimento
  6) Estatísticas do projeto
  7) Tudo
  8) Sair

EOF
    read -p "Opção: " choice
    
    case $choice in
        1)
            print_header "🦆 QuackOS - Visão Geral"
            show_bootloader_info
            show_kernel_info
            show_disk_info
            ;;
        2)
            print_header "🦆 QuackOS - Bootloader"
            show_bootloader_info
            ;;
        3)
            print_header "🦆 QuackOS - Kernel"
            show_kernel_info
            ;;
        4)
            print_header "🦆 QuackOS - Imagem de Disco"
            show_disk_info
            ;;
        5)
            print_header "🦆 QuackOS - Ambiente"
            show_environment_info
            ;;
        6)
            print_header "🦆 QuackOS - Estatísticas"
            show_project_stats
            ;;
        7)
            print_header "🦆 QuackOS - Informações Completas"
            show_bootloader_info
            show_kernel_info
            show_disk_info
            show_environment_info
            show_project_stats
            ;;
        8)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida${NC}"
            exit 1
            ;;
    esac
    
    echo ""
}

# ==============================================================================
# Main
# ==============================================================================

# Se chamado com argumento, executar diretamente
if [ $# -gt 0 ]; then
    case "$1" in
        --bootloader) show_bootloader_info ;;
        --kernel) show_kernel_info ;;
        --disk) show_disk_info ;;
        --env) show_environment_info ;;
        --stats) show_project_stats ;;
        --all)
            print_header "🦆 QuackOS - Informações Completas"
            show_bootloader_info
            show_kernel_info
            show_disk_info
            show_environment_info
            show_project_stats
            ;;
        *)
            echo "Uso: $0 [--bootloader|--kernel|--disk|--env|--stats|--all]"
            exit 1
            ;;
    esac
else
    show_menu
fi
