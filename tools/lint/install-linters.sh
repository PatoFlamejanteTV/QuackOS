#!/usr/bin/env bash
# Script para instalar dependências de linting do QuackOS
# QuackOS Project

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║   QuackOS - Instalador de Linters     ║${NC}"
echo -e "${BOLD}${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Verifica se está rodando como root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}[ERRO] Não execute este script como root!${NC}"
    echo "Execute sem sudo. O script pedirá senha quando necessário."
    exit 1
fi

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" &> /dev/null
}

# Função para instalar pacotes APT
install_apt_packages() {
    local packages=("$@")
    local to_install=()
    
    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            to_install+=("$pkg")
        else
            echo -e "${GREEN}✓${NC} $pkg já está instalado"
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}Instalando pacotes APT...${NC}"
        sudo apt update
        sudo apt install -y "${to_install[@]}"
        echo -e "${GREEN}✓ Pacotes APT instalados com sucesso!${NC}"
    fi
}

# Função para instalar pacotes NPM globais
install_npm_packages() {
    if ! command_exists npm; then
        echo -e "${YELLOW}NPM não encontrado. Instalando Node.js...${NC}"
        sudo apt install -y nodejs npm
    fi
    
    local packages=("$@")
    
    for pkg in "${packages[@]}"; do
        if ! npm list -g "$pkg" &> /dev/null; then
            echo -e "${YELLOW}Instalando $pkg...${NC}"
            sudo npm install -g "$pkg"
            echo -e "${GREEN}✓ $pkg instalado${NC}"
        else
            echo -e "${GREEN}✓${NC} $pkg já está instalado"
        fi
    done
}

echo -e "${BOLD}1. Ferramentas do Sistema (APT)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

APT_PACKAGES=(
    "clang-format"      # Formatador de C/C++
    "cppcheck"          # Análise estática de C/C++
    "shellcheck"        # Linter de shell scripts
    "nasm"              # Assembler (para validação)
)

install_apt_packages "${APT_PACKAGES[@]}"

echo ""
echo -e "${BOLD}2. Ferramentas Node.js (NPM)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

NPM_PACKAGES=(
    "markdownlint-cli"  # Linter de Markdown
)

install_npm_packages "${NPM_PACKAGES[@]}"

echo ""
echo -e "${BOLD}3. Verificação Final${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOOLS=(
    "clang-format:Formatador C/C++"
    "cppcheck:Análise estática C/C++"
    "shellcheck:Linter Shell"
    "nasm:Assembler NASM"
    "markdownlint:Linter Markdown"
)

ALL_OK=true

for tool_entry in "${TOOLS[@]}"; do
    IFS=':' read -r cmd desc <<< "$tool_entry"
    if command_exists "$cmd"; then
        echo -e "${GREEN}✓${NC} $desc ($cmd)"
    else
        echo -e "${RED}✗${NC} $desc ($cmd) - NÃO ENCONTRADO"
        ALL_OK=false
    fi
done

echo ""
if [ "$ALL_OK" = true ]; then
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║   Instalação Concluída com Sucesso!   ║${NC}"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Você pode agora executar os linters:"
    echo -e "  ${BLUE}./tools/lint/lint-all.sh${NC}"
    exit 0
else
    echo -e "${YELLOW}${BOLD}╔════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${BOLD}║   Instalação Parcial                  ║${NC}"
    echo -e "${YELLOW}${BOLD}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Algumas ferramentas não foram instaladas.${NC}"
    echo "Os linters ainda funcionarão com funcionalidade reduzida."
    exit 0
fi
