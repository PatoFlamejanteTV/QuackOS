# 📖 Explicação Detalhada do Bootloader QuackOS

Este documento explica **cada etapa** do bootloader do QuackOS, linha por linha, com conceitos técnicos claros.

---

## 🎯 Visão Geral

O bootloader do QuackOS é responsável por:

1. Ser carregado pela BIOS
2. Preparar o ambiente de execução
3. Carregar o kernel
4. Transitar de 16 bits → 32 bits → 64 bits
5. Passar controle ao kernel com informações de sistema

**Nenhuma dependência externa.** Tudo feito do zero.

---

## 🏗️ Arquitetura em Dois Estágios

### Por que dois estágios?

**MBR (Stage 1)**: Limitado a 512 bytes pela especificação BIOS.

- Muito pequeno para fazer tudo
- Apenas carrega código maior

**Stage 2**: Sem limite de tamanho (usamos 8KB).

- Pode ter código complexo
- Detecta hardware
- Configura paginação
- Entra em long mode

---

## 📝 Stage 1: MBR (boot.asm)

### Estrutura Geral

```
┌─────────────────────┐
│  Inicialização      │  Configurar ambiente básico
├─────────────────────┤
│  Carregar Stage 2   │  Ler do disco
├─────────────────────┤
│  Validação          │  Verificar assinatura "QOS2"
├─────────────────────┤
│  Transferência      │  Saltar para Stage 2
└─────────────────────┘
```

### Código Explicado Seção por Seção

#### 1. Cabeçalho e Referências

```asm
[BITS 16]           ; Código 16 bits (real mode)
[ORG 0x7C00]        ; BIOS carrega MBR em 0x7C00
```

**Por quê?**

- BIOS sempre carrega o setor de boot em `0x7C00`
- CPU inicia em **real mode** (16 bits)
- `ORG` diz ao assembler que o código está nesse endereço

#### 2. Inicialização

```asm
inicio:
    cli                 ; Desabilitar interrupções
    
    xor ax, ax          ; AX = 0
    mov ds, ax          ; DS = 0
    mov es, ax          ; ES = 0
    mov ss, ax          ; SS = 0
    
    mov sp, 0x7C00      ; Stack em 0x7C00
    
    sti                 ; Reabilitar interrupções
```

**Explicação:**

1. **CLI**: Desabilita interrupções enquanto configuramos
2. **Zerar segment registers**: Em real mode, endereço físico = `segment * 16 + offset`
   - Zerando segments, usamos endereçamento linear simples
3. **Stack**: Cresce "para baixo" de 0x7C00
   - Temos ~30KB de stack (0x0000 a 0x7C00)
4. **STI**: Reabilita interrupções

#### 3. Leitura de Disco (INT 13h Extended)

```asm
mov ah, 0x42        ; Função: Extended Read
mov dl, [drive]     ; Drive de boot
mov si, dap         ; Disk Address Packet
int 0x13            ; Chamar BIOS
```

**DAP (Disk Address Packet):**

```asm
dap:
    db 0x10         ; Tamanho: 16 bytes
    db 0            ; Reservado
    dw 16           ; Setores a ler (8KB)
    dw 0x7E00       ; Destino: offset
    dw 0x0000       ; Destino: segment
    dd 1            ; LBA: setor 1
    dd 0            ; LBA high
```

**Por que Extended Read?**

- **CHS** (Cylinder-Head-Sector) é limitado e complexo
- **LBA** (Logical Block Addressing) é linear e simples
- Lemos do **LBA 1** (logo após o MBR)

#### 4. Validação do Stage 2

```asm
mov eax, [0x7E00]           ; Primeiros 4 bytes
cmp eax, 0x32534F51         ; "QOS2" em little-endian
jne erro_stage2             ; Se diferente, erro
```

**Por quê?**

- Evitar executar lixo se disco estiver corrompido
- Assinatura customizada "QOS2"

#### 5. Transferência de Controle

```asm
mov dl, [drive]         ; Passar drive ao Stage 2
jmp 0x0000:0x7E00       ; Far jump para Stage 2
```

**Far Jump**: Configura CS:IP

- CS = 0x0000
- IP = 0x7E00

#### 6. Assinatura MBR

```asm
times 510-($-$$) db 0   ; Preencher com zeros
dw 0xAA55               ; Assinatura obrigatória
```

**Por quê?**

- BIOS só aceita MBR se bytes 510-511 forem `0x55 0xAA`
- Little-endian: escrevemos `0xAA55`

---

## 📝 Stage 2: Loader (stage2.asm)

### Estrutura Geral

```
┌──────────────────────┐
│  Detecção de Memória │  INT 0x15, E820
├──────────────────────┤
│  Habilitar A20       │  Acessar >1MB
├──────────────────────┤
│  Carregar Kernel     │  Para 0x100000
├──────────────────────┤
│  Protected Mode      │  32 bits
├──────────────────────┤
│  Configurar Paginação│  4 níveis
├──────────────────────┤
│  Long Mode           │  64 bits
├──────────────────────┤
│  Transferir p/ Kernel│  RDI = boot_info
└──────────────────────┘
```

