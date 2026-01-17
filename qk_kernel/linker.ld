ENTRY(qk_entrada)

SECTIONS
{
    /* O kernel será carregado em 1MB pelo bootloader */
    . = 0x100000;

    .text :
    {
        *(.text)
    }

    .rodata :
    {
        *(.rodata)
    }

    .data :
    {
        *(.data)
    }

    .bss :
    {
        *(.bss)
    }
}
