# 🦆 QuackOS Bootloader

Bootloader próprio do QuackOS, implementado em Assembly x86 (16/32/64 bits), seguindo rigorosamente a especificação **BOOT.md**.

## 📋 Características

- **MBR próprio** (512 bytes) - sem GRUB
- **Stage 2 separado** (8KB) para funcionalidades avançadas
- **BIOS-only** (Legacy Boot)
- **Pipeline completo**: Real Mode → Protected Mode → Long Mode (64 bits)
- **Paginação de 4 níveis** configurada automaticamente
- **Detecção de memória** via INT 0x15 (E820)
- **Linha A20** habilitada automaticamente

## 🏗️ Arquitetura

### Pipeline de Inicialização

```
┌─────────┐
│  BIOS   │  Carrega MBR em 0x7C00
└────┬────┘
     │
     ▼
┌──────────────────────────────────────┐
│  MBR (boot.asm) - 512 bytes          │
│  • Configura stack                   │
│  • Carrega Stage 2 (LBA 1-16)        │
│  • Valida assinatura "QOS2"          │
│  • Salta para 0x7E00                 │
└────┬─────────────────────────────────┘
     │
     ▼
┌──────────────────────────────────────┐
│  Stage 2 (stage2.asm) - 8KB          │
│  • Detecta memória (E820)            │
│  • Habilita A20                      │
│  • Carrega kernel em 0x100000        │
│  • Entra em Protected Mode (32 bits) │
│  • Configura paginação (4 níveis)    │
│  • Entra em Long Mode (64 bits)      │
│  • Prepara boot_info                 │
│  • Salta para qkern_inicio()         │
└────┬─────────────────────────────────┘
     │
     ▼
┌──────────────────────────────────────┐
│  QKern (kernel) - em 0x100000        │
│  • Recebe controle em 64 bits        │
│  • Paginação ativa                   │
│  • Recebe ponteiro boot_info         │
└──────────────────────────────────────┘
```

## 📦 Estrutura de Arquivos

```
bootloader/
├── boot.asm        # MBR (Stage 1) - 512 bytes
├── stage2.asm      # Stage 2 Loader - 8KB
├── Makefile        # Compilação automatizada
└── README.md       # Este arquivo
```

## 🔧 Compilação

### Requisitos

- **NASM** (Netwide Assembler)
- **QEMU** (para testes)
- **dd** (coreutils)

Instalação no Ubuntu/Debian:

```bash
sudo apt install nasm qemu-system-x86 coreutils
```

### Compilar

```bash
cd bootloader
make
```

Isso irá:

1. Compilar `boot.asm` → `build/boot.bin` (512 bytes)
2. Compilar `stage2.asm` → `build/stage2.bin` (8192 bytes)
3. Criar `build/quackos.img` (imagem de disco de 10MB)

### Executar no QEMU

```bash
make run
```

### Debug

```bash
make debug        # Modo debug com monitor
make debug-gui    # Debug com interface gráfica
```

## 🗺️ Layout do Disco

| LBA   | Tamanho | Conteúdo            | Descrição                    |
|-------|---------|---------------------|------------------------------|
| 0     | 512 B   | `boot.bin` (MBR)    | Stage 1 - carregador inicial |
| 1-16  | 8 KB    | `stage2.bin`        | Stage 2 - loader completo    |
| 17+   | Variável| `qkern.bin`         | Kernel (a ser implementado)  |

## 🧠 Layout de Memória

### Durante o Boot

| Endereço   | Conteúdo           | Tamanho |
|------------|--------------------|---------|
| 0x0000     | IVT / BDA          | ~1.5KB  |
| 0x0500     | Stack (cresce ↓)   | ~30KB   |
| 0x7C00     | MBR (boot.bin)     | 512B    |
| 0x7E00     | Stage 2 (stage2.bin)| 8KB    |
| 0x1000     | Tabelas de paginação| 16KB   |
| 0x10000    | Kernel temporário  | 32KB+   |
| 0x100000   | Kernel final (1MB) | Variável|

### Após Long Mode

| Endereço Virtual         | Conteúdo          |
|--------------------------|-------------------|
| 0x0000000000000000 - 0x00007FFFFFFFFFFF | Userspace        |
| 0xFFFFFFFF80000000 - 0xFFFFFFFFFFFFFFFF | QKern (kernel)   |

## 📊 Estrutura boot_info

Passada ao kernel em **RDI**:

```c
struct boot_info {
    uint64_t mem_total;      // Memória total detectada (bytes)
    uint64_t mem_livre;      // Memória livre disponível (bytes)
    void*    framebuffer;    // Ponteiro para framebuffer (NULL se não configurado)
    uint32_t fb_largura;     // Largura do framebuffer (pixels)
    uint32_t fb_altura;      // Altura do framebuffer (pixels)
    uint32_t fb_bpp;         // Bits por pixel
};
```

