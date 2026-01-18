; ==============================================================================
; QuackOS - QKern Fase 0.5 (IDT Mínima)
; ==============================================================================
; Arquivo: qkern.asm
; Formato: ELF64
; Modo: Long Mode (64 bits)
;
; Responsabilidades:
;   1. Receber struct boot_info* em RDI (convenção System V AMD64 ABI)
;   2. Configurar stack própria e IDT
;   3. Escrever "QuackOS kernel alive" em VGA 0xB8000
;   4. Entrar em loop infinito com HLT
;
; Fase 0.5 - IDT mínima:
;   - 256 entradas; stub por vetor (push N; jmp common). #8 → df_handler (stack própria)
;   - common_exception_handler: "EXCEPTION: #XX" em VGA linha 2; cli; hlt
;   - Double fault (#8): df_stack dedicada, "EXCEPTION: #DF", sem usar stack do CPU
;   - int3 (#BP) e div0 (#DE) capturados; exceções tornam o kernel observável
;
; Ainda não (Fase 1): GDT definitiva, STI, timer, transição ASM→C
;
; ------------------------------------------------------------------------------
; Pré-requisitos (garantidos pelo bootloader):
;   - Identity mapping ativo para memória baixa (VGA 0xB8000, stack, page tables)
; ------------------------------------------------------------------------------
; Testar IDT: int3  (breakpoint) ou  xor eax,eax; div eax  (divide by zero)
; ==============================================================================

[BITS 64]                   ; Código 64 bits (long mode)

; ==============================================================================
; SEÇÃO .text - CÓDIGO
; ==============================================================================

section .text.header
global qkern_header
extern __kernel_sector_count

; ==============================================================================
; KERNEL HEADER (32 bytes - alinhado a setor para facilitar)
; ------------------------------------------------------------------------------
; ABI de Boot do QuackOS (Offsets Fixos):
;   0x00: jmp qkern_inicio (Instrução de salto para o entrypoint)
;   0x04: Magic number 'QKRN' (0x4E524B51 em little-endian)
;   0x08: Kernel sector count (4 bytes, sectors including header)
;   0x0C: Reservado (Futuras flags ou entrypoints)
; ==============================================================================
qkern_header:
    jmp short qkern_inicio  ; Saltar para o início real do código (2 bytes)
    align 4                 ; (2 bytes padding)
    db 'QKRN'               ; Magic number (4 bytes) - Offset 0x04
    dd __kernel_sector_count ; Tamanho em setores (4 bytes) - Offset 0x08
    dq 0                    ; Reservado (8 bytes)
    dq 0                    ; Reservado (8 bytes)
    dq 0                    ; Reservado (8 bytes)

section .text
global qkern_inicio         ; Entry point exportado para o linker
EXTERN stack_top            ; Definido em linker.ld (.stack); 16KB, ALIGN(16)

; ==============================================================================
; ENTRY POINT DO KERNEL
; ==============================================================================
; Convenção de chamada: System V AMD64 ABI
; RDI = ponteiro para struct boot_info (passado pelo bootloader)
; ==============================================================================

qkern_inicio:
    ; --- Desabilitar interrupções ---
    ; Não temos IDT configurada ainda, então interrupções causariam triple fault
    cli

    ; --- Configurar stack temporária para inicialização ---
    mov rsp, stack_top
    xor rbp, rbp

    ; --- Salvar boot_info ---
    mov [boot_info_ptr], rdi

    ; --- Configurar GDT e TSS ---
    call gdt_configurar
    call tss_configurar

    ; --- Carregar GDT ---
    lgdt [gdt_descriptor]

    ; --- Reload de CS (far jump) ---
    push 0x08                       ; Seletor de Kernel Code
    lea rax, [rel .reload_cs]
    push rax
    retfq

.reload_cs:
    ; --- Carregar seletores de dados ---
    mov ax, 0x10                    ; Seletor de Kernel Data
    mov ds, ax
    mov ss, ax

    ; --- Carregar TSS ---
    mov ax, 0x28                    ; Seletor de TSS
    ltr ax

    ; --- Configurar e carregar IDT ---
    call idt_configurar
    lidt [idt_descriptor]

    ; --- Validar boot_info (ABI: RDI, layout do stage2) ---
    ; boot_info.mem_total em [rdi+0]; se 0, bootloader não preencheu
    test rdi, rdi
    jz .boot_info_invalido
    cmp qword [rdi + 0], 0
    jz .boot_info_invalido

    ; --- Escrever mensagem em VGA ---
    lea rsi, [mensagem]
    call vga_escrever_mensagem
    ; int3                      ; descomente para testar IDT: deve mostrar "EXCEPTION: #03" na linha 2
    ; xor eax,eax; div eax      ; ou: div0 → "EXCEPTION: #00"
    jmp .halt_loop

.boot_info_invalido:
    lea rsi, [mensagem_boot_info_invalido]
    call vga_escrever_mensagem

    ; --- Loop infinito com HLT ---
    ; HLT pausa o CPU até a próxima interrupção
    ; Como interrupções estão desabilitadas (CLI), o CPU fica parado permanentemente
    ; Isso economiza energia em comparação a um loop vazio
.halt_loop:
    hlt
    jmp .halt_loop              ; Garantir que nunca sai do halt (paranoico)

; ==============================================================================
; FUNÇÃO: vga_escrever_mensagem
; ==============================================================================
; Entrada: RSI = ponteiro para string null-terminated
; Escreve no canto superior esquerdo da tela (0xB8000).
; ==============================================================================

vga_escrever_mensagem:
    mov rdi, 0xB8000            ; RDI = endereço base do VGA buffer
    mov ah, 0x0F                ; AH = atributo (fundo preto, texto branco brilhante)
    ; RSI já contém o ponteiro para a string (passado pelo caller)

.loop:
    lodsb                       ; Carregar próximo byte de [RSI] em AL, incrementar RSI
    test al, al                 ; Verificar se é 0 (fim da string)
    jz .fim                     ; Se zero, terminar

    ; Escrever caractere + atributo no VGA
    mov [rdi], al               ; Escrever ASCII
    mov [rdi + 1], ah           ; Escrever atributo
    add rdi, 2                  ; Avançar para próxima posição (2 bytes por char)
    
    jmp .loop

.fim:
    ret

; ==============================================================================
; idt_configurar: preenche IDT a partir de isr_stub_table (runtime; NASM não
; permite &/>> em símbolos). 64-bit interrupt gate: sel 0x08, type 0x8E.
; ==============================================================================
idt_configurar:
    xor ecx, ecx
    mov rdi, idt
    lea rsi, [isr_stub_table]
.idt_loop:
    mov rax, [rsi + rcx*8]       ; endereço do stub
    mov [rdi], ax                ; offset 0-15
    mov word [rdi + 2], 0x08     ; selector

    ; Configurar IST1 para Double Fault (vetor 8)
    mov byte [rdi + 4], 0        ; IST default
    cmp ecx, 8                   ; Se for #DF
    jne .not_df
    mov byte [rdi + 4], 1        ; Usar IST1
.not_df:

    mov byte [rdi + 5], 0x8E     ; P=1, DPL=0, 64-bit int gate=0xE
    shr rax, 16
    mov [rdi + 6], ax            ; offset 16-31
    mov rax, [rsi + rcx*8]       ; recarregar para 32-63
    shr rax, 32
    mov [rdi + 8], eax           ; offset 32-63
    mov dword [rdi + 12], 0      ; reserved
    add rdi, 16
    inc ecx
    cmp ecx, 256
    jb .idt_loop
    ret

; ==============================================================================
; gdt_configurar: preenche o descritor de TSS na GDT (runtime)
; ==============================================================================
gdt_configurar:
    mov rax, tss
    mov word [gdt + 0x28 + 2], ax   ; Base bits 0-15
    shr rax, 16
    mov byte [gdt + 0x28 + 4], al   ; Base bits 16-23
    mov byte [gdt + 0x28 + 7], ah   ; Base bits 24-31
    shr rax, 16
    mov dword [gdt + 0x28 + 8], eax ; Base bits 32-63

    mov word [gdt + 0x28 + 0], 103  ; Limite (104 bytes - 1)
    mov byte [gdt + 0x28 + 5], 0x89 ; P=1, DPL=0, Type=64-bit TSS (Available)
    ret

; ==============================================================================
; tss_configurar: inicializa RSP0 e IST1 no TSS
; ==============================================================================
tss_configurar:
    mov rax, stack_top
    mov [tss + 4], rax              ; RSP0

    mov rax, ist1_stack_top
    mov [tss + 36], rax             ; IST1
    ret

; ==============================================================================
; IDT - STUBS (256 vetores) e HANDLERS
; ==============================================================================
; Cada stub: push <vec>; jmp common. Vetor 8 (#DF): jmp df_handler_direct
; (stack do CPU pode estar corrompida em #DF; df_handler usa df_stack)
; ==============================================================================

%assign vec 0
%rep 256
isr_stub_ %+ vec:
  %if vec == 8
    jmp df_handler_direct
  %else
    push strict dword vec
    jmp common_exception_handler
  %endif
  %assign vec vec+1
%endrep

; --- Handler comum: [RSP] = vector (push do stub). Escreve "EXCEPTION: #XX" em VGA linha 2 ---
common_exception_handler:
    pop r15                     ; vetor 0-255
    mov rdi, 0xB8000 + 160      ; linha 2 (80*2 bytes)
    mov ah, 0x0F
    lea rsi, [excepcion_prefix]
.prefix:
    lodsb
    test al, al
    jz .hex
    mov [rdi], al
    mov [rdi + 1], ah
    add rdi, 2
    jmp .prefix
.hex:
    mov cl, r15b
    shr cl, 4
    mov al, cl
    call nibble_to_ascii
    mov [rdi], al
    mov [rdi + 1], ah
    add rdi, 2
    mov cl, r15b
    and cl, 0x0F
    mov al, cl
    call nibble_to_ascii
    mov [rdi], al
    mov [rdi + 1], ah
    cli
    hlt
    jmp $

nibble_to_ascii:                ; AL in 0-15 → ASCII em AL
    cmp al, 10
    jb .d
    add al, 'A' - 10
    ret
.d: add al, '0'
    ret

; --- Double fault: Usa IST1 (stack automática). Escreve "EXCEPTION: #DF" em VGA ---
df_handler_direct:
    ; O RSP já foi trocado automaticamente pelo CPU para ist1_stack_top
    mov rdi, 0xB8000 + 160
    mov ah, 0x0F
    lea rsi, [msg_exception_df]
.df_loop:
    lodsb
    test al, al
    jz .df_halt
    mov [rdi], al
    mov [rdi + 1], ah
    add rdi, 2
    jmp .df_loop
.df_halt:
    cli
    hlt
    jmp .df_halt

; ==============================================================================
; SEÇÃO .rodata - DADOS SOMENTE LEITURA
; ==============================================================================

section .rodata

mensagem: db "QuackOS kernel alive", 0
mensagem_boot_info_invalido: db "boot_info invalido", 0
excepcion_prefix: db "EXCEPTION: #", 0
msg_exception_df: db "EXCEPTION: #DF", 0

; ==============================================================================
; SEÇÃO .bss - DADOS NÃO INICIALIZADOS
; ==============================================================================

section .bss

boot_info_ptr: resq 1

; IDT: 256 entradas × 16 bytes; preenchida em idt_configurar
idt: resb 256 * 16

; TSS (Task State Segment) - 104 bytes para 64-bit
tss: resb 104

; IST1 Stack (Stack de emergência para #DF)
ist1_stack: resb 4096
ist1_stack_top:

; ==============================================================================
; SEÇÃO .data - DADOS INICIALIZADOS
; ==============================================================================

section .data

kernel_version: db "QKern 0.0.1-Fase1A", 0

; --- GDT DEFINITIVA ---
; 0x00: Null
; 0x08: Kernel Code (DPL 0, 64-bit)
; 0x10: Kernel Data (DPL 0)
; 0x18: User Code (DPL 3, 64-bit)
; 0x20: User Data (DPL 3)
; 0x28: TSS (16 bytes, ocupa 2 entradas)
gdt:
    dq 0x0000000000000000 ; Null
    dq 0x00209A0000000000 ; Kernel Code: L=1, P=1, DPL=0, S=1, Type=0xA
    dq 0x0000920000000000 ; Kernel Data: P=1, DPL=0, S=1, Type=0x2
    dq 0x0020FA0000000000 ; User Code: L=1, P=1, DPL=3, S=1, Type=0xA
    dq 0x0000F20000000000 ; User Data: P=1, DPL=3, S=1, Type=0x2
    dq 0x0000000000000000 ; TSS Low (preenchido em gdt_configurar)
    dq 0x0000000000000000 ; TSS High (preenchido em gdt_configurar)

gdt_descriptor:
    dw (7 * 8) - 1        ; Limite: 6 entradas + 1 (TSS ocupa 2)
    dq gdt

; --- Tabela de endereços dos 256 stubs (preenchida em assemble/link; sem &/>> em símbolos) ---
isr_stub_table:
%assign i 0
%rep 256
  dq isr_stub_ %+ i
  %assign i i+1
%endrep

idt_descriptor:
  dw 256 * 16 - 1
  dq idt
