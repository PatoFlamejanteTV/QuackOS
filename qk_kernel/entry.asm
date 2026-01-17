; Ponto de entrada do QKern - QuackOS
; Localizado em 0x100000

[bits 64]
[extern qk_main]

global qk_entrada
qk_entrada:
    ; Configura stack básica (opcional se o bootloader já fez, mas bom garantir)
    mov rsp, 0x90000 ; Stack cresce para baixo a partir de 0x90000

    ; Chama o kernel em C
    call qk_main

    ; Se o kernel retornar, entra em loop infinito
.fim:
    hlt
    jmp .fim
