#!/usr/bin/env bash
# ==============================================================================
# QuackOS - Script Principal (All-in-One)
# ==============================================================================
# Interface unificada para todos os scripts do QuackOS
# ==============================================================================

set -e

# Cores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# Banner
# ==============================================================================

show_banner() {
    cat << 'EOF'
    ___                   _     ___  ____  
   / _ \ _   _  __ _  ___| | __/ _ \/ ___| 
  | | | | | | |/ _` |/ __| |/ / | | \___ \ 
  | |_| | |_| | (_| | (__|   <| |_| |___) |
   \__\_\\__,_|\__,_|\___|_|\_\\___/|____/ 
                                           
EOF
}

# ==============================================================================
# Menu Principal
# ==============================================================================

show_menu() {
    clear
    echo -e "${CYAN}$(show_banner)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}QuackOS - Sistema de Build e Desenvolvimento${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}🔨 Compilação e Build:${NC}"
    echo "  ${BOLD}1${NC}) Build completo          - Compilar bootloader + kernel + imagem"
    echo "  ${BOLD}2${NC}) Build incremental        - Apenas arquivos modificados"
    echo "  ${BOLD}3${NC}) Limpar build             - Remover artefatos de compilação"
    echo "  ${BOLD}4${NC}) Watch mode               - Compilação contínua automática"
    echo ""
    echo -e "${BLUE}🚀 Execução e Debug:${NC}"
    echo "  ${BOLD}5${NC}) Executar no QEMU         - Rodar normalmente"
    echo "  ${BOLD}6${NC}) Executar com debug       - QEMU em modo debug"
    echo "  ${BOLD}7${NC}) Debug com GDB            - QEMU + GDB interativo"
    echo "  ${BOLD}8${NC}) Executar com KVM         - Virtualização de hardware"
    echo ""
    echo -e "${YELLOW}🧪 Testes e Verificação:${NC}"
    echo "  ${BOLD}9${NC}) Executar testes          - Suite de testes automáticos"
    echo " ${BOLD}10${NC}) Verificar build          - Checar integridade dos binários"
    echo " ${BOLD}11${NC}) Informações do sistema   - Ver detalhes do build"
    echo ""
    echo -e "${CYAN}📚 Utilitários:${NC}"
    echo " ${BOLD}12${NC}) Build + Run              - Compilar e executar"
    echo " ${BOLD}13${NC}) Build + Test + Run       - Pipeline completo"
    echo " ${BOLD}14${NC}) Abrir documentação       - README dos scripts"
    echo ""
    echo -e "${RED} ${BOLD}0${NC}) Sair"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -ne "Escolha uma opção: "
}

# ==============================================================================
# Executar comando com feedback
# ==============================================================================

run_with_feedback() {
    local script=$1
    local description=$2
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🦆 $description${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if "$SCRIPT_DIR/$script"; then
        echo ""
        echo -e "${GREEN}✓ Concluído!${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}✗ Erro ao executar $script${NC}"
        return 1
    fi
}

# ==============================================================================
# Ações do menu
# ==============================================================================

pause() {
    echo ""
    read -p "Pressione ENTER para continuar..."
}

action_build() {
    run_with_feedback "build.sh" "Build Completo"
    pause
}

action_clean() {
    run_with_feedback "clean.sh" "Limpeza"
    pause
}

action_run() {
    run_with_feedback "run.sh" "Executando QuackOS no QEMU"
}

action_run_debug() {
    run_with_feedback "run.sh --debug --monitor" "Executando em Modo Debug"
}

action_debug_gdb() {
    "$SCRIPT_DIR/debug.sh"
}

action_run_kvm() {
    run_with_feedback "run.sh --kvm" "Executando com KVM"
}

action_test() {
    run_with_feedback "test.sh" "Executando Testes"
    pause
}

action_info() {
    "$SCRIPT_DIR/info.sh" --all
    pause
}

action_watch() {
    "$SCRIPT_DIR/watch.sh"
}

action_build_run() {
    if run_with_feedback "build.sh" "Build Completo"; then
        echo ""
        run_with_feedback "run.sh" "Executando QuackOS"
    fi
}

action_full_pipeline() {
    if run_with_feedback "clean.sh" "Limpeza"; then
        if run_with_feedback "build.sh" "Build Completo"; then
            if run_with_feedback "test.sh" "Testes"; then
                echo ""
                run_with_feedback "run.sh" "Executando QuackOS"
            fi
        fi
    fi
}

action_docs() {
    if command -v less &> /dev/null; then
        less "$SCRIPT_DIR/README.md"
    else
        cat "$SCRIPT_DIR/README.md"
        pause
    fi
}

# ==============================================================================
# Loop principal
# ==============================================================================

main_loop() {
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1) action_build ;;
            2) 
                echo ""
                echo -e "${YELLOW}Build incremental: use make diretamente${NC}"
                echo "  cd bootloader && make"
                echo "  cd kernel && make"
                pause
                ;;
            3) action_clean ;;
            4) action_watch ;;
            5) action_run ;;
            6) action_run_debug ;;
            7) action_debug_gdb ;;
            8) action_run_kvm ;;
            9) action_test ;;
            10) 
                "$SCRIPT_DIR/info.sh" --disk
                pause
                ;;
            11) action_info ;;
            12) action_build_run ;;
            13) action_full_pipeline ;;
            14) action_docs ;;
            0)
                clear
                echo -e "${CYAN}🦆 Até logo!${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo ""
                echo -e "${RED}Opção inválida!${NC}"
                sleep 1
                ;;
        esac
    done
}

# ==============================================================================
# Ajuda da linha de comando
# ==============================================================================

show_help() {
    cat << EOF
${CYAN}QuackOS - Script Principal${NC}

Uso: $0 [comando]

Comandos Rápidos:
  build           - Compilar bootloader + kernel
  run             - Executar no QEMU
  test            - Executar testes
  clean           - Limpar build
  debug           - Debug com GDB
  info            - Informações do sistema
  watch           - Watch mode (compilação contínua)
  
  build-run       - Compilar e executar
  pipeline        - Clean + Build + Test + Run

Sem argumentos: Abre menu interativo

Exemplos:
  $0              # Menu interativo
  $0 build        # Build direto
  $0 build-run    # Build e executar
  $0 pipeline     # Pipeline completo

EOF
}

# ==============================================================================
# Main
# ==============================================================================

# Se chamado com argumento, executar comando direto
if [ $# -gt 0 ]; then
    case "$1" in
        -h|--help|help)
            show_help
            exit 0
            ;;
        build)
            action_build
            ;;
        run)
            action_run
            ;;
        test)
            action_test
            ;;
        clean)
            action_clean
            ;;
        debug)
            action_debug_gdb
            ;;
        info)
            action_info
            ;;
        watch)
            action_watch
            ;;
        build-run)
            action_build_run
            ;;
        pipeline)
            action_full_pipeline
            ;;
        *)
            echo -e "${RED}Comando desconhecido: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
else
    # Menu interativo
    main_loop
fi
