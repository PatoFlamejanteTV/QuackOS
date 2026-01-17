#!/usr/bin/env bash
# ==============================================================================
# QuackOS - Script de Limpeza
# ==============================================================================
# Remove todos os artefatos de build
# ==============================================================================

set -e

# Cores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

clean_bootloader() {
    echo -e "${YELLOW}➜${NC} Limpando bootloader..."
    cd "$BOOTLOADER_DIR"
    if [ -f Makefile ]; then
        make clean 2>&1 | sed 's/^/  /'
    fi
    echo -e "${GREEN}  ✓${NC} Bootloader limpo"
}

clean_kernel() {
    echo -e "${YELLOW}➜${NC} Limpando kernel..."
    cd "$KERNEL_DIR"
    if [ -f Makefile ]; then
        make clean 2>&1 | sed 's/^/  /'
    fi
    echo -e "${GREEN}  ✓${NC} Kernel limpo"
}

clean_build_dir() {
    echo -e "${YELLOW}➜${NC} Limpando diretório de build central..."
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        echo -e "${GREEN}  ✓${NC} Diretório de build removido"
    else
        echo -e "${GREEN}  ✓${NC} Diretório de build não existe"
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    print_header "🧹 Limpeza do QuackOS"
    echo ""
    
    clean_bootloader
    clean_kernel
    clean_build_dir
    
    echo ""
    print_header "✓ Limpeza concluída!"
}

main "$@"