## 🔍 Detalhes Técnicos

### MBR (boot.asm)

**Modo**: Real Mode (16 bits)  
**Origem**: 0x7C00  
**Tamanho**: Exatamente 512 bytes

**Responsabilidades**:

1. Configurar segment registers (DS, ES, SS = 0)
2. Configurar stack em 0x7C00
3. Carregar Stage 2 usando INT 13h Extended Read (função 0x42)
4. Validar assinatura "QOS2" do Stage 2
5. Transferir controle para 0x7E00

**Limitações**:

- Usa DAP (Disk Address Packet) para LBA
- Carrega 16 setores (8KB) do Stage 2
- Nenhum sistema de arquivos

### Stage 2 (stage2.asm)

**Modo inicial**: Real Mode (16 bits)  
**Modo final**: Long Mode (64 bits)  
**Origem**: 0x7E00  
**Tamanho**: 8192 bytes (16 setores)

**Responsabilidades**:

#### 1. Detecção de Memória (E820)

- Usa INT 0x15, EAX=0xE820
- Armazena até 32 entradas de memória
- Calcula total e livre

#### 2. Habilitação A20

Métodos tentados em ordem:

1. BIOS (INT 0x15, AX=0x2401)
2. Keyboard Controller (porta 0x64)
3. Fast A20 (porta 0x92)

#### 3. Protected Mode (32 bits)

- Carrega GDT com 3 entradas (null, code, data)
- Ativa CR0.PE (bit 0)
- Far jump para limpar pipeline

#### 4. Paginação (4 níveis)

Estrutura:

```
PML4 (0x1000)
  └─ PDP (0x2000)
      └─ PD (0x3000)
          └─ PT (0x4000)
              └─ 512 páginas de 4KB (2MB total)
```

#### 5. Long Mode (64 bits)

- Habilita CR4.PAE (bit 5)
- Habilita EFER.LME (MSR 0xC0000080, bit 8)
- Habilita CR0.PG (bit 31)
- Far jump para código 64 bits

## ⚙️ Registradores ao Entrar no Kernel

| Registrador | Valor                     |
|-------------|---------------------------|
| **RDI**     | Ponteiro para `boot_info` |
| **RSP**     | Stack válida (~0x90000)   |
| **CR0**     | PG=1, PE=1                |
| **CR3**     | 0x1000 (PML4)             |
| **CR4**     | PAE=1                     |
| **EFER**    | LME=1, LMA=1              |
| **CS**      | 0x08 (code segment)       |
| **DS/ES/SS**| 0x10 (data segment)       |

## 🧪 Testes

### Teste 1: Compilação

```bash
make clean
make
```

✅ Deve compilar sem erros  
✅ `boot.bin` deve ter exatamente 512 bytes  
✅ `stage2.bin` deve ter exatamente 8192 bytes

### Teste 2: Boot no QEMU

```bash
make run
```

✅ Deve exibir mensagens do bootloader  
✅ Deve detectar memória  
✅ Deve habilitar A20  
✅ Deve tentar carregar kernel (falhará se kernel não existir)

### Teste 3: Assinatura MBR

```bash
hexdump -C build/boot.bin | tail -n 1
```

✅ Últimos dois bytes devem ser `55 aa`

### Teste 4: Assinatura Stage 2

```bash
hexdump -C build/stage2.bin | head -n 1
```

✅ Primeiros 4 bytes devem ser `51 4f 53 32` ("QOS2")

## 🐛 Troubleshooting

### "ERRO: Falha ao ler disco"

- Verifique se a imagem está corrompida
- Recompile com `make clean && make`

### "ERRO: Stage 2 invalido"

- Stage 2 não tem assinatura correta
- Verifique se `stage2.bin` começa com "QOS2"

### Boot trava após Stage 2

- Kernel não foi carregado ou está corrompido
- Implemente um kernel mínimo de teste

### A20 não habilita

- Normal em alguns emuladores
- Código tenta 3 métodos automaticamente

## 📚 Referências

- **BOOT.md** - Especificação oficial do boot
- [OSDev Wiki - Bootloader](https://wiki.osdev.org/Bootloader)
- [OSDev Wiki - A20 Line](https://wiki.osdev.org/A20_Line)
- [Intel Manual - Long Mode](https://www.intel.com/content/www/us/en/architecture-and-technology/64-ia-32-architectures-software-developer-vol-3a-part-1-manual.html)

## 🦆 Filosofia QuackOS

> "Boot simples, auditável e reimplementável.  
> Se não cabe num disquete mental, está errado."

Este bootloader segue os princípios do QuackOS:

- ✅ Código claro e comentado
- ✅ Sem dependências externas (GRUB, UEFI)
- ✅ Compatível com hardware antigo
- ✅ Totalmente reimplementável
- ✅ Educativo e funcional

---

**Próximo passo**: Implementar kernel mínimo (`qkern.bin`) que receba o controle em long mode.
