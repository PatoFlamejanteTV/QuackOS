; Stage 2 Bootloader - QuackOS
; Transição para Modo Protegido e depois Modo Longo (64 bits).

[bits 16]
[org 0x7e00]

stage2_inicio:
    mov si, msg_stage2
    call imprimir_texto_16

    ; Carrega o Kernel (QKern)
    ; O Kernel começa no setor 6 (setor 1 MBR, setores 2-5 Stage 2)
    ; Vamos carregar 64 setores por enquanto (32KB)
    mov ah, 0x02
    mov al, 64
    mov ch, 0
    mov dh, 0
    mov cl, 6
    mov bx, 0x1000  ; Carrega temporariamente em 0x1000:0000 (0x10000)
    mov es, bx
    xor bx, bx
    int 0x13
    jc erro_leitura_kernel

    ; Transição para Modo Protegido (32 bits)
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:stage2_32bits

[bits 32]
stage2_32bits:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Move o kernel para 0x100000 (1MB) - local final esperado pelo linker
    mov esi, 0x10000
    mov edi, 0x100000
    mov ecx, 64 * 512 / 4
    rep movsd

    ; Configura Paginação para Modo Longo
    ; PML4 em 0x1000, PDPT em 0x2000, PDT em 0x3000
    mov edi, 0x1000
    mov cr3, edi
    xor eax, eax
    mov ecx, 4096
    rep stosd
    mov edi, cr3

    ; PML4[0] -> PDPT
    mov dword [edi], 0x2003
    mov dword [edi + 4], 0
    ; PDPT[0] -> PDT
    mov dword [edi + 0x1000], 0x3003
    mov dword [edi + 0x1004], 0
    ; PDT[0] -> 2MB page (identidade)
    mov dword [edi + 0x2000], 0x00000083
    mov dword [edi + 0x2004], 0

    ; Ativa PAE
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Ativa Long Mode no EFER MSR
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; Ativa Paginação
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ; Carrega GDT de 64 bits e pula para o Kernel
    lgdt [gdt64_descriptor]
    jmp 0x08:stage2_64bits

[bits 64]
stage2_64bits:
    ; Pula para o ponto de entrada do Kernel em 0x100000
    mov rax, 0x100000
    jmp rax

[bits 16]
erro_leitura_kernel:
    mov si, msg_erro_kernel
    call imprimir_texto_16
    jmp $

imprimir_texto_16:
    lodsb
    or al, al
    jz .fim
    mov ah, 0x0e
    int 0x10
    jmp imprimir_texto_16
.fim:
    ret

msg_stage2 db "QuackOS: Stage 2 ativo. Entrando em Modo Longo...", 13, 10, 0
msg_erro_kernel db "Erro ao carregar QKern!", 0

; GDT para Modo Protegido (32 bits)
gdt_inicio:
    dq 0 ; Nulo
    dq 0x00cf9a000000ffff ; Código
    dq 0x00cf92000000ffff ; Dados
gdt_fim:

gdt_descriptor:
    dw gdt_fim - gdt_inicio - 1
    dd gdt_inicio

; GDT para Modo Longo (64 bits)
gdt64_inicio:
    dq 0 ; Nulo
    dq 0x00af9a000000ffff ; Código 64 bits
    dq 0x00af92000000ffff ; Dados 64 bits
gdt64_fim:

gdt64_descriptor:
    dw gdt64_fim - gdt64_inicio - 1
    dq gdt64_inicio

; Padding para garantir que o Stage 2 ocupe exatamente 4 setores (2048 bytes)
times 2048-($-$$) db 0
