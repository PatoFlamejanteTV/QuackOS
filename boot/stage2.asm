; Stage 2 Bootloader - QuackOS
; Transição para Modo Protegido e depois Modo Longo (64 bits).

[bits 16]
[org 0x7e00]

stage2_inicio:
    mov si, msg_stage2
    call imprimir_texto_16

    ; Habilita A20
    call habilitar_a20

    ; Carrega o Kernel (QKern)
    ; O Kernel começa no setor 6 (setor 1 MBR, setores 2-5 Stage 2)
    ; Vamos carregar 64 setores por enquanto (32KB)
    mov ax, 0x1000
    mov es, ax
    xor bx, bx
    mov cl, 6       ; Setor inicial
    mov al, 64      ; Total de setores
.loop_leitura:
    push ax
    mov ah, 0x02
    mov al, 1       ; Lê um setor por vez para simplicidade e robustez
    mov ch, 0
    mov dh, 0
    ; cl já tem o setor
    mov dl, [boot_drive]
    int 0x13
    jc erro_leitura_kernel

    pop ax
    dec al
    jz .fim_leitura

    ; Próximo destino
    add bx, 512
    jnz .sem_carry_segmento
    mov dx, es
    add dx, 0x1000
    mov es, dx
.sem_carry_segmento:
    inc cl          ; Próximo setor (simplificado: assume que cabe no cilindro)
    jmp .loop_leitura

.fim_leitura:
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

    ; Verifica A20 antes de mover o kernel
    call verificar_a20
    or al, al
    jz erro_a20

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

erro_a20:
    mov si, msg_erro_a20
    call imprimir_texto_16
    jmp $

habilitar_a20:
    ; Fast A20
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

verificar_a20:
    push ds
    push es
    push di
    push si

    xor ax, ax
    mov ds, ax
    not ax
    mov es, ax

    mov di, 0x0500
    mov si, 0x0510

    mov al, [ds:di]
    push ax
    mov al, [es:si]
    push ax

    mov byte [ds:di], 0x00
    mov byte [es:si], 0xFF

    cmp byte [ds:di], 0xFF

    pop ax
    mov [es:si], al
    pop ax
    mov [ds:di], al

    mov ax, 0
    je .fim
    mov ax, 1

.fim:
    pop si
    pop di
    pop es
    pop ds
    ret

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
msg_erro_a20 db "Erro: A20 desabilitado!", 0
boot_drive equ 0x7dfd ; Endereço onde stage1 salvou o drive (relativo ao org 0x7c00 e db no fim)

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
