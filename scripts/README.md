# QuackOS - Scripts de Automação 🦆

Este diretório contém scripts shell para facilitar o desenvolvimento, compilação e teste do QuackOS.

## 📋 Scripts Disponíveis

### 🔨 `build.sh` - Compilação Completa

Compila todo o QuackOS (bootloader + kernel) e cria a imagem de disco bootável.

```bash
./scripts/build.sh
```

**O que faz:**

- Verifica dependências (nasm, ld, dd, make)
- Compila o bootloader (MBR + Stage 2)
- Compila o kernel (QKern)
- Integra tudo na imagem de disco
- Copia para o diretório `build/`

---

### 🚀 `run.sh` - Execução no QEMU

Executa o QuackOS no emulador QEMU.

```bash
./scripts/run.sh [opções]
```

**Opções:**

- `-h, --help` - Mostra ajuda
- `-d, --debug` - Modo debug (sem reboot, com logs)
- `-m, --monitor` - Abre monitor do QEMU
- `-n, --nographic` - Modo sem interface gráfica (console serial)
- `-k, --kvm` - Usar KVM (virtualização de hardware)
- `--memory SIZE` - Define memória RAM (padrão: 256M)
- `--cpus N` - Número de CPUs (padrão: 1)
- `--build` - Compila antes de executar

**Exemplos:**

```bash
./scripts/run.sh                    # Execução normal
./scripts/run.sh --debug            # Com debug
./scripts/run.sh --kvm --memory 512M  # KVM com 512MB
./scripts/run.sh --build            # Compila e executa
```

---

### 🧪 `test.sh` - Testes Automatizados

Executa suite de testes completa para verificar o QuackOS.

```bash
./scripts/test.sh
```

**Testa:**

- ✅ Tamanho correto do MBR (512 bytes)
- ✅ Assinatura de boot (0x55AA)
- ✅ Tamanho do Stage 2 (8KB)
- ✅ Formato ELF64 do kernel
- ✅ Entry point do kernel
- ✅ Símbolos importantes
- ✅ Sistema de build
- ✅ Boot rápido no QEMU

---

### 🐛 `debug.sh` - Debug com GDB

Inicia QEMU em modo debug e conecta o GDB para debugging.

```bash
./scripts/debug.sh
./scripts/debug.sh --auto  # Inicia GDB automaticamente
```

**Modos:**

1. **QEMU apenas** - Aguarda conexão externa do GDB
2. **QEMU + GDB automático** - Inicia ambos juntos

**Arquivos gerados:**

- `build/gdb_commands.txt` - Script GDB com comandos úteis
- `build/qemu_debug.log` - Log de debug do QEMU

---

### 🧹 `clean.sh` - Limpeza

Remove todos os artefatos de compilação.

```bash
./scripts/clean.sh
```

**Remove:**

- Build do bootloader (`bootloader/build/`)
- Build do kernel (`kernel/*.o`, `kernel/*.elf`)
- Diretório de build central (`build/`)

---

### ℹ️ `info.sh` - Informações do Sistema

Exibe informações detalhadas sobre o build do QuackOS.

```bash
./scripts/info.sh              # Menu interativo
./scripts/info.sh --all        # Todas as informações
./scripts/info.sh --bootloader # Apenas bootloader
./scripts/info.sh --kernel     # Apenas kernel
./scripts/info.sh --disk       # Apenas imagem
./scripts/info.sh --env        # Ambiente
./scripts/info.sh --stats      # Estatísticas
```

**Informações exibidas:**

- Detalhes do bootloader (MBR, Stage 2)
- Informações do kernel (ELF, entry point, seções)
- Estrutura da imagem de disco
- Versões das ferramentas
- Estatísticas do projeto

---

## 🔄 Workflow Típico

### 1️⃣ Primeira compilação

```bash
./scripts/build.sh
```

### 2️⃣ Testar

```bash
./scripts/test.sh
```

### 3️⃣ Executar

```bash
./scripts/run.sh
```

### 4️⃣ Debug (se necessário)

```bash
./scripts/debug.sh --auto
```

### 5️⃣ Recompilar após mudanças

```bash
./scripts/clean.sh
./scripts/build.sh
```

---

## 🛠️ Dependências Necessárias

Todos os scripts verificam automaticamente, mas aqui está a lista completa:

```bash
# Ubuntu/Debian
sudo apt install nasm binutils coreutils make qemu-system-x86 gdb

# Arch Linux
sudo pacman -S nasm binutils coreutils make qemu-system-x86 gdb

# Fedora
sudo dnf install nasm binutils coreutils make qemu-system-x86 gdb
```

---

## 📁 Estrutura de Saída

Após compilar, a estrutura será:

```
QuackOS/
├── build/                    # Build central
│   ├── quackos.img          # Imagem de disco bootável
│   ├── qkern.elf            # Kernel ELF64
│   ├── qemu.log             # Logs do QEMU (se executado)
│   └── gdb_commands.txt     # Script GDB (se debug)
├── bootloader/
│   └── build/
│       ├── boot.bin         # MBR (512 bytes)
│       ├── stage2.bin       # Stage 2 (8KB)
│       └── quackos.img      # Imagem original
└── kernel/
    ├── qkern.o              # Object file
    └── qkern.elf            # Kernel final
```

---

## 🎨 Cores e Output

Todos os scripts usam cores para facilitar a leitura:

- 🔵 **Azul/Ciano** - Headers e informações
- 🟢 **Verde** - Sucesso e confirmações
- 🟡 **Amarelo** - Avisos
- 🔴 **Vermelho** - Erros

---

## 🆘 Problemas Comuns

### "Dependências faltando"

```bash
sudo apt install nasm binutils coreutils make qemu-system-x86
```

### "Imagem não encontrada"

```bash
./scripts/build.sh  # Compile primeiro
```

### "Permission denied"

```bash
chmod +x scripts/*.sh  # Tornar executável
```

---

## 📝 Notas

1. **Todos os scripts devem ser executados a partir da raiz do projeto**
2. Scripts detectam automaticamente o diretório do projeto
3. Suporte a cores pode ser desabilitado com `NO_COLOR=1`
4. Logs são salvos em `build/`

---

**QuackOS** 🦆 - Um sistema operacional de aprendizado
