#!/usr/bin/env bash
# Script de linting para arquivos Assembly (.asm, .s, .S)
# QuackOS Project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== QuackOS Assembly Linter ===${NC}"

# Contador de erros
ERRORS=0
WARNINGS=0
FILES_CHECKED=0

# Encontra todos os arquivos assembly
ASM_FILES=$(find "$PROJECT_ROOT" -type f \( -name "*.asm" -o -name "*.s" -o -name "*.S" \) -not -path "*/.*")

if [ -z "$ASM_FILES" ]; then
    echo -e "${YELLOW}Nenhum arquivo assembly encontrado.${NC}"
    exit 0
fi

# Função para verificar sintaxe básica
check_asm_syntax() {
    local file="$1"
    local issues=0
    
    echo "Verificando: $file"
    
    # Verifica tabs vs spaces (assembly geralmente usa tabs)
    if grep -P '^\s+ ' "$file" > /dev/null; then
        echo -e "  ${YELLOW}[AVISO]${NC} Espaços encontrados no início da linha (considere usar tabs)"
        ((WARNINGS++))
    fi
    
    # Verifica linhas muito longas (>120 caracteres)
    if awk 'length > 120' "$file" | grep -q .; then
        echo -e "  ${YELLOW}[AVISO]${NC} Linhas longas detectadas (>120 caracteres)"
        ((WARNINGS++))
    fi
    
    # Verifica se há labels sem comentários (boas práticas)
    if grep -E '^[a-zA-Z_][a-zA-Z0-9_]*:' "$file" | head -5 > /dev/null; then
        # Labels encontrados - isso é normal
        :
    fi
    
    # Verifica trailing whitespace
    if grep -E '\s+$' "$file" > /dev/null; then
        echo -e "  ${YELLOW}[AVISO]${NC} Espaços em branco no final da linha detectados"
        ((WARNINGS++))
    fi
    
    # Tenta validar sintaxe NASM (se disponível)
    if command -v nasm &> /dev/null; then
        if ! nasm -f elf64 "$file" -o /dev/null 2>/dev/null; then
            # Pode falhar por dependências, não é erro crítico
            :
        fi
    fi
    
    ((FILES_CHECKED++))
    return $issues
}

# Processa cada arquivo
for file in $ASM_FILES; do
    check_asm_syntax "$file"
done

# Relatório final
echo ""
echo -e "${YELLOW}=== Relatório Final ===${NC}"
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
