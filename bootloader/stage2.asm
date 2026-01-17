; ==============================================================================
; QuackOS - Stage 2 Bootloader
; ==============================================================================
; Arquivo: stage2.asm
; Modo inicial: Real Mode (16 bits)
; Modo final: Long Mode (64 bits)
; Carregado em: 0x7E00 pelo MBR
;
; Responsabilidades:
;   1. Detectar mapa de memória (INT 0x15, E820)
;   2. Habilitar linha A20
;   3. Configurar modo gráfico básico (VESA)
;   4. Carregar kernel (qkern.bin) para 0x100000
;   5. Preparar GDT para protected mode
;   6. Entrar em protected mode (32 bits)
;   7. Configurar paginação de 4 níveis
;   8. Entrar em long mode (64 bits)
;   9. Transferir controle ao kernel
;
; Pipeline: Real Mode → Protected Mode → Long Mode → Kernel
; ==============================================================================

[BITS 16]
[ORG 0x7E00]

; ==============================================================================
; ASSINATURA E PONTO DE ENTRADA
; ==============================================================================

; Assinatura "QOS2" para validação pelo MBR
dd 0x32534F51

inicio_stage2:
    ; DL contém o drive de boot (passado pelo MBR)
    mov [boot_drive], dl
    
    ; --- Exibir mensagem ---
    mov si, msg_stage2
    call print

    ; ==============================================================================
    ; ETAPA 1: DETECTAR MAPA DE MEMÓRIA (E820)
    ; ==============================================================================
    
    mov si, msg_mem
    call print
    call detectar_memoria
    
    ; ==============================================================================
    ; ETAPA 2: HABILITAR LINHA A20
    ; ==============================================================================
    
    mov si, msg_a20
    call print
    call habilitar_a20
    
    ; ==============================================================================
    ; ETAPA 3: CONFIGURAR MODO GRÁFICO (VESA - opcional)
    ; ==============================================================================
    
    ; Por enquanto, pularemos o modo gráfico no bootloader
    ; O kernel inicializará o framebuffer diretamente
    
    ; ==============================================================================
    ; ETAPA 4: CARREGAR KERNEL
    ; ==============================================================================
    
    mov si, msg_kernel
    call print
    call carregar_kernel
    
    ; ==============================================================================
    ; ETAPA 5: ENTRAR EM PROTECTED MODE
    ; ==============================================================================
    
    mov si, msg_pmode
    call print
    
    cli                     ; Desabilitar interrupções
    lgdt [gdt_descriptor]   ; Carregar GDT
    
    ; Ativar bit PE (Protection Enable) no CR0
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    ; Far jump para limpar pipeline e entrar em protected mode
    jmp 0x08:protected_mode_inicio

; ==============================================================================
; CÓDIGO EM PROTECTED MODE (32 bits)
; ==============================================================================

[BITS 32]
protected_mode_inicio:
    ; --- Configurar segment registers para protected mode ---
    mov ax, 0x10        ; Data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000    ; Stack em 576KB
    
    ; --- Configurar paginação para long mode ---
    call configurar_paginacao
    
    ; --- Entrar em long mode ---
    call entrar_long_mode
    
    ; Não deveria chegar aqui
    jmp $

; ==============================================================================
; FUNÇÕES - REAL MODE (16 bits)
; ==============================================================================

[BITS 16]

; --- Detectar memória usando INT 0x15, EAX=0xE820 ---
detectar_memoria:
    push bp
    mov bp, sp
    
    xor ebx, ebx            ; EBX = 0 na primeira chamada
    mov di, mmap_entries    ; Destino das entradas
    xor si, si              ; Contador de entradas
    
.loop:
    mov eax, 0xE820         ; Função E820
    mov ecx, 24             ; Tamanho do buffer
    mov edx, 0x534D4150     ; Assinatura "SMAP"
    int 0x15
    
    jc .fim                 ; Se carry, acabaram as entradas
    
    cmp eax, 0x534D4150     ; Verificar se BIOS suporta
    jne .erro
    
    ; Entrada válida
    add di, 24              ; Próxima entrada
    inc si                  ; Incrementar contador
    
    test ebx, ebx           ; EBX = 0 significa última entrada
    jz .fim
    
    cmp si, 32              ; Máximo de 32 entradas
    jge .fim
    
    jmp .loop
    
