/**
 * ===========================================================================
 * QuackOS - Estrutura boot_info
 * ===========================================================================
 * Arquivo: boot_info.h
 * 
 * Define a estrutura de informações passadas do bootloader para o kernel.
 * Esta estrutura é passada em RDI conforme System V AMD64 ABI.
 * 
 * Nota: Este é um header C para documentação. O kernel em assembly
 * acessa os campos através de offsets manuais.
 * ===========================================================================
 */

#ifndef BOOT_INFO_H
#define BOOT_INFO_H

#include <stdint.h>

/**
 * Estrutura de informações de boot
 * Passada do bootloader Stage 2 para o kernel em RDI
 */
typedef struct {
    /* Assinatura mágica para validação (deve ser 0x51574B49 - "QKWI") */
    uint32_t magic;
    
    /* Versão desta estrutura (para compatibilidade futura) */
    uint32_t version;
    
    /* Informações de memória */
    uint64_t memory_map_addr;       /* Endereço do memory map (E820) */
    uint32_t memory_map_entries;    /* Número de entradas no memory map */
    uint64_t total_memory;          /* Memória total em bytes */
    
    /* Informações do bootloader */
    uint8_t  boot_drive;            /* Drive de boot (0x80, 0x81, etc) */
    uint8_t  reserved[7];           /* Padding/reservado para futuro */
    
    /* Informações de vídeo (para futuro) */
    uint32_t framebuffer_addr;      /* Endereço do framebuffer (0 = modo texto) */
    uint16_t screen_width;          /* Largura da tela em pixels/colunas */
    uint16_t screen_height;         /* Altura da tela em pixels/linhas */
    uint16_t screen_bpp;            /* Bits por pixel (0 = modo texto) */
    
} __attribute__((packed)) boot_info_t;

/* Constantes */
#define BOOT_INFO_MAGIC   0x51574B49  /* "QKWI" em ASCII */
#define BOOT_INFO_VERSION 1

#endif /* BOOT_INFO_H */
