# 📂 Índice de Documentação - Bootloader QuackOS

Este diretório contém a implementação completa do bootloader proprietário do QuackOS.

---

## 📋 Arquivos de Código

| Arquivo | Descrição | Tamanho | Linguagem |
|---------|-----------|---------|-----------|
| **boot.asm** | MBR (Stage 1) | 512 bytes | Assembly x86 (16-bit) |
| **stage2.asm** | Stage 2 Loader | 8 KB | Assembly x86 (16/32/64-bit) |
| **Makefile** | Build automation | - | Make |

---

## 📚 Documentação

### Para Iniciantes

1. **README.md** - Comece aqui!
   - Visão geral do bootloader
   - Arquitetura e pipeline
   - Como compilar e executar
   - Layout de memória e disco

2. **EXPLICACAO.md** - Entenda cada linha
   - Explicação detalhada de cada seção
   - Conceitos técnicos (Real Mode, Protected Mode, Long Mode)
   - Paginação de 4 níveis
   - Fluxo completo comentado

### Para Uso Prático

1. **TESTING.md** - Teste o bootloader
   - Instalação de dependências
   - Testes de compilação
   - Execução no QEMU
   - Criação de kernel stub
   - Troubleshooting

2. **install_deps.sh** - Script de instalação
   - Instala NASM, QEMU e dependências
   - Suporta Ubuntu, Fedora, Arch

### Referência Oficial

1. **BOOT.md** (na raiz `/home/quack/QuackOS/`)
   - Especificação normativa oficial
   - Contrato técnico do boot
   - Todas as implementações devem seguir este documento

---

## 🎯 Fluxo de Aprendizado Recomendado

### Nível 1: Visão Geral (30 minutos)

```
1. Leia README.md (seções: Características, Arquitetura, Pipeline)
2. Veja o diagrama visual do pipeline
3. Execute: ./install_deps.sh && make run
```

### Nível 2: Compreensão Profunda (2-3 horas)

```
1. Leia EXPLICACAO.md completamente
2. Abra boot.asm e siga junto com EXPLICACAO.md
3. Abra stage2.asm e siga junto com EXPLICACAO.md
4. Execute com debug: make debug
```

### Nível 3: Domínio Técnico (1 dia)

```
1. Leia BOOT.md (especificação oficial)
2. Leia TESTING.md e execute todos os testes
3. Crie um kernel stub e veja o bootloader funcionar
4. Experimente modificar o código
```

### Nível 4: Desenvolvimento (contínuo)

```
1. Implemente kernel mínimo (QKern)
2. Teste com kernel real
3. Adicione detecção VESA
4. Otimize paginação para kernel high-half
```

---

## 🔧 Quick Start

### Instalação

```bash
cd /home/quack/QuackOS/bootloader
./install_deps.sh
```

### Compilação

```bash
make clean
make
```

### Execução

```bash
make run          # Executar no QEMU
make debug        # Debug mode
```

### Estrutura de Build

```
bootloader/
├── build/                  # Criado após 'make'
│   ├── boot.bin           # MBR binário (512 bytes)
│   ├── stage2.bin         # Stage 2 binário (8 KB)
│   └── quackos.img        # Imagem de disco bootável (10 MB)
└── ...
```

---

## 📊 Mapa de Conceitos

### Conceitos Fundamentais

- [x] Real Mode (16 bits)
- [x] Protected Mode (32 bits)
- [x] Long Mode (64 bits)
- [x] Paginação de 4 níveis
- [x] GDT (Global Descriptor Table)
- [x] Linha A20
- [x] Detecção de memória (E820)

### Técnicas de Bootloader

- [x] MBR em 512 bytes
- [x] Bootloader em dois estágios
- [x] Leitura de disco (LBA via INT 13h)
- [x] Transição de modos
- [x] Configuração de paginação
- [x] Validação de assinatura

### Especificações BIOS

- [x] INT 0x10 (Vídeo)
- [x] INT 0x13 (Disco)
- [x] INT 0x15 (Memória/A20)
- [x] DAP (Disk Address Packet)
- [x] Memory Map (E820)

---

## 🐛 Troubleshooting Rápido

| Problema | Solução |
|----------|---------|
| `nasm: command not found` | Execute `./install_deps.sh` |
| `ERRO: MBR deve ter 512 bytes` | Código do MBR muito grande, otimizar |
| `ERRO: Stage 2 invalido` | Assinatura incorreta, verificar Stage 2 |
| `Trava após Stage 2` | Kernel não encontrado (normal sem kernel) |
| Boot não inicia | Imagem corrompida, `make clean && make` |

---

## 📈 Estado do Projeto

### ✅ Implementado

- [x] MBR funcional (boot.asm)
- [x] Stage 2 funcional (stage2.asm)
- [x] Detecção de memória
- [x] Habilitação A20
- [x] Transição para Long Mode
- [x] Paginação de 4 níveis
- [x] Estrutura boot_info
- [x] Documentação completa

### ⏳ Próximos Passos

- [ ] Kernel mínimo (qkern.bin)
- [ ] Detecção VESA para framebuffer
- [ ] Suporte a UEFI (opcional, futuro)
- [ ] Modo gráfico inicial

---

## 🔗 Links Úteis

### Documentação Interna

- [BOOT.md](/home/quack/QuackOS/BOOT.md) - Especificação oficial
- [README.md geral](/home/quack/QuackOS/README.md) - Visão geral do QuackOS

### Referências Externas

- [OSDev Wiki - Bootloader](https://wiki.osdev.org/Bootloader)
- [OSDev Wiki - Long Mode](https://wiki.osdev.org/Setting_Up_Long_Mode)
- [Intel SDM](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)

---

## 🦆 Filosofia

> **"Boot simples, auditável e reimplementável.  
> Se não cabe num disquete mental, está errado."**

Este bootloader exemplifica os valores do QuackOS:

- ✅ Código claro e bem comentado
- ✅ Sem dependências externas (GRUB, UEFI)
- ✅ Educativo e funcional
- ✅ Compatível com hardware antigo
- ✅ Totalmente open source

---

## 📞 Ajuda

Se tiver dúvidas:

1. Leia EXPLICACAO.md para entender conceitos
2. Consulte TESTING.md para problemas de compilação
3. Verifique troubleshooting no README.md
4. Leia BOOT.md para especificação oficial

---

**Última atualização:** 2026-01-17  
**Versão:** 1.0  
**Status:** ✅ Funcional (aguardando kernel)
