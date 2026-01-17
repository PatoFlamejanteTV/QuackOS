/* QKern - Núcleo do QuackOS */

#include <stdint.h>

void qk_imprimir(const char *str);

void qk_main() {
    // Limpa a tela (modo texto VGA 80x25)
    volatile uint16_t *vga = (volatile uint16_t *)0xB8000;
    for (int i = 0; i < 80 * 25; i++) {
        vga[i] = (0x07 << 8) | ' ';
    }

    qk_imprimir("QuackOS: QKern ativo e operante!");
    qk_imprimir("\nOla, mundo 64 bits!");

    while (1) {
        __asm__ volatile("hlt");
    }
}

void qk_imprimir(const char *str) {
    static int x = 0;
    static int y = 0;
    volatile uint16_t *vga = (volatile uint16_t *)0xB8000;

    for (int i = 0; str[i] != '\0'; i++) {
        if (str[i] == '\n') {
            x = 0;
            y++;
        } else {
            vga[y * 80 + x] = (0x0F << 8) | str[i];
            x++;
            if (x >= 80) {
                x = 0;
                y++;
            }
        }

        // Rolagem simples se chegar ao fim da tela
        if (y >= 25) {
            for (int r = 0; r < 24 * 80; r++) {
                vga[r] = vga[r + 80];
            }
            for (int c = 0; c < 80; c++) {
                vga[24 * 80 + c] = (0x07 << 8) | ' ';
            }
            y = 24;
        }
    }
}
