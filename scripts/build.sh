#!/usr/bin/env bash
# ==============================================================================
# QuackOS - Script de Build Completo
# ==============================================================================
# Compila o bootloader e o kernel, criando a imagem de disco bootável
# ==============================================================================

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BOOTLOADER_DIR="$PROJECT_ROOT/bootloader"
KERNEL_DIR="$PROJECT_ROOT/kernel"
BUILD_DIR="$PROJECT_ROOT/build"

# ==============================================================================
# Funções auxiliares
# ==============================================================================

print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🦆 $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_step() {
    echo -e "${BLUE}➜${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# ==============================================================================
# Verificar dependências
# ==============================================================================

check_dependencies() {
    print_step "Verificando dependências..."
    
    local deps=("nasm" "ld" "dd" "make")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        print_error "Dependências faltando: ${missing[*]}"
        echo ""
        echo "Instale com:"
        echo "  sudo apt install nasm binutils coreutils make"
        exit 1
    fi
    
    print_success "Todas as dependências encontradas"
}

# ==============================================================================
# Build do bootloader
# ==============================================================================

build_bootloader() {
    print_header "Compilando Bootloader"
    
    cd "$BOOTLOADER_DIR"
    
    if [ ! -f "Makefile" ]; then
        print_error "Makefile do bootloader não encontrado em $BOOTLOADER_DIR"
        exit 1
    fi
    
    print_step "Executando make no bootloader..."
    make all
    
    print_success "Bootloader compilado com sucesso"
}

# ==============================================================================
# Build do kernel
# ==============================================================================

build_kernel() {
    print_header "Compilando Kernel (QKern)"
    
    cd "$KERNEL_DIR"
    
    if [ ! -f "Makefile" ]; then
        print_error "Makefile do kernel não encontrado em $KERNEL_DIR"
        exit 1
    fi
    
    print_step "Executando make no kernel..."
    make all
    
    print_success "Kernel compilado com sucesso"
}

# ==============================================================================
# Integração da imagem de disco
# ==============================================================================

integrate_disk_image() {
    print_header "Integrando Imagem de Disco"
    
    local DISK_IMG="$BOOTLOADER_DIR/build/quackos.img"
    local KERNEL_BIN="$KERNEL_DIR/qkern.elf"
    
    # Verificar se os arquivos existem
    if [ ! -f "$DISK_IMG" ]; then
        print_error "Imagem de disco não encontrada: $DISK_IMG"
        exit 1
    fi
    
    if [ ! -f "$KERNEL_BIN" ]; then
        print_warning "Kernel não encontrado: $KERNEL_BIN"
        print_warning "A imagem terá apenas o bootloader"
        return
    fi
    
    print_step "Escrevendo kernel na imagem (LBA 17+)..."
    # Stage 2 ocupa LBA 1-16 (16 setores = 8KB)
    # Kernel começa em LBA 17
    dd if="$KERNEL_BIN" of="$DISK_IMG" bs=512 seek=17 conv=notrunc status=none
    
    print_success "Kernel integrado à imagem de disco"
}

# ==============================================================================
# Copiar para diretório de build central
# ==============================================================================

copy_to_build_dir() {
    print_header "Organizando Build"
    
    mkdir -p "$BUILD_DIR"
    
    # Copiar imagem de disco
    if [ -f "$BOOTLOADER_DIR/build/quackos.img" ]; then
        cp "$BOOTLOADER_DIR/build/quackos.img" "$BUILD_DIR/quackos.img"
        print_success "Imagem copiada para $BUILD_DIR/quackos.img"
    fi
    
    # Copiar kernel
    if [ -f "$KERNEL_DIR/qkern.elf" ]; then
        cp "$KERNEL_DIR/qkern.elf" "$BUILD_DIR/qkern.elf"
        print_success "Kernel copiado para $BUILD_DIR/qkern.elf"
    fi
}

# ==============================================================================
# Exibir informações do build
# ==============================================================================

show_build_info() {
    print_header "Informações do Build"
    
    echo -e "${CYAN}Estrutura da imagem de disco:${NC}"
    echo "  LBA 0      : MBR (boot.bin, 512 bytes)"
    echo "  LBA 1-16   : Stage 2 (stage2.bin, 8KB)"
    echo "  LBA 17+    : Kernel (qkern.elf)"
    echo ""
    
    if [ -f "$BUILD_DIR/quackos.img" ]; then
        local size=$(stat -c%s "$BUILD_DIR/quackos.img")
        local size_mb=$((size / 1024 / 1024))
        echo -e "${CYAN}Imagem de disco:${NC}"
        echo "  Arquivo: $BUILD_DIR/quackos.img"
        echo "  Tamanho: $size bytes (~${size_mb} MB)"
        echo ""
    fi
    
    if [ -f "$BUILD_DIR/qkern.elf" ]; then
        echo -e "${CYAN}Kernel:${NC}"
        file "$BUILD_DIR/qkern.elf"
        size "$BUILD_DIR/qkern.elf"
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    print_header "QuackOS Build System"
    echo ""
    
    check_dependencies
    echo ""
    
    build_bootloader
    echo ""
    
    build_kernel
    echo ""
    
    integrate_disk_image
    echo ""
    
    copy_to_build_dir
    echo ""
    
    show_build_info
    echo ""
    
    print_header "Build Completo! 🦆"
    echo -e "${GREEN}Execute com:${NC} ./scripts/run.sh"
    echo -e "${GREEN}Ou teste com:${NC} ./scripts/test.sh"
}

# Executar
main "$@"
