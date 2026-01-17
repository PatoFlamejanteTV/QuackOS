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
; ==============================================================================

[BITS 64]                   ; Código 64 bits (long mode)

; ==============================================================================
; SEÇÃO .text - CÓDIGO
; ==============================================================================

section .text
global qkern_inicio         ; Entry point exportado para o linker

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
    ; RDI já contém o ponteiro para boot_info
    ; Vamos armazená-lo em uma variável global para uso futuro
    mov [boot_info_ptr], rdi

    ; --- Configurar stack própria ---
    ; Vamos usar uma stack de 16KB definida no BSS
    ; A stack cresce para baixo, então apontamos RSP para o final
    lea rsp, [kernel_stack_top]
    
    ; Zerar RBP para marcar o início da stack (útil para debugging)
    xor rbp, rbp

    ; --- Escrever mensagem em VGA ---
    ; VGA text mode buffer está em 0xB8000 (physical)
    ; Cada caractere ocupa 2 bytes: [ASCII][Atributo]
    ; Atributo: 0x0F = fundo preto, texto branco brilhante
    
    call vga_escrever_mensagem

    ; --- Loop infinito com HLT ---
    ; HLT pausa o CPU até a próxima interrupção
    ; Como interrupções estão desabilitadas (CLI), o CPU fica parado permanentemente
    ; Isso economiza energia em comparação a um loop vazio
.halt_loop:
    hlt
    jmp .halt_loop              ; Garantir que nunca sai do halt (paranoico)

; ==============================================================================
; FUNÇÃO: Escrever mensagem no VGA
; ==============================================================================
; Escreve "QuackOS kernel alive" no canto superior esquerdo da tela
; ==============================================================================

vga_escrever_mensagem:
    ; Preparar registradores
    mov rdi, 0xB8000            ; RDI = endereço base do VGA buffer
    lea rsi, [mensagem]         ; RSI = ponteiro para a mensagem
    mov ah, 0x0F                ; AH = atributo (fundo preto, texto branco brilhante)

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

; Mensagem a ser exibida (null-terminated)
mensagem: db "QuackOS kernel alive", 0

; ==============================================================================
; SEÇÃO .bss - DADOS NÃO INICIALIZADOS
; ==============================================================================

section .bss

; Ponteiro para struct boot_info (passado pelo bootloader)
boot_info_ptr: resq 1           ; Reservar 1 qword (8 bytes)

; Stack do kernel (16KB)
align 16                        ; Alinhar stack em 16 bytes (exigido pela ABI)
kernel_stack_bottom: resb 16384 ; Reservar 16KB
kernel_stack_top:               ; Topo da stack (stack cresce para baixo)

; ==============================================================================
; SEÇÃO .data - DADOS INICIALIZADOS
; ==============================================================================

section .data

; Informações sobre o kernel (útil para debugging)
kernel_version: db "QKern 0.0.1-Fase0", 0
