# BOOT.md — Processo de Inicialização do QuackOS

Este documento define **exatamente** como o QuackOS inicializa, sem abstrações modernas desnecessárias.

---

## 🎯 Alvo

- **Arquitetura**: x86-64
- **Firmware**: BIOS (Legacy)
- **Máquinas**: PCs antigos (2008–2015)

---

## 🚀 Pipeline de Boot

### 1. BIOS

- BIOS carrega o **MBR** (LBA 0) para **0x7C00**
- CPU inicia em **real mode** (16 bits)

### 2. MBR (boot.asm)

**Responsabilidades mínimas**:

- Configurar stack básica
- Limpar interrupções
- Carregar o **Stage 2** do disco
- Não contém filesystem complexo

**Limites**:

- **512 bytes**
- Assinatura **0x55AA** obrigatória

### 3. Stage 2 Loader (stage2.asm)

**Funções principais**:

- Detectar mapa de memória (INT 0x15, E820)
- Habilitar linha A20
- Carregar kernel (**qkern.bin**) para memória alta (0x100000)
- Trocar para **protected mode** (32 bits)
- Configurar **paginação de 4 níveis**
- Preparar transição para **long mode** (64 bits)
- Transferir controle ao kernel

### 4. Entrada do Kernel (QKern)

- CPU já em **long mode** (64 bits)
- **Paginação** ativada
- **Stack** válida
- Registradores limpos

**Ponto de entrada**:

```c
void qkern_inicio(struct boot_info* info);
```

---

## 📊 Estrutura boot_info

```c
struct boot_info {
    uint64_t mem_total;      // Memória total em bytes
    uint64_t mem_livre;      // Memória livre em bytes
    void*    framebuffer;    // Ponteiro para framebuffer (ou NULL)
    uint32_t fb_largura;     // Largura em pixels
    uint32_t fb_altura;      // Altura em pixels
    uint32_t fb_bpp;         // Bits por pixel
};
```

Esta estrutura é passada ao kernel no registrador **RDI**.

---

## ⚙️ Detalhes Técnicos

### Layout de Memória Durante Boot

| Endereço    | Conteúdo                | Tamanho  |
|-------------|-------------------------|----------|
| 0x0000      | IVT / BIOS Data Area    | ~1.5 KB  |
| 0x0500      | Stack (cresce para baixo)| ~30 KB  |
| 0x7C00      | MBR (boot.bin)          | 512 B    |
| 0x7E00      | Stage 2 (stage2.bin)    | 8 KB     |
| 0x1000-0x5000| Tabelas de paginação   | 16 KB    |
| 0x100000    | Kernel (qkern.bin)      | Variável |

### Layout do Disco

| LBA    | Tamanho   | Conteúdo       |
|--------|-----------|----------------|
| 0      | 512 B     | MBR            |
| 1-16   | 8 KB      | Stage 2        |
| 17+    | Variável  | Kernel         |

### Transições de Modo

```
Real Mode (16 bits)
    ↓
Protected Mode (32 bits)
    ↓
Long Mode (64 bits)
    ↓
Kernel
```

### Registradores ao Entrar no Kernel

| Registrador | Valor                          |
|-------------|--------------------------------|
| **RIP**     | Endereço de `qkern_inicio()`   |
| **RDI**     | Ponteiro para `boot_info`      |
| **RSP**     | Stack válida                   |
| **CR0**     | PG=1, PE=1                     |
| **CR3**     | Endereço do PML4 (0x1000)      |
| **CR4**     | PAE=1                          |
| **CS**      | Code segment (0x08)            |
| **DS/ES/SS**| Data segment (0x10)            |

---

## 🔒 Regras de Ouro

1. ✅ **Nenhuma dependência de UEFI**
2. ✅ **Nenhum GRUB**
3. ✅ **Boot simples, auditável e reimplementável**
4. ✅ **Se não cabe num disquete mental, está errado**

---

## 🧪 Testes Obrigatórios

- ✅ Boot em **QEMU**
- ✅ Boot em **PC real**
- ✅ Falha limpa se kernel não for encontrado
- ✅ Dump visual mínimo em caso de erro

---

## 📝 Notas de Implementação

### Detecção de Memória (E820)

O bootloader usa a **INT 0x15, EAX=0xE820** para detectar regiões de memória disponíveis. As entradas são armazenadas e processadas para calcular:

- Total de memória instalada
- Memória livre (tipo 1 - Available)

### Habilitação A20

A linha A20 deve ser habilitada para acessar memória acima de 1MB. O bootloader tenta, em ordem:

1. BIOS (INT 0x15, AX=0x2401)
2. Keyboard Controller (porta 0x64)
3. Fast A20 (porta 0x92)

### Paginação

O bootloader configura paginação de **4 níveis** (PML4 → PDP → PD → PT):

- Mapeia os primeiros **2MB** de memória
- Identity mapping (endereço virtual = endereço físico)
- Permite transição suave para long mode

### Long Mode

Sequência para entrar em long mode:

1. Configurar paginação (CR3 = PML4)
2. Habilitar PAE (CR4.PAE = 1)
3. Habilitar Long Mode (EFER.LME = 1)
4. Habilitar paging (CR0.PG = 1)
5. Far jump para código 64 bits

---

## 🎓 Filosofia

> "O QuackOS nasce do nada até chegar ao QKern em 64 bits através de um pipeline claro, auditável e educativo."

Este bootloader não é apenas funcional — é **didático**. Cada linha de código tem um propósito claro e comentado.

---

## 📚 Arquivos Relacionados

- `bootloader/boot.asm` - Implementação do MBR
- `bootloader/stage2.asm` - Implementação do Stage 2
- `bootloader/Makefile` - Compilação automatizada
- `bootloader/README.md` - Documentação técnica detalhada

---

**Este documento é normativo. Implementações devem segui-lo literalmente.**

🦆 **QuackOS** - Sistema operacional próprio, simples e educativo.
