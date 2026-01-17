#!/bin/bash
# ==============================================================================
# Script de Instalação de Dependências - QuackOS Bootloader
# ==============================================================================

echo "🦆 QuackOS - Instalação de Dependências do Bootloader"
echo ""

# Detectar sistema operacional
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ Sistema operacional não detectado"
    exit 1
fi

echo "📦 Sistema detectado: $OS"
echo ""

# Instalação baseada no OS
case $OS in
    ubuntu|debian|pop)
        echo "🔧 Instalando dependências com apt..."
        sudo apt update
        sudo apt install -y nasm qemu-system-x86 build-essential
        ;;
    
    fedora|rhel|centos)
        echo "🔧 Instalando dependências com dnf..."
        sudo dnf install -y nasm qemu-system-x86 gcc make
        ;;
    
    arch|manjaro)
        echo "🔧 Instalando dependências com pacman..."
        sudo pacman -S --noconfirm nasm qemu-system-x86 base-devel
        ;;
    
    *)
        echo "❌ Sistema não suportado automaticamente"
        echo "Por favor, instale manualmente:"
        echo "  - nasm (assembler)"
        echo "  - qemu-system-x86 (emulador)"
        echo "  - build-essential ou equivalente"
        exit 1
        ;;
esac

# Verificar instalação
echo ""
echo "✅ Verificando instalação..."
echo ""

if command -v nasm &> /dev/null; then
    echo "  ✓ NASM: $(nasm -v)"
else
    echo "  ✗ NASM não encontrado"
    exit 1
fi

if command -v qemu-system-x86_64 &> /dev/null; then
    echo "  ✓ QEMU: $(qemu-system-x86_64 --version | head -n 1)"
else
    echo "  ✗ QEMU não encontrado"
    exit 1
fi

if command -v make &> /dev/null; then
    echo "  ✓ Make: $(make --version | head -n 1)"
else
    echo "  ✗ Make não encontrado"
    exit 1
fi

echo ""
echo "🎉 Todas as dependências instaladas com sucesso!"
echo ""
echo "Próximos passos:"
echo "  1. cd /home/quack/QuackOS/bootloader"
echo "  2. make          # Compilar bootloader"
echo "  3. make run      # Executar no QEMU"