.fim:
    mov [mmap_count], si
    pop bp
    ret
    
.erro:
    mov si, msg_erro_mem
    call print
    jmp halt_real

; --- Habilitar linha A20 (método rápido) ---
habilitar_a20:
    push ax
    
    ; Método 1: BIOS
    mov ax, 0x2401
    int 0x15
    jnc .verificar
    
    ; Método 2: Teclado controller
    call wait_8042
    mov al, 0xAD
    out 0x64, al        ; Desabilitar teclado
    
    call wait_8042
    mov al, 0xD0
    out 0x64, al        ; Ler output port
    
    call wait_8042_data
    in al, 0x60
    push ax
    
    call wait_8042
    mov al, 0xD1
    out 0x64, al        ; Escrever output port
    
    call wait_8042
    pop ax
    or al, 2            ; Habilitar A20
    out 0x60, al
    
    call wait_8042
    mov al, 0xAE
    out 0x64, al        ; Reabilitar teclado
    
    call wait_8042
    
.verificar:
    ; Verificar se A20 está habilitado
    call verificar_a20
    test ax, ax
    jnz .ok
    
    ; Método 3: Fast A20
    in al, 0x92
    or al, 2
    out 0x92, al
    
.ok:
    pop ax
    ret

wait_8042:
    in al, 0x64
    test al, 2
    jnz wait_8042
    ret

wait_8042_data:
    in al, 0x64
    test al, 1
    jz wait_8042_data
    ret

verificar_a20:
    push ds
    push es
    push di
    push si
    
    xor ax, ax
    mov ds, ax
    mov si, 0x7DFE
    
    mov ax, 0xFFFF
    mov es, ax
    mov di, 0x7E0E
    
    mov al, [ds:si]
    mov byte [es:di], 0x00
    mov bl, [ds:si]
    
    mov byte [es:di], 0xFF
    mov cl, [ds:si]
    
    mov byte [es:di], al
    
    xor ax, ax
    cmp bl, cl
    jz .fim
    mov ax, 1
    
.fim:
    pop si
    pop di
    pop es
    pop ds
    ret

; --- Carregar kernel do disco ---
carregar_kernel:
    push bp
    mov bp, sp
    
    ; Carregar 64 setores (32KB) do kernel
    ; Stage 2 ocupa 16 setores (LBA 1-16)
    ; Kernel começa em LBA 17
    
    mov ax, 0x1000          ; Segment 0x1000 (0x10000 físico)
    mov es, ax
    xor bx, bx              ; Offset 0
    
    mov al, 64              ; 64 setores
    mov dl, [boot_drive]    ; Drive
    mov ch, 0               ; Cilindro 0
    mov cl, 18              ; Setor 18 (LBA 17, +1)
    mov dh, 0               ; Cabeça 0
    
    mov ah, 0x02            ; Função: Read Sectors
    int 0x13
    
    jc .erro
    
    pop bp
    ret
    
.erro:
    mov si, msg_erro_kernel
    call print
    jmp halt_real

; --- Imprimir string (real mode) ---
print:
    push ax
    push si
    
.loop:
    lodsb
    test al, al
    jz .fim
    
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    jmp .loop
    
.fim:
    pop si
    pop ax
    ret

halt_real:
    cli
    hlt
    jmp halt_real

; ==============================================================================
; FUNÇÕES - PROTECTED MODE (32 bits)
; ==============================================================================

[BITS 32]

; --- Configurar paginação de 4 níveis para long mode ---
configurar_paginacao:
    ; Zerar tabelas de página
    mov edi, 0x1000     ; PML4 em 0x1000
    mov ecx, 0x1000     ; 4096 bytes (4 páginas)
    xor eax, eax
    rep stosd
    
    ; PML4[0] -> PDP (0x2000)
    mov dword [0x1000], 0x2003  ; Present, R/W
    
    ; PDP[0] -> PD (0x3000)
    mov dword [0x2000], 0x3003
    
    ; PD[0] -> PT (0x4000)
    mov dword [0x3000], 0x4003
    
    ; PT: mapear primeiros 2MB com páginas de 4KB
    mov edi, 0x4000
    mov eax, 0x0003     ; Present, R/W
    mov ecx, 512        ; 512 entradas
    
