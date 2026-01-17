/* ===========================================================================
 * QuackOS - Linker Script para QKern (ELF64)
 * ===========================================================================
 * Arquivo: linker.ld
 * Formato de saída: ELF64 executável
 * Arquitetura: x86-64
 *
 * Este linker script define o layout do kernel em memória:
 * - Entry point: qkern_inicio
 * - Baseado em 1MB (0x100000) - higher half será implementado depois
 * - Seções: .text, .rodata, .data, .bss
 * ===========================================================================
 */

/* Arquitetura e formato */
OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)

/* Entry point do kernel */
ENTRY(qkern_inicio)

/* Layout de memória */
SECTIONS
{
    /* Kernel carregado em 1MB (convencional para kernels x86) */
    /* Isso evita conflitos com:
     *   - BIOS data area (0x0000 - 0x0500)
     *   - Conventional memory (0x0500 - 0x7C00)
     *   - Bootloader (0x7C00 - 0x7DFF)
     *   - Stack (0x7E00 - ~0x9FFFF)
     *   - Video memory (0xA0000 - 0xFFFFF)
     */
    . = 0x100000;

    /* Início do kernel (usado para calcular tamanho) */
    __kernel_start = .;

    /* ==================================================================
     * SEÇÃO .text - CÓDIGO EXECUTÁVEL
     * ================================================================== */
    .text ALIGN(4K) : {
        *(.text)
        *(.text.*)
    }

    /* ==================================================================
     * SEÇÃO .rodata - DADOS SOMENTE LEITURA
     * ================================================================== */
    .rodata ALIGN(4K) : {
        *(.rodata)
        *(.rodata.*)
    }

    /* ==================================================================
     * SEÇÃO .data - DADOS INICIALIZADOS
     * ================================================================== */
    .data ALIGN(4K) : {
        *(.data)
        *(.data.*)
    }

    /* ==================================================================
     * SEÇÃO .bss - DADOS NÃO INICIALIZADOS (ZEROED)
     * ================================================================== */
    .bss ALIGN(4K) : {
        __bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        __bss_end = .;
    }

    /* ==================================================================
     * SEÇÃO .stack - STACK DO KERNEL (16KB, ALIGN(16))
     * ==================================================================
     * Em região mapeada (identity mapping do bootloader). Não colide com
     * .text, .bss ou page tables. stack_top usado em qkern.asm: mov rsp, stack_top
     * ================================================================== */
    .stack ALIGN(16) : {
        stack_bottom = .;
        . += 16K;
        stack_top = .;
    }

    /* Fim do kernel (usado para calcular tamanho) */
    __kernel_end = .;
    __kernel_size = __kernel_end - __kernel_start;

    /* ==================================================================
     * DESCARTE - SEÇÕES NÃO NECESSÁRIAS
     * ================================================================== */
    /DISCARD/ : {
        *(.comment)
        *(.eh_frame)
        *(.note*)
    }
}
