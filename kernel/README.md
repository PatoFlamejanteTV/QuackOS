# QKern - Kernel do QuackOS

## Fase 0: Kernel Mínimo

Esta é a **Fase 0** do QKern, um kernel mínimo que demonstra:

✅ Compilação como ELF64  
✅ Entry point em `qkern_inicio`  
✅ Recebimento de `struct boot_info*` em RDI  
✅ Configuração de stack própria (16KB)  
✅ Escrita em VGA text mode (0xB8000)  
✅ Loop infinito com HLT  

### Não Implementado (por design)

❌ Interrupções (IDT)  
❌ Heap  
❌ Syscalls  
❌ Drivers  
❌ Multitarefa  

## Estrutura de Arquivos

```
kernel/
├── qkern.asm       # Código principal do kernel (64-bit)
├── linker.ld       # Linker script para ELF64
├── Makefile        # Build system
├── boot_info.h     # Definição da struct boot_info (documentação)
└── README.md       # Este arquivo
```

## Compilação

### Requisitos

- `nasm` (Netwide Assembler)
- `ld` (GNU Linker)
- `make`

### Build

```bash
cd /home/quack/QuackOS/kernel
make
```

Isso irá gerar `qkern.elf`, o kernel em formato ELF64.

### Comandos Úteis

```bash
make all      # Compilar o kernel
make clean    # Limpar arquivos gerados
make rebuild  # Recompilar do zero
make info     # Mostrar informações sobre o kernel
make disasm   # Ver disassembly do código
make check    # Verificar entry point e formato
```

## Verificação

Após compilar, você pode verificar o kernel:

```bash
# Ver formato do arquivo
file qkern.elf

# Ver entry point
readelf -h qkern.elf | grep Entry

# Ver seções
readelf -S qkern.elf

# Ver tamanho
size qkern.elf

# Disassembly
objdump -D -M intel qkern.elf
```

## Layout de Memória

O kernel é carregado em **1MB (0x100000)** para evitar conflitos com:

- BIOS data area (0x0000 - 0x0500)
- Bootloader (0x7C00 - 0x7DFF)
- Stack do bootloader (0x7E00 - ~0x9FFFF)
- Video memory (0xA0000 - 0xFFFFF)

### Seções

| Seção    | Descrição                      | Alinhamento |
|----------|--------------------------------|-------------|
| `.text`  | Código executável              | 4KB         |
| `.rodata`| Dados somente leitura          | 4KB         |
| `.data`  | Dados inicializados            | 4KB         |
| `.bss`   | Dados não inicializados (zero) | 4KB         |

## Convenção de Chamada

O kernel segue a **System V AMD64 ABI**:

- **RDI**: Ponteiro para `struct boot_info` (passado pelo bootloader)
- **RSP**: Stack pointer (configurada pelo kernel para 16KB própria)
- **RBP**: Base pointer (zerado para marcar início da stack)

## Funcionamento

1. **Entry point** (`qkern_inicio`):
   - Desabilita interrupções (`cli`)
   - Salva ponteiro `boot_info` de RDI
   - Configura stack própria de 16KB
   - Zera RBP

2. **Escrita em VGA**:
   - Buffer VGA em 0xB8000 (physical)
   - Formato: [ASCII][Atributo] (2 bytes por caractere)
   - Atributo: 0x0F (fundo preto, texto branco brilhante)
   - Mensagem: "QuackOS kernel alive"

3. **Loop infinito**:
   - `hlt` pausa o CPU (economiza energia)
   - Como interrupções estão desabilitadas, fica parado permanentemente

## Próximas Fases

- **Fase 1**: GDT própria, IDT básica, tratamento de exceções
- **Fase 2**: Gerenciamento de memória (PMM, VMM)
- **Fase 3**: Heap (kmalloc/kfree)
- **Fase 4**: Drivers básicos (teclado, timer)
- **Fase 5**: Multitarefa cooperativa
- **Fase 6**: Syscalls e userspace

## Exemplo de Saída (VGA)

```
QuackOS kernel alive
```

A mensagem aparece no canto superior esquerdo da tela em modo texto VGA.

## Notas Técnicas

### Por que 1MB?

O endereço 0x100000 (1MB) é convencional para kernels x86 porque:

- Está acima da memória convencional (< 1MB)
- Evita conflitos com BIOS e hardware legacy
- É o início da "extended memory"
- É o padrão usado por GRUB e outros bootloaders

### Por que HLT em loop?

```asm
.halt_loop:
    hlt
    jmp .halt_loop
```

- `hlt` pausa o CPU até a próxima interrupção (economiza energia)
- Como interrupções estão desabilitadas (`cli`), o CPU fica parado
- O `jmp` garante que mesmo se houver NMI (non-maskable interrupt), volta ao halt
- É mais eficiente que um loop vazio (`jmp $`)

### Stack de 16KB

- Tamanho razoável para kernel simples
- Alinhada em 16 bytes (exigência da ABI)
- Cresce para baixo (RSP aponta para o topo)
- RBP zerado marca início da call stack (útil para stack traces)

## Autor

PatoFlamejanteTV (QuackOS Project)

## Licença

Ver arquivo LICENSE na raiz do projeto.
