; Stage 1 Bootloader - QuackOS
; MBR localizado no setor 0 do disco.
; Carrega o Stage 2 do disco para a memória e pula para ele.

[bits 16]
[org 0x7c00]

inicio:
    ; Configura registradores de segmento
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; Mensagem de boas vindas
    mov si, msg_carregando
    call imprimir_texto

    ; Carrega o Stage 2 (começa no setor 1)
    ; Vamos carregar 4 setores por enquanto (o Stage 2 pode crescer)
    mov ah, 0x02    ; Função de leitura da BIOS
    mov al, 4       ; Número de setores para ler
    mov ch, 0       ; Cilindro 0
    mov dh, 0       ; Cabeça 0
    mov cl, 2       ; Setor 2 (setores BIOS começam em 1, MBR é 1)
    mov bx, 0x7e00  ; Destino: logo após o MBR
    int 0x13
    jc erro_leitura

    ; Pula para o Stage 2
    jmp 0x0000:0x7e00

erro_leitura:
    mov si, msg_erro
    call imprimir_texto
    jmp $

imprimir_texto:
    lodsb
    or al, al
    jz .fim
    mov ah, 0x0e
    int 0x10
    jmp imprimir_texto
.fim:
    ret

msg_carregando db "QuackOS: Carregando Stage 2...", 13, 10, 0
msg_erro       db "Erro ao carregar Stage 2!", 0

times 510-($-$$) db 0
dw 0xaa55
