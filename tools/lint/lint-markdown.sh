#!/usr/bin/env bash
# Script de linting para arquivos Markdown (.md)
# QuackOS Project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${MAGENTA}=== QuackOS Markdown Linter ===${NC}"

# Verifica se markdownlint-cli está instalado
if ! command -v markdownlint &> /dev/null; then
    echo -e "${YELLOW}[AVISO]${NC} markdownlint não encontrado."
    echo "Para instalar: npm install -g markdownlint-cli"
    echo "Continuando com verificações básicas..."
    USE_MARKDOWNLINT=false
else
    USE_MARKDOWNLINT=true
fi

# Contador de erros
ERRORS=0
WARNINGS=0
FILES_CHECKED=0

# Encontra todos os arquivos markdown
MD_FILES=$(find "$PROJECT_ROOT" -type f -name "*.md" -not -path "*/.*" -not -path "*/node_modules/*")

if [ -z "$MD_FILES" ]; then
    echo -e "${YELLOW}Nenhum arquivo markdown encontrado.${NC}"
    exit 0
fi

# Função para verificar problemas básicos
check_basic_issues() {
    local file="$1"
    
    echo "Verificando: $file"
    
    # Verifica trailing whitespace
    if grep -E '\s+$' "$file" > /dev/null; then
        echo -e "  ${YELLOW}[AVISO]${NC} Espaços em branco no final da linha"
        ((WARNINGS++))
    fi
    
    # Verifica múltiplas linhas em branco consecutivas
    if grep -Pzo '\n\n\n+' "$file" > /dev/null; then
        echo -e "  ${YELLOW}[AVISO]${NC} Múltiplas linhas em branco consecutivas"
        ((WARNINGS++))
    fi
    
    # Verifica se há um título de nível 1 (# Título)
    if ! grep -q "^# " "$file"; then
        echo -e "  ${YELLOW}[AVISO]${NC} Nenhum título de nível 1 encontrado"
        ((WARNINGS++))
    fi
    
    # Verifica links quebrados locais (básico)
    while IFS= read -r line; do
        if [[ "$line" =~ \[.*\]\(([^)]+)\) ]]; then
            local link="${BASH_REMATCH[1]}"
            # Verifica apenas links locais (não URLs)
            if [[ ! "$link" =~ ^https?:// ]] && [[ ! "$link" =~ ^# ]]; then
                local link_path=$(dirname "$file")/"$link"
                if [ ! -f "$link_path" ] && [ ! -d "$link_path" ]; then
                    echo -e "  ${YELLOW}[AVISO]${NC} Link possivelmente quebrado: $link"
                    ((WARNINGS++))
                fi
            fi
        fi
    done < "$file"
    
    ((FILES_CHECKED++))
}

# Função para executar markdownlint
run_markdownlint() {
    if [ "$USE_MARKDOWNLINT" = true ]; then
        echo -e "\n${MAGENTA}Executando markdownlint...${NC}"
        # Configuração básica do markdownlint
        local config='{
            "default": true,
            "MD013": false,
            "MD033": false,
            "MD041": false
        }'
        
        for file in $MD_FILES; do
            if ! markdownlint "$file" 2>&1; then
                ((ERRORS++))
            fi
        done
    fi
}

# Processa cada arquivo
for file in $MD_FILES; do
    check_basic_issues "$file"
done

# Executa markdownlint se disponível
run_markdownlint

# Relatório final
echo ""
echo -e "${MAGENTA}=== Relatório Final ===${NC}"
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
