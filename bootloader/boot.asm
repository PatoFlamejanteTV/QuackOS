; ==============================================================================
; QuackOS - MBR Bootloader (Stage 1)
; ==============================================================================
; Arquivo: boot.asm
; Tamanho: 512 bytes (obrigatório para MBR)
; Modo: Real Mode (16 bits)
; Carregado em: 0x7C00 pela BIOS
;
; Responsabilidades:
;   1. Configurar stack e segment registers
;   2. Limpar interrupções críticas
;   3. Carregar Stage 2 do disco
;   4. Transferir controle ao Stage 2
;
; Filosofia: Sem filesystem complexo. Leitura direta de LBAs.
; ==============================================================================

[BITS 16]           ; Código 16 bits (real mode)
[ORG 0x7C00]        ; BIOS carrega MBR em 0x7C00

; ==============================================================================
; PONTO DE ENTRADA
; ==============================================================================

inicio:
    ; --- Desabilitar interrupções durante inicialização ---
    cli

    ; --- Configurar segment registers ---
    ; CS já está correto (BIOS configura)
    ; Zeramos DS, ES, SS para garantir endereçamento linear
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax

    ; --- Salvar o drive de boot passado pela BIOS em DL ---
    ; Agora que DS está zerado, podemos salvar em [drive] com segurança
    mov [drive], dl
    
    ; --- Configurar stack ---
    ; Stack cresce para baixo a partir de 0x7C00
    ; Isso nos dá ~30KB para a stack (0x0000 a 0x7C00)
    mov sp, 0x7C00
    
    ; --- Reabilitar interrupções ---
    sti

    ; --- Limpar tela e exibir mensagem inicial ---
    call limpar_tela
    mov si, msg_boot
    call print_string

    ; --- Carregar Stage 2 do disco ---
    ; Stage 2 começa no setor 1 (LBA 1)
    ; Vamos carregar 16 setores (8KB) para 0x7E00
    ; Isso dá espaço suficiente para o loader
    
    mov si, msg_carregando
    call print_string
    
    ; Configurar leitura do disco
    mov ah, 0x42        ; INT 13h Extended Read
    mov dl, [drive]     ; Drive de boot (salvo pela BIOS)
    mov si, dap         ; Disk Address Packet
    int 0x13
    
    jc erro_disco       ; Se carry flag set, erro
    
    ; --- Verificar assinatura do Stage 2 ---
    ; Primeiros 4 bytes devem ser "QOS2"
    mov eax, [0x7E00]
    cmp eax, 0x32534F51 ; "QOS2" em little-endian
    jne erro_stage2
    
    ; --- Transferir controle ao Stage 2 ---
    mov si, msg_sucesso
    call print_string
    
    ; Passar informações ao Stage 2
    mov dl, [drive]     ; DL = drive de boot
    jmp 0x0000:0x7E04   ; Saltar para Stage 2 (pular assinatura "QOS2")

; ==============================================================================
; TRATAMENTO DE ERROS
; ==============================================================================

erro_disco:
    mov si, msg_erro_disco
    call print_string
    jmp halt

erro_stage2:
    mov si, msg_erro_stage2
    call print_string
    jmp halt

halt:
    hlt
    jmp halt

; ==============================================================================
; FUNÇÕES AUXILIARES
; ==============================================================================

; --- Limpar tela ---
limpar_tela:
    push ax
    mov ah, 0x00        ; Função: Set video mode
    mov al, 0x03        ; Modo texto 80x25
    int 0x10
    pop ax
    ret

; --- Imprimir string (terminada em 0) ---
; Entrada: SI = ponteiro para string
print_string:
    push ax
    push bx
    
.loop:
    lodsb               ; Carregar byte de [SI] em AL e incrementar SI
    test al, al         ; Verificar se é 0 (fim da string)
    jz .fim
    
    mov ah, 0x0E        ; Função: Teletype output
    mov bh, 0           ; Página 0
    mov bl, 0x07        ; Cor: cinza claro
    int 0x10
    
    jmp .loop
    
.fim:
    pop bx
    pop ax
    ret

; ==============================================================================
; DADOS
; ==============================================================================

; Drive de boot (preenchido pela BIOS em DL)
drive: db 0x80          ; 0x80 = primeiro HD

; Disk Address Packet (DAP) para INT 13h Extended Read
dap:
    db 0x10             ; Tamanho do DAP (16 bytes)
    db 0                ; Sempre 0
    dw 16               ; Número de setores a ler (16 setores = 8KB)
    dw 0x7E00           ; Offset: carregar em 0x7E00
    dw 0x0000           ; Segment: 0x0000
    dd 1                ; LBA low: setor 1 (após MBR)
    dd 0                ; LBA high: 0

; Mensagens
msg_boot:       db 'QuackOS Boot v1.0', 13, 10, 0
msg_carregando: db 'Carregando Stage 2...', 13, 10, 0
msg_sucesso:    db 'Stage 2 OK. Transferindo...', 13, 10, 0
msg_erro_disco: db 'ERRO: Falha ao ler disco', 13, 10, 0
msg_erro_stage2:db 'ERRO: Stage 2 invalido', 13, 10, 0

; ==============================================================================
; PADDING E ASSINATURA MBR
; ==============================================================================

; Preencher até byte 510 com zeros
times 510-($-$$) db 0

; Assinatura MBR obrigatória (bytes 511-512)
dw 0xAA55           ; Little-endian: 0x55AA