### Código Explicado

#### 1. Assinatura

```asm
dd 0x32534F51           ; "QOS2"
```

Primeiros 4 bytes = assinatura verificada pelo MBR.

#### 2. Detectar Memória (E820)

```asm
detectar_memoria:
    xor ebx, ebx            ; EBX = 0 (primeira chamada)
    mov di, mmap_entries    ; Buffer de destino
    
.loop:
    mov eax, 0xE820         ; Função E820
    mov ecx, 24             ; Tamanho da entrada
    mov edx, 0x534D4150     ; "SMAP"
    int 0x15
    
    jc .fim                 ; Sem mais entradas
    
    add di, 24              ; Próxima entrada
    inc si                  ; Contador++
    
    test ebx, ebx           ; EBX = 0 → última
    jnz .loop
```

**Como funciona:**

- **INT 0x15, EAX=0xE820**: Lista regiões de memória
- **EDX**: Deve ser "SMAP" (0x534D4150)
- **EBX**: Continuação (0 = fim)
- **ECX**: Tamanho do buffer (24 bytes)

**Formato da entrada (24 bytes):**

```
Offset  Tamanho  Descrição
0       8        Base address (64 bits)
8       8        Length (64 bits)
16      4        Type (1=Available, 2=Reserved, etc)
20      4        Extended attributes
```

#### 3. Habilitar A20

**O que é A20?**

- Processadores antigos tinham apenas 20 linhas de endereço (1MB)
- A21 (linha A20) é desabilitada por padrão para compatibilidade
- Sem A20, endereços "wraparound" em 1MB
- **Precisamos habilitar para acessar >1MB**

**Métodos (em ordem de tentativa):**

```asm
; Método 1: BIOS
mov ax, 0x2401
int 0x15
```

```asm
; Método 2: Keyboard Controller
mov al, 0xAD        ; Desabilitar teclado
out 0x64, al
mov al, 0xD0        ; Ler output port
out 0x64, al
in al, 0x60
or al, 2            ; Bit 1 = A20
out 0x60, al
mov al, 0xAE        ; Reabilitar teclado
out 0x64, al
```

```asm
; Método 3: Fast A20
in al, 0x92
or al, 2
out 0x92, al
```

#### 4. Carregar Kernel

```asm
mov ax, 0x1000      ; Segment 0x1000 (físico 0x10000)
mov es, ax
xor bx, bx          ; Offset 0

mov al, 64          ; 64 setores (32KB)
mov cl, 18          ; Setor 18 (LBA 17)
mov ah, 0x02        ; Função: Read Sectors
int 0x13
```

**Destino:** 0x1000:0x0000 = 0x10000 físico (64KB)

- Depois vamos copiar para 0x100000 (1MB)

#### 5. Entrar em Protected Mode

```asm
cli                     ; Desabilitar interrupções
lgdt [gdt_descriptor]   ; Carregar GDT

mov eax, cr0
or eax, 1               ; PE bit (Protection Enable)
mov cr0, eax

jmp 0x08:protected_mode_inicio  ; Far jump
```

**GDT (Global Descriptor Table):**

```
Entry 0: NULL (obrigatório)
Entry 1: Code Segment (0x08)
Entry 2: Data Segment (0x10)
```

**Por que far jump?**

- Limpa pipeline da CPU
- Carrega CS com novo selector

#### 6. Configurar Paginação

Em protected mode (32 bits):

```asm
configurar_paginacao:
    ; Zerar tabelas
    mov edi, 0x1000
    mov ecx, 0x1000     ; 4096 DWords
    xor eax, eax
    rep stosd
    
    ; PML4[0] → PDP
    mov dword [0x1000], 0x2003  ; Present, R/W
    
    ; PDP[0] → PD
    mov dword [0x2000], 0x3003
    
    ; PD[0] → PT
    mov dword [0x3000], 0x4003
    
    ; PT: mapear 2MB
    mov edi, 0x4000
    mov eax, 0x0003     ; Present, R/W
    mov ecx, 512
.loop:
    stosd
    add eax, 0x1000     ; +4KB
    loop .loop
    
    ; Carregar CR3
    mov eax, 0x1000
    mov cr3, eax
```

**Estrutura de 4 níveis:**

```
PML4 (Page Map Level 4) → 0x1000
  └─ PDP (Page Directory Pointer) → 0x2000
      └─ PD (Page Directory) → 0x3000
          └─ PT (Page Table) → 0x4000
              └─ 512 entradas × 4KB = 2MB
```

**Flags:**

- Bit 0: Present
- Bit 1: Read/Write

#### 7. Entrar em Long Mode

