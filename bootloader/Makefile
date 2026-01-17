# ==============================================================================
# QuackOS Bootloader - Makefile
# ==============================================================================
# 
# Compilação do bootloader em dois estágios:
#   - boot.asm (MBR, 512 bytes)
#   - stage2.asm (Stage 2, 8KB)
#
# Saída: quackos.img (imagem de disco bootável)
# ==============================================================================

# Ferramentas
NASM = nasm
DD = dd
QEMU = qemu-system-x86_64

# Diretórios
BUILD_DIR = build

# Arquivos
MBR = boot.asm
STAGE2 = stage2.asm
MBR_BIN = $(BUILD_DIR)/boot.bin
STAGE2_BIN = $(BUILD_DIR)/stage2.bin
DISK_IMG = $(BUILD_DIR)/quackos.img

# Flags do NASM
NASM_FLAGS = -f bin

# ==============================================================================
# ALVOS PRINCIPAIS
# ==============================================================================

.PHONY: all clean run debug

all: $(DISK_IMG)
	@echo "✅ QuackOS bootloader compilado com sucesso!"
	@echo "   Imagem: $(DISK_IMG)"

# ==============================================================================
# COMPILAÇÃO
# ==============================================================================

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Compilar MBR
$(MBR_BIN): $(MBR) | $(BUILD_DIR)
	@echo "🔨 Compilando MBR (boot.asm)..."
	$(NASM) $(NASM_FLAGS) $< -o $@
	@# Verificar tamanho (deve ser exatamente 512 bytes)
	@if [ `stat -c%s $(MBR_BIN)` -ne 512 ]; then \
		echo "❌ ERRO: MBR deve ter exatamente 512 bytes!"; \
		exit 1; \
	fi
	@echo "   ✓ MBR: 512 bytes"

# Compilar Stage 2
$(STAGE2_BIN): $(STAGE2) | $(BUILD_DIR)
	@echo "🔨 Compilando Stage 2 (stage2.asm)..."
	$(NASM) $(NASM_FLAGS) $< -o $@
	@# Verificar tamanho (deve ser 8192 bytes / 16 setores)
	@if [ `stat -c%s $(STAGE2_BIN)` -ne 8192 ]; then \
		echo "❌ ERRO: Stage 2 deve ter exatamente 8192 bytes!"; \
		exit 1; \
	fi
	@echo "   ✓ Stage 2: 8192 bytes (16 setores)"

# Criar imagem de disco
$(DISK_IMG): $(MBR_BIN) $(STAGE2_BIN)
	@echo "💾 Criando imagem de disco..."
	@# Criar imagem vazia de 10MB
	$(DD) if=/dev/zero of=$@ bs=1M count=10 status=none
	@# Escrever MBR no LBA 0
	$(DD) if=$(MBR_BIN) of=$@ bs=512 count=1 conv=notrunc status=none
	@# Escrever Stage 2 no LBA 1
	$(DD) if=$(STAGE2_BIN) of=$@ bs=512 seek=1 count=16 conv=notrunc status=none
	@echo "   ✓ Imagem criada: $(DISK_IMG) (10 MB)"

# ==============================================================================
# EXECUÇÃO E DEBUG
# ==============================================================================

# Executar no QEMU
run: $(DISK_IMG)
	@echo "🦆 Iniciando QuackOS no QEMU..."
	$(QEMU) -drive format=raw,file=$(DISK_IMG) -m 256M

# Debug com QEMU (modo monitor e serial)
debug: $(DISK_IMG)
	@echo "🔍 Iniciando QuackOS no QEMU (modo debug)..."
	$(QEMU) -drive format=raw,file=$(DISK_IMG) \
		-m 256M \
		-monitor stdio \
		-d int,cpu_reset \
		-no-reboot \
		-no-shutdown

# Debug com interface gráfica
debug-gui: $(DISK_IMG)
	@echo "🔍 Iniciando QuackOS no QEMU (debug com GUI)..."
	$(QEMU) -drive format=raw,file=$(DISK_IMG) \
		-m 256M \
		-d int \
		-no-reboot

# ==============================================================================
# LIMPEZA
# ==============================================================================

clean:
	@echo "🧹 Limpando arquivos compilados..."
	rm -rf $(BUILD_DIR)
	@echo "   ✓ Limpeza concluída"

# ==============================================================================
# AJUDA
# ==============================================================================

help:
	@echo "QuackOS Bootloader - Makefile"
	@echo ""
	@echo "Alvos disponíveis:"
	@echo "  make           - Compilar bootloader e criar imagem"
	@echo "  make run       - Executar no QEMU"
	@echo "  make debug     - Executar no QEMU com debug"
	@echo "  make debug-gui - Debug com interface gráfica"
	@echo "  make clean     - Remover arquivos compilados"
	@echo "  make help      - Exibir esta ajuda"
	@echo ""
	@echo "Estrutura da imagem:"
	@echo "  LBA 0      : MBR (boot.bin, 512 bytes)"
	@echo "  LBA 1-16   : Stage 2 (stage2.bin, 8KB)"
	@echo "  LBA 17+    : Kernel (qkern.bin, a ser implementado)"
