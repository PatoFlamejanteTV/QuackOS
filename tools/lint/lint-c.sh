#!/usr/bin/env bash
# Script de linting para arquivos C/C++ (.c, .h, .cpp, .hpp)
# QuackOS Project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== QuackOS C/C++ Linter ===${NC}"

# Verifica se as ferramentas necessárias estão instaladas
MISSING_TOOLS=""

if ! command -v clang-format &> /dev/null; then
    MISSING_TOOLS="${MISSING_TOOLS}clang-format "
fi

if ! command -v cppcheck &> /dev/null; then
    echo -e "${YELLOW}[AVISO]${NC} cppcheck não encontrado. Instale com: sudo apt install cppcheck"
fi

if [ -n "$MISSING_TOOLS" ]; then
    echo -e "${YELLOW}[AVISO]${NC} Ferramentas ausentes: $MISSING_TOOLS"
    echo "Para instalar: sudo apt install clang-format cppcheck"
fi

# Contador de erros
ERRORS=0
WARNINGS=0
FILES_CHECKED=0

# Encontra todos os arquivos C/C++
C_FILES=$(find "$PROJECT_ROOT" -type f \( -name "*.c" -o -name "*.h" -o -name "*.cpp" -o -name "*.hpp" \) -not -path "*/.*" -not -path "*/build/*")

if [ -z "$C_FILES" ]; then
    echo -e "${YELLOW}Nenhum arquivo C/C++ encontrado.${NC}"
    exit 0
fi

# Função para verificar formatação
check_formatting() {
    local file="$1"
    
    if command -v clang-format &> /dev/null; then
        if ! clang-format -style=file --dry-run --Werror "$file" 2>/dev/null; then
            echo -e "  ${YELLOW}[AVISO]${NC} Formatação inconsistente (execute: clang-format -i $file)"
            ((WARNINGS++))
        fi
    fi
}

# Função para verificar problemas comuns
check_common_issues() {
    local file="$1"
    
    echo "Verificando: $file"
    
    # Verifica trailing whitespace
    if grep -E '\s+$' "$file" > /dev/null; then
        echo -e "  ${YELLOW}[AVISO]${NC} Espaços em branco no final da linha"
        ((WARNINGS++))
    fi
    
    # Verifica tabs (preferência por espaços em C)
    if grep -P '\t' "$file" > /dev/null; then
        echo -e "  ${YELLOW}[AVISO]${NC} Tabs encontrados (considere usar espaços)"
        ((WARNINGS++))
    fi
    
    # Verifica linhas muito longas (>100 caracteres)
    if awk 'length > 100' "$file" | grep -q .; then
        echo -e "  ${YELLOW}[AVISO]${NC} Linhas muito longas (>100 caracteres)"
        ((WARNINGS++))
    fi
    
    # Verifica headers guards (apenas para .h)
    if [[ "$file" == *.h ]] || [[ "$file" == *.hpp ]]; then
        if ! grep -q "#ifndef\|#pragma once" "$file"; then
            echo -e "  ${RED}[ERRO]${NC} Header guard ausente"
            ((ERRORS++))
        fi
    fi
    
    ((FILES_CHECKED++))
}

# Função para executar cppcheck
run_cppcheck() {
    if command -v cppcheck &> /dev/null; then
        echo -e "\n${BLUE}Executando análise estática com cppcheck...${NC}"
        if ! cppcheck --enable=warning,style,performance,portability --error-exitcode=0 \
            --suppress=missingIncludeSystem \
            --quiet \
            $C_FILES 2>&1 | grep -v "^Checking"; then
            :
        fi
    fi
}

# Processa cada arquivo
for file in $C_FILES; do
    check_common_issues "$file"
    check_formatting "$file"
done

# Executa cppcheck em todos os arquivos
run_cppcheck

# Relatório final
echo ""
echo -e "${BLUE}=== Relatório Final ===${NC}"
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
