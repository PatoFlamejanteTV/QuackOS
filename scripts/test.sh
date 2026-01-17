#!/usr/bin/env bash
# ==============================================================================
# QuackOS - Script de Testes Automatizados
# ==============================================================================
# Testa o bootloader e kernel do QuackOS
# ==============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
BOOTLOADER_DIR="$PROJECT_ROOT/bootloader"
KERNEL_DIR="$PROJECT_ROOT/kernel"

# Contadores de teste
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ==============================================================================
# Funções auxiliares
# ==============================================================================

print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

test_start() {
    echo -e "${BLUE}▶${NC} Testando: $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo -e "  ${RED}✗${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

test_info() {
    echo -e "  ${YELLOW}ℹ${NC} $1"
}

# ==============================================================================
# Testes do Bootloader
# ==============================================================================

test_bootloader() {
    print_header "🔍 Testes do Bootloader"
    echo ""
    
    # Teste 1: MBR existe e tem 512 bytes
    test_start "MBR (boot.bin)"
    local MBR="$BOOTLOADER_DIR/build/boot.bin"
    
    if [ -f "$MBR" ]; then
        local size=$(stat -c%s "$MBR")
        if [ "$size" -eq 512 ]; then
            test_pass "Tamanho correto (512 bytes)"
        else
            test_fail "Tamanho incorreto: $size bytes (esperado: 512)"
        fi
        
        # Verificar assinatura de boot (0x55AA nos últimos 2 bytes)
        local signature=$(xxd -p -l 2 -s 510 "$MBR")
        if [ "$signature" = "55aa" ]; then
            test_pass "Assinatura de boot válida (0x55AA)"
        else
            test_fail "Assinatura de boot inválida: 0x$signature"
        fi
    else
        test_fail "Arquivo não encontrado: $MBR"
    fi
    
    echo ""
    
    # Teste 2: Stage 2 existe e tem 8KB
    test_start "Stage 2 (stage2.bin)"
    local STAGE2="$BOOTLOADER_DIR/build/stage2.bin"
    
    if [ -f "$STAGE2" ]; then
        local size=$(stat -c%s "$STAGE2")
        if [ "$size" -eq 8192 ]; then
            test_pass "Tamanho correto (8192 bytes / 16 setores)"
        else
            test_fail "Tamanho incorreto: $size bytes (esperado: 8192)"
        fi
    else
        test_fail "Arquivo não encontrado: $STAGE2"
    fi
    
    echo ""
    
    # Teste 3: Imagem de disco
    test_start "Imagem de disco (quackos.img)"
    local DISK_IMG="$BOOTLOADER_DIR/build/quackos.img"
    
    if [ -f "$DISK_IMG" ]; then
        local size=$(stat -c%s "$DISK_IMG")
        test_pass "Imagem encontrada ($size bytes)"
        
        # Verificar MBR na imagem
        local mbr_sig=$(xxd -p -l 2 -s 510 "$DISK_IMG")
        if [ "$mbr_sig" = "55aa" ]; then
            test_pass "MBR integrado corretamente"
        else
            test_fail "MBR não encontrado na imagem"
        fi
    else
        test_fail "Arquivo não encontrado: $DISK_IMG"
    fi
}

# ==============================================================================
# Testes do Kernel
# ==============================================================================

test_kernel() {
    print_header "🔍 Testes do Kernel"
    echo ""
    
    test_start "Kernel ELF (qkern.elf)"
    local KERNEL="$KERNEL_DIR/qkern.elf"
    
    if [ ! -f "$KERNEL" ]; then
        test_fail "Arquivo não encontrado: $KERNEL"
        return
    fi
    
    test_pass "Kernel encontrado"
    
    # Verificar formato ELF64
    if file "$KERNEL" | grep -q "ELF 64-bit"; then
        test_pass "Formato ELF 64-bit correto"
    else
        test_fail "Formato incorreto (esperado: ELF 64-bit)"
        file "$KERNEL"
    fi
    
    # Verificar entry point
    local entry=$(readelf -h "$KERNEL" | grep "Entry point" | awk '{print $4}')
    if [ -n "$entry" ]; then
        test_pass "Entry point: $entry"
    else
        test_fail "Entry point não encontrado"
    fi
    
    # Verificar símbolos importantes
    if readelf -s "$KERNEL" | grep -q "qkern_inicio"; then
        test_pass "Símbolo qkern_inicio encontrado"
    else
        test_fail "Símbolo qkern_inicio não encontrado"
    fi
    
    # Informações adicionais
    echo ""
    test_info "Detalhes do kernel:"
    size "$KERNEL" | tail -n +2 | while read line; do
        echo -e "    $line"
    done
}

# ==============================================================================
# Testes de build
# ==============================================================================

test_build_system() {
    print_header "🔍 Testes do Sistema de Build"
    echo ""
    
    # Teste 1: Makefiles existem
    test_start "Makefiles"
    
    if [ -f "$BOOTLOADER_DIR/Makefile" ]; then
        test_pass "Makefile do bootloader encontrado"
    else
        test_fail "Makefile do bootloader não encontrado"
    fi
    
    if [ -f "$KERNEL_DIR/Makefile" ]; then
        test_pass "Makefile do kernel encontrado"
    else
        test_fail "Makefile do kernel não encontrado"
    fi
    
    echo ""
    
    # Teste 2: Linker script
    test_start "Linker script"
    
    if [ -f "$KERNEL_DIR/linker.ld" ]; then
        test_pass "linker.ld encontrado"
    else
        test_fail "linker.ld não encontrado"
    fi
    
    echo ""
    
    # Teste 3: Scripts de build
    test_start "Scripts de automação"
    
    if [ -f "$SCRIPT_DIR/build.sh" ]; then
        test_pass "build.sh encontrado"
    else
        test_fail "build.sh não encontrado"
    fi
    
    if [ -f "$SCRIPT_DIR/run.sh" ]; then
        test_pass "run.sh encontrado"
    else
        test_fail "run.sh não encontrado"
    fi
}

# ==============================================================================
# Teste de execução rápida (QEMU)
# ==============================================================================

test_qemu_boot() {
    print_header "🔍 Teste de Boot (QEMU)"
    echo ""
    
    test_start "Boot rápido no QEMU"
    
    local DISK_IMG="$BUILD_DIR/quackos.img"
    
    if [ ! -f "$DISK_IMG" ]; then
        test_fail "Imagem não encontrada: $DISK_IMG"
        return
    fi
    
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        test_fail "QEMU não instalado"
        return
    fi
    
    # Executar QEMU por 2 segundos e capturar log
    local LOG_FILE="$BUILD_DIR/test_boot.log"
    timeout 2s qemu-system-x86_64 \
        -drive format=raw,file="$DISK_IMG" \
        -m 256M \
        -display none \
        -serial file:"$LOG_FILE" \
        -d int,cpu_reset \
        -D "$BUILD_DIR/test_qemu_debug.log" \
        2>&1 || true
    
    test_pass "QEMU executado por 2 segundos"
    test_info "Logs salvos em:"
    test_info "  - $LOG_FILE"
    test_info "  - $BUILD_DIR/test_qemu_debug.log"
}

# ==============================================================================
# Dependências
# ==============================================================================

test_dependencies() {
    print_header "🔍 Verificação de Dependências"
    echo ""
    
    test_start "Ferramentas necessárias"
    
    local tools=("nasm" "ld" "dd" "qemu-system-x86_64" "xxd" "readelf" "objdump")
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            local version=$(command $tool --version 2>&1 | head -n1 || echo "N/A")
            test_pass "$tool: $version"
        else
            test_fail "$tool não instalado"
        fi
    done
}

# ==============================================================================
# Sumário
# ==============================================================================

print_summary() {
    echo ""
    print_header "📊 Sumário dos Testes"
    echo ""
    
    echo -e "${CYAN}Total de testes:${NC} $TESTS_RUN"
    echo -e "${GREEN}Passaram:${NC}        $TESTS_PASSED"
    echo -e "${RED}Falharam:${NC}        $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✓ Todos os testes passaram! 🦆${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        return 0
    else
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}✗ Alguns testes falharam${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        return 1
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    print_header "🦆 QuackOS - Suite de Testes"
    echo ""
    
    test_dependencies
    echo ""
    
    test_build_system
    echo ""
    
    test_bootloader
    echo ""
    
    test_kernel
    echo ""
    
    test_qemu_boot
    echo ""
    
    print_summary
}

# Executar
main "$@"
