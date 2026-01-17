#!/usr/bin/env bash
# ==============================================================================
# QuackOS - Script de Execução com QEMU
# ==============================================================================
# Executa o QuackOS no QEMU com várias opções
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
BUILD_DIR="$PROJECT_ROOT/build"
DISK_IMG="$BUILD_DIR/quackos.img"

# Configurações padrão
MEMORY="256M"
CPU_COUNT="1"
DEBUG_MODE=false
MONITOR_MODE=false
NO_GRAPHIC=false
KVM=false

# ==============================================================================
# Ajuda
# ==============================================================================

show_help() {
    cat << EOF
${CYAN}QuackOS - Script de Execução${NC}

Uso: $0 [opções]

Opções:
  -h, --help              Exibir esta ajuda
  -d, --debug             Modo debug (sem reboot, com log de interrupts)
  -m, --monitor           Abrir monitor do QEMU (stdio)
  -n, --nographic         Modo sem interface gráfica (serial console)
  -k, --kvm               Usar KVM (virtualização de hardware)
  --memory SIZE           Memória RAM (padrão: 256M)
  --cpus N                Número de CPUs (padrão: 1)
  --build                 Compilar antes de executar

Exemplos:
  $0                      Executar normalmente
  $0 --debug              Executar em modo debug
  $0 --monitor --debug    Debug com monitor QEMU
  $0 --kvm --memory 512M  Usar KVM com 512MB de RAM
  $0 --build              Compilar e executar

EOF
}

# ==============================================================================
# Parse de argumentos
# ==============================================================================

BUILD_FIRST=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--debug)
            DEBUG_MODE=true
            shift
            ;;
        -m|--monitor)
            MONITOR_MODE=true
            shift
            ;;
        -n|--nographic)
            NO_GRAPHIC=true
            shift
            ;;
        -k|--kvm)
            KVM=true
            shift
            ;;
        --memory)
            MEMORY="$2"
            shift 2
            ;;
        --cpus)
            CPU_COUNT="$2"
            shift 2
            ;;
        --build)
            BUILD_FIRST=true
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
# Verificar dependências
# ==============================================================================

if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo -e "${RED}ERRO: qemu-system-x86_64 não encontrado${NC}"
    echo "Instale com: sudo apt install qemu-system-x86"
    exit 1
fi

# ==============================================================================
# Build (se solicitado)
# ==============================================================================

if [ "$BUILD_FIRST" = true ]; then
    echo -e "${CYAN}🔨 Compilando QuackOS...${NC}"
    "$SCRIPT_DIR/build.sh"
    echo ""
fi

# ==============================================================================
# Verificar imagem
# ==============================================================================

if [ ! -f "$DISK_IMG" ]; then
    echo -e "${RED}ERRO: Imagem de disco não encontrada: $DISK_IMG${NC}"
    echo ""
    echo "Compile primeiro com:"
    echo "  ./scripts/build.sh"
    echo ""
    echo "Ou execute com --build:"
    echo "  ./scripts/run.sh --build"
    exit 1
fi

# ==============================================================================
# Construir comando QEMU
# ==============================================================================

QEMU_CMD="qemu-system-x86_64"
QEMU_ARGS=(
    "-drive" "format=raw,file=$DISK_IMG"
    "-m" "$MEMORY"
    "-smp" "$CPU_COUNT"
)

# KVM
if [ "$KVM" = true ]; then
    QEMU_ARGS+=("-enable-kvm")
fi

# Modo debug
if [ "$DEBUG_MODE" = true ]; then
    QEMU_ARGS+=(
        "-d" "int,cpu_reset"
        "-D" "$BUILD_DIR/qemu.log"
        "-no-reboot"
        "-no-shutdown"
    )
fi

# Monitor
if [ "$MONITOR_MODE" = true ]; then
    QEMU_ARGS+=("-monitor" "stdio")
fi

# Sem gráficos
if [ "$NO_GRAPHIC" = true ]; then
    QEMU_ARGS+=(
        "-nographic"
        "-serial" "stdio"
    )
fi

# ==============================================================================
# Executar
# ==============================================================================

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🦆 Iniciando QuackOS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Configuração:${NC}"
echo "  Imagem: $DISK_IMG"
echo "  Memória: $MEMORY"
echo "  CPUs: $CPU_COUNT"
echo "  Debug: $DEBUG_MODE"
echo "  Monitor: $MONITOR_MODE"
echo "  KVM: $KVM"
echo ""

if [ "$DEBUG_MODE" = true ]; then
    echo -e "${YELLOW}Modo debug ativado. Logs em: $BUILD_DIR/qemu.log${NC}"
    echo ""
fi

echo -e "${CYAN}Comando QEMU:${NC}"
echo "$QEMU_CMD ${QEMU_ARGS[*]}"
echo ""

# Executar QEMU
exec $QEMU_CMD "${QEMU_ARGS[@]}"