```asm
; Habilitar PAE
mov eax, cr4
or eax, (1 << 5)
mov cr4, eax

; Habilitar Long Mode (EFER.LME)
mov ecx, 0xC0000080     ; EFER MSR
rdmsr
or eax, (1 << 8)
wrmsr

; Habilitar Paging
mov eax, cr0
or eax, (1 << 31)
mov cr0, eax

jmp 0x08:long_mode_inicio
```

**Sequência obrigatória:**

1. PAE (Physical Address Extension) no CR4
2. LME (Long Mode Enable) no EFER
3. PG (Paging) no CR0
4. Far jump para código 64 bits

#### 8. Preparar boot_info

```asm
[BITS 64]
long_mode_inicio:
    mov rdi, boot_info_struct
    
    mov rax, [mmap_total]
    mov [rdi], rax          ; mem_total
    
    ; ... preencher outros campos
    
    mov rax, 0x100000       ; Endereço do kernel
    call rax                ; Chamar qkern_inicio()
```

**Convenção de chamada x86-64:**

- Primeiro argumento em **RDI**
- Passamos ponteiro para `boot_info`

---

## 🧠 Conceitos Técnicos Importantes

### Real Mode (16 bits)

- **Endereçamento:** Segment:Offset
  - Físico = (Segment × 16) + Offset
  - Exemplo: 0x1000:0x0500 = 0x10500
- **Limite:** 1MB (20 bits de endereço)
- **Proteção:** Nenhuma
- **Modo padrão** da BIOS

### Protected Mode (32 bits)

- **Segmentação:** Via GDT
- **Endereçamento:** 32 bits (4GB)
- **Proteção:** Rings 0-3
- **Paginação:** Opcional
- **Modo intermediário** para long mode

### Long Mode (64 bits)

- **Endereçamento:** 64 bits (teórico), 48 bits (real)
- **Paginação:** Obrigatória
- **Segmentação:** Simplificada (flat model)
- **Registradores:** RAX, RBX, etc (64 bits)
- **Modo final** do QuackOS

### Paginação de 4 Níveis

```
Endereço Virtual (48 bits):
┌───────┬───────┬───────┬───────┬────────────┐
│ PML4  │  PDP  │  PD   │  PT   │   Offset   │
│ 9 bit │ 9 bit │ 9 bit │ 9 bit │   12 bit   │
└───────┴───────┴───────┴───────┴────────────┘
   ↓       ↓       ↓       ↓         ↓
  Index  Index   Index  Index    Offset na página
```

**Exemplo:** Tradução de 0x0000000000001000

1. PML4[0] → 0x2003 (PDP em 0x2000)
2. PDP[0] → 0x3003 (PD em 0x3000)
3. PD[0] → 0x4003 (PT em 0x4000)
4. PT[1] → 0x1003 (página física em 0x1000)
5. Offset 0x000 → endereço final 0x1000

---

## 🎯 Fluxo Completo de Boot

```
┌──────────────┐
│     BIOS     │ POST, detectar hardware
└──────┬───────┘
       │ Carregar setor 0 → 0x7C00
       │
┌──────▼───────┐
│     MBR      │ Real Mode (16 bits)
│  boot.asm    │ • Configurar stack
│              │ • Carregar Stage 2
└──────┬───────┘
       │ Jump para 0x7E00
       │
┌──────▼───────┐
│   Stage 2    │ Real Mode → Protected → Long
│ stage2.asm   │ • Detectar memória
│              │ • Habilitar A20
│              │ • Carregar kernel
│              │ • Configurar GDT
│              │ • Entrar em Protected Mode
│              │ • Configurar paginação
│              │ • Entrar em Long Mode
└──────┬───────┘
       │ Call 0x100000
       │
┌──────▼───────┐
│    Kernel    │ Long Mode (64 bits)
│  qkern.bin   │ • Recebe boot_info em RDI
│              │ • Paginação ativa
│              │ • Inicializar QKern
└──────────────┘
```

---

## 📚 Referências Técnicas

1. **Intel 64 and IA-32 Architectures Software Developer's Manual**
   - Volume 3A: Paginação, Long Mode

2. **OSDev Wiki**
   - [Bootloader](https://wiki.osdev.org/Bootloader)
   - [A20 Line](https://wiki.osdev.org/A20_Line)
   - [Long Mode](https://wiki.osdev.org/Setting_Up_Long_Mode)

3. **BIOS Interrupts**
   - INT 0x10: Vídeo
   - INT 0x13: Disco
   - INT 0x15: Memória / A20

---

## 🦆 Filosofia QuackOS

Este bootloader exemplifica os princípios do QuackOS:

✅ **Simples**: Apenas o necessário, nada mais  
✅ **Educativo**: Cada linha comentada e explicada  
✅ **Auditável**: Código aberto e compreensível  
✅ **Funcional**: Não é apenas teoria, funciona!  
✅ **Independente**: Sem GRUB, sem UEFI complexo

> "Se não cabe num disquete mental, está errado."

---

🦆 **QuackOS** - Do nada aos 64 bits, passo a passo!
