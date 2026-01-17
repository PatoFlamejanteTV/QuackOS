#!/usr/bin/env bash
# Script de linting para Makefiles
# QuackOS Project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}=== QuackOS Makefile Linter ===${NC}"

# Contador de erros
ERRORS=0
WARNINGS=0
FILES_CHECKED=0

# Encontra todos os Makefiles
MAKEFILES=$(find "$PROJECT_ROOT" -type f \( -name "Makefile" -o -name "*.mk" -o -name "GNUmakefile" \) -not -path "*/.*" -not -path "*/build/*")

if [ -z "$MAKEFILES" ]; then
    echo -e "${YELLOW}Nenhum Makefile encontrado.${NC}"
    exit 0
fi

# Função para verificar problemas comuns
check_makefile() {
    local file="$1"
    
    echo "Verificando: $file"
    
    # Verifica se usa tabs (OBRIGATÓRIO em Makefiles)
    if grep -n '^    ' "$file" | grep -v '^[^:]*:#' | head -1; then
        local line_num=$(grep -n '^    ' "$file" | grep -v '^[^:]*:#' | head -1 | cut -d: -f1)
        echo -e "  ${RED}[ERRO]${NC} Espaços detectados em vez de tabs na linha $line_num (Makefiles exigem tabs)"
        echo -e "  ${YELLOW}        Use tabs para indentação de comandos!${NC}"
        ((ERRORS++))
    fi
    
    # Verifica trailing whitespace
    if grep -E '\s+$' "$file" > /dev/null; then
        echo -e "  ${YELLOW}[AVISO]${NC} Espaços em branco no final da linha"
        ((WARNINGS++))
    fi
    
    # Verifica se .PHONY está sendo usado
    if ! grep -q "^\.PHONY:" "$file"; then
        echo -e "  ${YELLOW}[AVISO]${NC} Nenhuma declaração .PHONY encontrada (boa prática para targets não-arquivo)"
        ((WARNINGS++))
    fi
    
    # Verifica variáveis não definidas (básico)
    local undefined_vars=$(grep -o '\$([A-Z_][A-Z0-9_]*)' "$file" | sort -u)
    if [ -n "$undefined_vars" ]; then
        # Verifica se as variáveis estão definidas no arquivo
        for var in $undefined_vars; do
            local var_name=$(echo "$var" | sed 's/\$(\(.*\))/\1/')
            if ! grep -q "^$var_name\s*[:?]=" "$file" && ! grep -q "^export $var_name" "$file"; then
                # Algumas variáveis padrão do Make são OK
                if [[ ! "$var_name" =~ ^(CC|CXX|LD|AR|AS|CFLAGS|CXXFLAGS|LDFLAGS|ASFLAGS)$ ]]; then
                    echo -e "  ${YELLOW}[AVISO]${NC} Variável possivelmente não definida: $var_name"
                    ((WARNINGS++))
                fi
            fi
        done
    fi
    
    # Tenta validar sintaxe básica com make -n
    if command -v make &> /dev/null; then
        local makefile_dir=$(dirname "$file")
        if ! make -n -f "$file" -C "$makefile_dir" &>/dev/null; then
            # Isso pode falhar por dependências, então é apenas um aviso
            echo -e "  ${YELLOW}[AVISO]${NC} Possíveis problemas de sintaxe detectados"
            ((WARNINGS++))
        fi
    fi
    
    ((FILES_CHECKED++))
}

# Processa cada arquivo
for file in $MAKEFILES; do
    check_makefile "$file"
done

# Relatório final
echo ""
echo -e "${PURPLE}=== Relatório Final ===${NC}"
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
