# QKern - Kernel do QuackOS

## Fase 0: Kernel Mínimo ✅

Kernel mínimo que demonstra: ELF64, entry `qkern_inicio`, `boot_info*` em RDI, stack 16KB, VGA 0xB8000, HLT.

## Fase 0.5: IDT Mínima ✅

**IDT mínima** para deixar o kernel **observável** em vez de triple fault em qualquer exceção:

✅ **IDT** com 256 entradas; preenchida em runtime a partir de `isr_stub_table`  
✅ **Stubs**: 256 vetores; cada um `push N; jmp common`. Vetor **#8** → `jmp df_handler_direct` (não usa stack do CPU)  
✅ **common_exception_handler**: imprime `EXCEPTION: #XX` em hex na **linha 2** do VGA; `cli`; `hlt`  
✅ **Double fault (#8)**: `df_handler_direct` usa `df_stack` (64 bytes) própria; imprime `EXCEPTION: #DF`; evita triple fault se o handler padrão falhar  
✅ **lidt** após stack e `idt_configurar`; exceções (#DE, #BP, #PF, etc.) passam a ser capturadas  

### Testar a IDT

No `qkern.asm`, após a mensagem de sucesso, descomente:

- `int3` → deve aparecer `EXCEPTION: #03` na linha 2  
- `xor eax,eax; div eax` → `EXCEPTION: #00` (divide by zero)  

### Ainda não (Fase 1)

❌ GDT definitiva  
❌ `sti` e interrupções reais (timer, teclado)  
❌ Transição ASM → C  

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
| `.data`  | Dados inicializados (IDT desc, isr_stub_table) | 4KB |
| `.bss`   | Dados não inicializados (idt, boot_info_ptr, df_stack) | 4KB |
| `.stack` | Stack do kernel 16KB           | 16          |

## Convenção de Chamada

O kernel segue a **System V AMD64 ABI**:

- **RDI**: Ponteiro para `struct boot_info` (passado pelo bootloader)
- **RSP**: Stack pointer (configurada pelo kernel para 16KB própria)
- **RBP**: Base pointer (zerado para marcar início da stack)

## Funcionamento

1. **Entry point** (`qkern_inicio`):
   - Desabilita interrupções (`cli`)
   - Salva `boot_info`, configura stack 16KB, zera RBP
   - **Fase 0.5**: `idt_configurar` (preenche IDT), `lidt`; valida `boot_info`

2. **Escrita em VGA**:
   - Buffer VGA em 0xB8000 (physical)
   - Formato: [ASCII][Atributo] (2 bytes por caractere)
   - Atributo: 0x0F (fundo preto, texto branco brilhante)
   - Mensagem: "QuackOS kernel alive"

3. **Loop infinito**:
   - `hlt` pausa o CPU (economiza energia)
   - Como interrupções estão desabilitadas, fica parado permanentemente

## Próximas Fases

- **Fase 1**: GDT definitiva, `sti`, timer, início da transição ASM → C
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
