#!/usr/bin/env bash
# ==============================================================================
# QuackOS - Script de Watch (Compilação Contínua)
# ==============================================================================
# Monitora mudanças nos arquivos e recompila automaticamente
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

# ==============================================================================
# Verificar dependência
# ==============================================================================

if ! command -v inotifywait &> /dev/null; then
    echo -e "${YELLOW}⚠ inotify-tools não instalado${NC}"
    echo ""
    echo "Este script usa inotifywait para monitorar mudanças em arquivos."
    echo ""
    echo "Instale com:"
    echo "  sudo apt install inotify-tools    # Ubuntu/Debian"
    echo "  sudo pacman -S inotify-tools      # Arch"
    echo "  sudo dnf install inotify-tools    # Fedora"
    echo ""
    echo "Ou use build manual com: ./scripts/build.sh"
    exit 1
fi

# ==============================================================================
# Função de build
# ==============================================================================

do_build() {
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🔄 Recompilando QuackOS...${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
    
    if "$SCRIPT_DIR/build.sh"; then
        echo ""
        echo -e "${GREEN}✓ Build completo!${NC}"
        
        # Se flag --test estiver ativada, executar testes
        if [ "$RUN_TESTS" = true ]; then
            echo ""
            "$SCRIPT_DIR/test.sh"
        fi
    else
        echo ""
        echo -e "${RED}✗ Build falhou${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}👀 Monitorando mudanças... (Ctrl+C para sair)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ==============================================================================
# Ajuda
# ==============================================================================

show_help() {
    cat << EOF
${CYAN}QuackOS - Watch Mode (Compilação Contínua)${NC}

Uso: $0 [opções]

Opções:
  -h, --help      Exibir esta ajuda
  -t, --test      Executar testes após cada build

Descrição:
  Monitora mudanças em arquivos .asm, .c, .h e Makefiles
  e recompila automaticamente o QuackOS.

Diretórios monitorados:
  - bootloader/
  - kernel/
  - libq/

Pressione Ctrl+C para sair do watch mode.

EOF
}

# ==============================================================================
# Parse de argumentos
# ==============================================================================

RUN_TESTS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--test)
            RUN_TESTS=true
            shift
            ;;
        *)
            echo -e "${RED}Opção desconhecida: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# ==============================================================================
# Main
# ==============================================================================

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🦆 QuackOS - Watch Mode${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Iniciando monitoramento contínuo...${NC}"
echo ""
echo "Diretórios monitorados:"
echo "  - $PROJECT_ROOT/bootloader/"
echo "  - $PROJECT_ROOT/kernel/"
echo "  - $PROJECT_ROOT/libq/"
echo ""
echo "Tipos de arquivo: .asm, .c, .h, Makefile"
if [ "$RUN_TESTS" = true ]; then
    echo -e "${YELLOW}Testes automáticos: ATIVADOS${NC}"
fi
echo ""
echo -e "${YELLOW}Pressione Ctrl+C para sair${NC}"
echo ""

# Build inicial
do_build

# Monitorar mudanças
inotifywait -m -r -e modify,create,delete,move \
    --include '.*\.(asm|c|h)$|Makefile' \
    "$PROJECT_ROOT/bootloader" \
    "$PROJECT_ROOT/kernel" \
    "$PROJECT_ROOT/libq" 2>/dev/null | \
while read -r directory event filename; do
    echo ""
    echo -e "${YELLOW}⚡ Mudança detectada: $directory$filename${NC}"
    sleep 0.5  # Pequeno delay para evitar builds múltiplos
    do_build
done
