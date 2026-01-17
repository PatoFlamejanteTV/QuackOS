#!/usr/bin/env bash
# Script de linting para arquivos Shell Script (.sh)
# QuackOS Project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== QuackOS Shell Script Linter ===${NC}"

# Verifica se shellcheck está instalado
if ! command -v shellcheck &> /dev/null; then
    echo -e "${YELLOW}[AVISO]${NC} shellcheck não encontrado."
    echo "Para instalar: sudo apt install shellcheck"
    echo "Continuando com verificações básicas..."
    USE_SHELLCHECK=false
else
    USE_SHELLCHECK=true
fi

# Contador de erros
ERRORS=0
WARNINGS=0
FILES_CHECKED=0

# Encontra todos os arquivos shell script
SHELL_FILES=$(find "$PROJECT_ROOT" -type f -name "*.sh" -not -path "*/.*" -not -path "*/node_modules/*")

if [ -z "$SHELL_FILES" ]; then
    echo -e "${YELLOW}Nenhum arquivo shell script encontrado.${NC}"
    exit 0
fi

# Função para verificar problemas básicos
check_basic_issues() {
    local file="$1"
    
    echo "Verificando: $file"
    
    # Verifica shebang
    local first_line=$(head -n 1 "$file")
    if [[ ! "$first_line" =~ ^#!/ ]]; then
        echo -e "  ${RED}[ERRO]${NC} Shebang ausente ou inválido"
        ((ERRORS++))
    elif [[ "$first_line" != "#!/usr/bin/env bash" ]] && [[ "$first_line" != "#!/bin/bash" ]] && [[ "$first_line" != "#!/bin/sh" ]]; then
        echo -e "  ${YELLOW}[AVISO]${NC} Shebang não padrão: $first_line"
        ((WARNINGS++))
    fi
    
    # Verifica se o arquivo é executável
    if [ ! -x "$file" ]; then
        echo -e "  ${YELLOW}[AVISO]${NC} Arquivo não é executável (use: chmod +x $file)"
        ((WARNINGS++))
    fi
    
    # Verifica trailing whitespace
    if grep -E '\s+$' "$file" > /dev/null; then
        echo -e "  ${YELLOW}[AVISO]${NC} Espaços em branco no final da linha"
        ((WARNINGS++))
    fi
    
    # Verifica uso de set -e ou set -u (boas práticas)
    if ! grep -q "set -e\|set -u\|set -eu\|set -euo pipefail" "$file"; then
        echo -e "  ${YELLOW}[AVISO]${NC} Considere usar 'set -e' ou 'set -euo pipefail' para tratamento de erros"
        ((WARNINGS++))
    fi
    
    ((FILES_CHECKED++))
}

# Função para executar shellcheck
run_shellcheck() {
    local file="$1"
    
    if [ "$USE_SHELLCHECK" = true ]; then
        local output=$(shellcheck -f gcc "$file" 2>&1)
        if [ -n "$output" ]; then
            echo "$output"
            # Conta avisos e erros
            local error_count=$(echo "$output" | grep -c "error:" || true)
            local warning_count=$(echo "$output" | grep -c "warning:" || true)
            ((ERRORS += error_count))
            ((WARNINGS += warning_count))
        fi
    fi
}

# Processa cada arquivo
for file in $SHELL_FILES; do
    check_basic_issues "$file"
    run_shellcheck "$file"
done

# Relatório final
echo ""
echo -e "${CYAN}=== Relatório Final ===${NC}"
echo "Arquivos verificados: $FILES_CHECKED"
echo -e "Avisos: ${YELLOW}$WARNINGS${NC}"
echo -e "Erros: ${RED}$ERRORS${NC}"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Linting falhou com $ERRORS erro(s).${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Linting completado com $WARNINGS aviso(s).${NC}"
    exit 0
else
    echo -e "${GREEN}Linting completado sem problemas!${NC}"
    exit 0
fi
