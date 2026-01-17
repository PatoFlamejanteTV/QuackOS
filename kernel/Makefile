# ==============================================================================
# QuackOS - Makefile do QKern (Fase 0)
# ==============================================================================
# Compila o kernel mínimo em ELF64
# ==============================================================================

# ------------------------------------------------------------------------------
# CONFIGURAÇÕES
# ------------------------------------------------------------------------------

# Assembler e Linker
AS = nasm
LD = ld

# Flags do NASM
ASFLAGS = -f elf64 -g -F dwarf

# Flags do Linker
LDFLAGS = -T linker.ld -nostdlib -static

# Arquivos
ASM_SRC = qkern.asm
OBJ = qkern.o
KERNEL = qkern.elf

# ------------------------------------------------------------------------------
# REGRAS
# ------------------------------------------------------------------------------

# Regra padrão: compilar o kernel
all: $(KERNEL)

# Compilar assembly -> object file
$(OBJ): $(ASM_SRC)
	@echo "[AS] $< -> $@"
	$(AS) $(ASFLAGS) $< -o $@

# Linkar object file -> ELF64
$(KERNEL): $(OBJ) linker.ld
	@echo "[LD] $@"
	$(LD) $(LDFLAGS) $(OBJ) -o $@
	@echo "✓ QKern compilado com sucesso: $(KERNEL)"
	@echo ""
	@echo "Informações do kernel:"
	@file $(KERNEL)
	@size $(KERNEL)
	@echo ""
	@echo "Entry point:"
	@readelf -h $(KERNEL) | grep Entry

# Limpar arquivos gerados
clean:
	@echo "Limpando build artifacts..."
	rm -f $(OBJ) $(KERNEL)
	@echo "✓ Limpo"

# Recompilar do zero
rebuild: clean all

# Informações sobre o kernel (útil para debugging)
info: $(KERNEL)
	@echo "=== Informações do QKern ==="
	@file $(KERNEL)
	@echo ""
	@echo "=== ELF Header ==="
	@readelf -h $(KERNEL)
	@echo ""
	@echo "=== Seções ==="
	@readelf -S $(KERNEL)
	@echo ""
	@echo "=== Símbolos ==="
	@readelf -s $(KERNEL)
	@echo ""
	@echo "=== Tamanho das seções ==="
	@size $(KERNEL)

# Disassembly (útil para verificar o código gerado)
disasm: $(KERNEL)
	@echo "=== Disassembly do QKern ==="
	objdump -D -M intel $(KERNEL) | less

# Verificar se entry point está correto
check: $(KERNEL)
	@echo "Verificando entry point..."
	@readelf -h $(KERNEL) | grep -q "qkern_inicio" && echo "✓ Entry point correto" || echo "✗ Entry point incorreto"
	@echo ""
	@echo "Verificando formato..."
	@file $(KERNEL) | grep -q "ELF 64-bit" && echo "✓ Formato ELF64 correto" || echo "✗ Formato incorreto"

# Phony targets (não são arquivos)
.PHONY: all clean rebuild info disasm check
