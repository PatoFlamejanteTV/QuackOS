# 🧪 Guia de Testes - QuackOS Bootloader

Este documento descreve como testar o bootloader do QuackOS.

## 📋 Pré-requisitos

### Instalação de Dependências

Execute o script de instalação:

```bash
cd /home/quack/QuackOS/bootloader
./install_deps.sh
```

Ou instale manualmente:

**Ubuntu/Debian:**

```bash
sudo apt install nasm qemu-system-x86 build-essential
```

**Fedora/RHEL:**

```bash
sudo dnf install nasm qemu-system-x86 gcc make
```

**Arch/Manjaro:**

```bash
sudo pacman -S nasm qemu-system-x86 base-devel
```

---

## 🔨 Teste 1: Compilação

### Compilar o Bootloader

```bash
cd /home/quack/QuackOS/bootloader
make clean
make
```

### Resultado Esperado

```
✅ QuackOS bootloader compilado com sucesso!
   Imagem: build/quackos.img
```

### Verificações

**1. Tamanho do MBR:**

```bash
stat -c%s build/boot.bin
```

Deve retornar: `512`

**2. Tamanho do Stage 2:**

```bash
stat -c%s build/stage2.bin
```

Deve retornar: `8192`

**3. Assinatura do MBR (0x55AA):**

```bash
hexdump -C build/boot.bin | tail -n 1
```

Últimos dois bytes devem ser: `55 aa`

**4. Assinatura do Stage 2 ("QOS2"):**

```bash
hexdump -C build/stage2.bin | head -n 1
```

Primeiros 4 bytes devem ser: `51 4f 53 32`

---

## 🦆 Teste 2: Execução no QEMU (Sem Kernel)

Como ainda não temos um kernel implementado, o bootloader irá falhar ao tentar carregá-lo. Isso é **esperado**.

### Executar

```bash
make run
```

### Resultado Esperado

Você verá:

1. ✅ "QuackOS Boot v1.0"
2. ✅ "Carregando Stage 2..."
3. ✅ "Stage 2 OK. Transferindo..."
4. ✅ "Stage 2 iniciado"
5. ✅ "Detectando memoria..."
6. ✅ "Habilitando A20..."
7. ✅ "Carregando kernel..."
8. ❌ "ERRO: Falha ao carregar kernel" (esperado)

**Nota:** O erro é normal pois ainda não implementamos o kernel.

---

## 🔍 Teste 3: Debug Detalhado

### Executar com Debug

```bash
make debug
```

Isso abrirá o QEMU com o monitor. Você pode:

- Verificar registradores: `info registers`
- Ver estado da CPU: `info cpus`
- Inspecionar memória: `x/16xb 0x7c00`

### Verificar Transições de Modo

No debug, você pode acompanhar:

1. **Real Mode** (16 bits) - CS=0x0000, RIP=0x7C00
2. **Protected Mode** (32 bits) - após Stage 2
3. **Long Mode** (64 bits) - antes de chamar kernel

---

## 📊 Teste 4: Análise de Dumps

### Dump do MBR

```bash
hexdump -C build/boot.bin > mbr_dump.txt
cat mbr_dump.txt
```

**Verificações:**

- Bytes 0-1: Código de boot (geralmente `EB` ou `E9`)
- Bytes 510-511: `55 AA`

### Dump do Stage 2

```bash
hexdump -C build/stage2.bin | head -n 20 > stage2_dump.txt
cat stage2_dump.txt
```

**Verificações:**

- Bytes 0-3: `51 4F 53 32` ("QOS2")

### Dump da Imagem Completa

```bash
hexdump -C build/quackos.img | head -n 40
```

**Verificações:**

- LBA 0 (bytes 0-511): MBR
- LBA 1 (bytes 512-8703): Stage 2

---

## 🎯 Teste 5: Criação de Kernel Stub (Teste Completo)