.loop_pt:
    stosd
    add eax, 0x1000     ; Próxima página (4KB)
    loop .loop_pt
    
    ; Carregar CR3 com endereço do PML4
    mov eax, 0x1000
    mov cr3, eax
    
    ret

; --- Entrar em long mode ---
entrar_long_mode:
    ; Habilitar PAE (Physical Address Extension)
    mov eax, cr4
    or eax, (1 << 5)    ; CR4.PAE
    mov cr4, eax
    
    ; Habilitar Long Mode (EFER.LME)
    mov ecx, 0xC0000080 ; EFER MSR
    rdmsr
    or eax, (1 << 8)    ; EFER.LME
    wrmsr
    
    ; Habilitar paginação (CR0.PG)
    mov eax, cr0
    or eax, (1 << 31)   ; CR0.PG
    mov cr0, eax
    
    ; Far jump para código 64 bits
    jmp 0x08:long_mode_inicio

; ==============================================================================
; CÓDIGO EM LONG MODE (64 bits)
; ==============================================================================

[BITS 64]
long_mode_inicio:
    ; --- Configurar segment registers ---
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; --- Preparar boot_info para o kernel ---
    mov rdi, boot_info_struct
    
    ; Preencher boot_info
    mov rax, [mmap_total]
    mov [rdi], rax          ; mem_total
    
    mov rax, [mmap_livre]
    mov [rdi + 8], rax      ; mem_livre
    
    xor rax, rax
    mov [rdi + 16], rax     ; framebuffer (NULL por enquanto)
    mov [rdi + 24], rax     ; fb_largura (0)
    mov [rdi + 28], rax     ; fb_altura (0)
    mov [rdi + 32], rax     ; fb_bpp (0)
    
    ; --- Transferir controle ao kernel ---
    ; Kernel carregado em 0x100000
    mov rax, 0x100000
    call rax
    
    ; Se kernel retornar, halt
    cli
    hlt
    jmp $

; ==============================================================================
; GDT (Global Descriptor Table)
; ==============================================================================

[BITS 16]

gdt_inicio:
    ; Entrada nula (obrigatória)
    dq 0
    
    ; Code segment (0x08)
    dw 0xFFFF       ; Limite 0-15
    dw 0x0000       ; Base 0-15
    db 0x00         ; Base 16-23
    db 10011010b    ; Flags: Present, Ring 0, Code, Executable, Readable
    db 11001111b    ; Flags: Granularity, 32-bit, Limite 16-19
    db 0x00         ; Base 24-31
    
    ; Data segment (0x10)
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b    ; Flags: Present, Ring 0, Data, Writable
    db 11001111b
    db 0x00

gdt_fim:

gdt_descriptor:
    dw gdt_fim - gdt_inicio - 1  ; Tamanho
    dd gdt_inicio                 ; Endereço

; ==============================================================================
; DADOS
; ==============================================================================

boot_drive:     db 0
mmap_count:     dw 0
mmap_total:     dq 0
mmap_livre:     dq 0

; Buffer para entradas E820 (32 entradas de 24 bytes)
mmap_entries:   times 768 db 0

; Estrutura boot_info que será passada ao kernel
boot_info_struct:
    dq 0            ; mem_total
    dq 0            ; mem_livre
    dq 0            ; framebuffer
    dd 0            ; fb_largura
    dd 0            ; fb_altura
    dd 0            ; fb_bpp

; Mensagens
msg_stage2:         db 'Stage 2 iniciado', 13, 10, 0
msg_mem:            db 'Detectando memoria...', 13, 10, 0
msg_a20:            db 'Habilitando A20...', 13, 10, 0
msg_kernel:         db 'Carregando kernel...', 13, 10, 0
msg_pmode:          db 'Entrando em protected mode...', 13, 10, 0
msg_erro_mem:       db 'ERRO: Falha ao detectar memoria', 13, 10, 0
msg_erro_kernel:    db 'ERRO: Falha ao carregar kernel', 13, 10, 0

; ==============================================================================
; PADDING
; ==============================================================================

; Preencher até 8KB (16 setores)
times 8192-($-$$) db 0
