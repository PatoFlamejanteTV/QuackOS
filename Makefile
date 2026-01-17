CC = gcc
AS = nasm
LD = ld

CFLAGS = -Wall -Wextra -std=c11 -ffreestanding -nostdlib -m64 -O2
LDFLAGS = -T qk_kernel/linker.ld

KERNEL_BIN = bin/qkern.bin
BOOT_BIN = bin/boot.bin
OS_IMG = bin/quackos.img

all: $(OS_IMG)

$(OS_IMG): $(BOOT_BIN) $(KERNEL_BIN)
	cat $(BOOT_BIN) $(KERNEL_BIN) > $(OS_IMG)
	# Garante que a imagem tenha o tamanho mínimo de um setor se necessário,
	# mas aqui apenas concatenamos.

$(BOOT_BIN): boot/stage1.asm boot/stage2.asm
	mkdir -p bin
	$(AS) -f bin boot/stage1.asm -o bin/stage1.bin
	$(AS) -f bin boot/stage2.asm -o bin/stage2.bin
	cat bin/stage1.bin bin/stage2.bin > $(BOOT_BIN)

$(KERNEL_BIN): qk_kernel/entry.o qk_kernel/main.o
	$(LD) $(LDFLAGS) -o $(KERNEL_BIN) qk_kernel/entry.o qk_kernel/main.o --oformat binary

qk_kernel/entry.o: qk_kernel/entry.asm
	$(AS) -f elf64 qk_kernel/entry.asm -o qk_kernel/entry.o

qk_kernel/main.o: qk_kernel/main.c
	$(CC) $(CFLAGS) -c qk_kernel/main.c -o qk_kernel/main.o

clean:
	rm -rf bin/*.bin bin/*.img qk_kernel/*.o
