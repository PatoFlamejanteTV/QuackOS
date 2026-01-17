; ==============================================================================
; QuackOS - QKern Fase 0 (Kernel Mínimo)
; ==============================================================================
; Arquivo: qkern.asm
; Formato: ELF64
; Modo: Long Mode (64 bits)
;
; Responsabilidades:
;   1. Receber struct boot_info* em RDI (convenção System V AMD64 ABI)
;   2. Configurar stack própria
;   3. Escrever "QuackOS kernel alive" em VGA 0xB8000
;   4. Entrar em loop infinito com HLT
;
; Não implementado (por design, Fase 0):
;   - Interrupções (IDT)
;   - Heap
;   - Syscalls
;   - Drivers
;   - Multitarefa
;
; ------------------------------------------------------------------------------
; Pré-requisitos (garantidos pelo bootloader na Fase 0):
;   - Identity mapping ativo para memória baixa. O kernel assume que 0xB8000
;     (VGA), a stack e as page tables estão mapeados. Se o identity mapping
;     for removido antes, VGA e stack quebram.
; ------------------------------------------------------------------------------
; CLI permanente na Fase 0: interrupções nunca são reativadas. NMI ainda pode
; ocorrer; HLT nunca retorna; debug com timer inexistente. Fase 1: IDT.
; ==============================================================================

[BITS 64]                   ; Código 64 bits (long mode)

; ==============================================================================
; SEÇÃO .text - CÓDIGO
; ==============================================================================

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

    ; --- Salvar boot_info ---
    mov [boot_info_ptr], rdi

    ; --- Configurar stack própria (linker.ld: .stack ALIGN(16), 16KB) ---
    ; Stack em região mapeada; RSP alinhado antes de qualquer call
    mov rsp, stack_top
    xor rbp, rbp

    ; --- Validar boot_info (ABI: RDI, layout do stage2) ---
    ; boot_info.mem_total em [rdi+0]; se 0, bootloader não preencheu
    test rdi, rdi
    jz .boot_info_invalido
    cmp qword [rdi + 0], 0
    jz .boot_info_invalido

    ; --- Escrever mensagem em VGA ---
    ; VGA em 0xB8000; [ASCII][Atributo]; 0x0F = fundo preto, texto branco
    lea rsi, [mensagem]
    call vga_escrever_mensagem
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
; SEÇÃO .rodata - DADOS SOMENTE LEITURA
; ==============================================================================

section .rodata

; Mensagens (null-terminated)
mensagem: db "QuackOS kernel alive", 0
mensagem_boot_info_invalido: db "boot_info invalido", 0

; ==============================================================================
; SEÇÃO .bss - DADOS NÃO INICIALIZADOS
; ==============================================================================

section .bss

; Ponteiro para struct boot_info (passado pelo bootloader)
boot_info_ptr: resq 1

; Stack: definida em linker.ld (.stack 16KB). Símbolo stack_top.

; ==============================================================================
; SEÇÃO .data - DADOS INICIALIZADOS
; ==============================================================================

section .data

; Informações sobre o kernel (útil para debugging)
kernel_version: db "QKern 0.0.1-Fase0", 0
