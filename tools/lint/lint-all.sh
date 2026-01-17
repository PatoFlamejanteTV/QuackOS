#!/usr/bin/env bash
# Script mestre de linting - executa todos os linters
# QuackOS Project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║   QuackOS - Linting Completo          ║${NC}"
echo -e "${BOLD}${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Contador global de erros
TOTAL_ERRORS=0
TOTAL_WARNINGS=0
FAILED_LINTERS=()

# Função para executar um linter
run_linter() {
    local linter_script="$1"
    local linter_name="$2"
    
    echo -e "\n${BOLD}>>> Executando: $linter_name${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ -f "$linter_script" ]; then
        if bash "$linter_script"; then
            echo -e "${GREEN}✓ $linter_name passou!${NC}"
            return 0
        else
            local exit_code=$?
            echo -e "${RED}✗ $linter_name falhou (exit code: $exit_code)${NC}"
            FAILED_LINTERS+=("$linter_name")
            ((TOTAL_ERRORS++))
            return 1
        fi
    else
        echo -e "${YELLOW}⚠ $linter_script não encontrado, pulando...${NC}"
        return 0
    fi
}

# Lista de linters a executar
LINTERS=(
    "$SCRIPT_DIR/lint-asm.sh:Assembly (NASM)"
    "$SCRIPT_DIR/lint-c.sh:C/C++"
    "$SCRIPT_DIR/lint-shell.sh:Shell Scripts"
    "$SCRIPT_DIR/lint-markdown.sh:Markdown"
    "$SCRIPT_DIR/lint-makefile.sh:Makefiles"
)

# Executa cada linter
for linter_entry in "${LINTERS[@]}"; do
    IFS=':' read -r script name <<< "$linter_entry"
    run_linter "$script" "$name" || true
done

# Relatório final
echo ""
echo -e "${BOLD}${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║   Relatório Final de Linting          ║${NC}"
echo -e "${BOLD}${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

if [ ${#FAILED_LINTERS[@]} -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ Todos os linters passaram com sucesso!${NC}"
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          LINTING PASSOU! ✓             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}✗ Linters falharam: ${#FAILED_LINTERS[@]}${NC}"
    echo ""
    echo -e "${RED}Linters com falhas:${NC}"
    for linter in "${FAILED_LINTERS[@]}"; do
        echo -e "  ${RED}• $linter${NC}"
    done
    echo ""
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║          LINTING FALHOU! ✗             ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    exit 1
fi