Para testar o bootloader completamente, vamos criar um kernel mínimo que apenas exibe uma mensagem.

### Criar kernel_stub.asm

```bash
cat > kernel_stub.asm << 'EOF'
```

```asm
[BITS 64]
[ORG 0x100000]

inicio:
    ; Preencher tela com caractere 'K' (Kernel)
    mov rax, 0xB8000        ; Endereço do VGA text buffer
    mov rcx, 2000           ; 80x25 = 2000 caracteres
    mov ax, 0x4F4B          ; 'K' branco sobre vermelho
    
.loop:
    mov [rax], ax
    add rax, 2
    loop .loop
    
    ; Halt
    cli
    hlt
    jmp $

times 512-($-$$) db 0
EOF
```

### Compilar Kernel Stub

```bash
nasm -f bin kernel_stub.asm -o build/qkern.bin
```

### Adicionar ao Disco

```bash
dd if=build/qkern.bin of=build/quackos.img bs=512 seek=17 conv=notrunc
```

### Executar

```bash
make run
```

### Resultado Esperado

✅ Tela preenchida com letra 'K' em branco sobre vermelho  
✅ Significa que o bootloader funcionou completamente!

---

## 📈 Checklist de Testes

Execute este checklist para validar o bootloader:

- [ ] **Compilação**
  - [ ] `make clean` executa sem erros
  - [ ] `make` executa sem erros
  - [ ] `boot.bin` tem 512 bytes
  - [ ] `stage2.bin` tem 8192 bytes
  - [ ] `quackos.img` foi criado

- [ ] **Assinaturas**
  - [ ] MBR termina com `55 AA`
  - [ ] Stage 2 começa com `51 4F 53 32` (QOS2)

- [ ] **Execução**
  - [ ] QEMU inicia sem erros
  - [ ] Mensagens do bootloader aparecem
  - [ ] Detecção de memória funciona
  - [ ] A20 é habilitado
  - [ ] Tentativa de carregar kernel (mesmo que falhe)

- [ ] **Com Kernel Stub**
  - [ ] Tela preenche com 'K'
  - [ ] Sistema não trava antes de transferir controle

---

## 🐛 Problemas Comuns

### "Command 'nasm' not found"

**Solução:**

```bash
./install_deps.sh
```

### "Could not access KVM kernel module"

**Solução:** Ignore. QEMU funcionará sem KVM, apenas mais lento.

### "ERRO: MBR deve ter exatamente 512 bytes"

**Solução:** O código do MBR está muito grande. Verifique:

```bash
nasm -f bin boot.asm -l boot.lst
cat boot.lst
```

### Trava após "Stage 2 OK"

**Solução:** Stage 2 pode ter bug. Execute com debug:

```bash
make debug
```

### "ERRO: Falha ao carregar kernel"

**Solução:** Isso é esperado se você não tem kernel. Ignore ou crie kernel stub.

---

## 📚 Logs Esperados

### Sem Kernel (Normal)

```
QuackOS Boot v1.0
Carregando Stage 2...
Stage 2 OK. Transferindo...
Stage 2 iniciado
Detectando memoria...
Habilitando A20...
Carregando kernel...
ERRO: Falha ao carregar kernel
```

### Com Kernel Stub (Sucesso!)

```
QuackOS Boot v1.0
Carregando Stage 2...
Stage 2 OK. Transferindo...
Stage 2 iniciado
Detectando memoria...
Habilitando A20...
Carregando kernel...
Entrando em protected mode...
[Tela preenchida com 'K']
```

---

## 🎓 Próximos Passos

Após validar o bootloader:

1. ✅ Bootloader funcionando
2. ⏭️ Implementar kernel mínimo (QKern)
3. ⏭️ Implementar syscalls básicas
4. ⏭️ Implementar gerenciamento de memória
5. ⏭️ Implementar drivers básicos

---

**🦆 QuackOS** - Boot simples, auditável e funcional!
