# QuackOS - Ferramentas de Linting

Este diretório contém scripts de linting para todas as linguagens usadas no projeto QuackOS.

## 📋 Scripts Disponíveis

### `lint-all.sh` - Linter Principal

Executa todos os linters em sequência e gera um relatório consolidado.

```bash
./tools/lint/lint-all.sh
```

### `lint-asm.sh` - Assembly

Verifica arquivos `.asm`, `.s`, `.S` quanto a:

- Formatação (tabs vs espaços)
- Trailing whitespace
- Linhas muito longas
- Sintaxe básica NASM (se disponível)

```bash
./tools/lint/lint-asm.sh
```

### `lint-c.sh` - C/C++

Verifica arquivos `.c`, `.h`, `.cpp`, `.hpp` quanto a:

- Formatação com `clang-format`
- Análise estática com `cppcheck`
- Header guards
- Trailing whitespace
- Linhas muito longas

```bash
./tools/lint/lint-c.sh
```

**Dependências opcionais:**

```bash
sudo apt install clang-format cppcheck
```

### `lint-shell.sh` - Shell Scripts

Verifica arquivos `.sh` quanto a:

- Shebang correto
- Permissões de execução
- Análise com `shellcheck`
- Tratamento de erros (`set -e`)
- Trailing whitespace

```bash
./tools/lint/lint-shell.sh
```

**Dependências opcionais:**

```bash
sudo apt install shellcheck
```

### `lint-markdown.sh` - Markdown

Verifica arquivos `.md` quanto a:

- Formatação com `markdownlint`
- Trailing whitespace
- Múltiplas linhas em branco
- Título de nível 1
- Links quebrados (básico)

```bash
./tools/lint/lint-markdown.sh
```

**Dependências opcionais:**

```bash
npm install -g markdownlint-cli
```

### `lint-makefile.sh` - Makefiles

Verifica `Makefile` e `.mk` quanto a:

- Uso correto de tabs (obrigatório)
- Trailing whitespace
- Declarações `.PHONY`
- Variáveis indefinidas
- Sintaxe básica

```bash
./tools/lint/lint-makefile.sh
```

## 🚀 Uso Rápido

Para verificar todo o código do projeto:

```bash
cd /home/quack/QuackOS
./tools/lint/lint-all.sh
```

Para verificar apenas uma linguagem específica:

```bash
./tools/lint/lint-c.sh      # Apenas C/C++
./tools/lint/lint-asm.sh    # Apenas Assembly
./tools/lint/lint-shell.sh  # Apenas Shell Scripts
```

## 📊 Interpretando Resultados

Cada linter retorna:

- **Exit Code 0**: Tudo OK ou apenas avisos
- **Exit Code 1**: Erros críticos encontrados

### Níveis de Severidade

- 🔴 **[ERRO]**: Problema crítico que deve ser corrigido
- 🟡 **[AVISO]**: Sugestão de melhoria, não bloqueia

## 🔧 Instalando Todas as Dependências

Para instalar todas as ferramentas de linting recomendadas:

```bash
# Ferramentas do sistema
sudo apt update
sudo apt install -y \
    clang-format \
    cppcheck \
    shellcheck \
    nasm

# Ferramentas Node.js (requer npm)
npm install -g markdownlint-cli
```

**Nota**: Os scripts funcionam mesmo sem as ferramentas opcionais, mas com funcionalidade reduzida.

## 🎯 Integração com CI/CD

Para usar em pipelines de CI/CD:

```yaml
# Exemplo para GitHub Actions
- name: Run Linters
  run: |
    chmod +x tools/lint/*.sh
    ./tools/lint/lint-all.sh
```

```yaml
# Exemplo para GitLab CI
lint:
  script:
    - chmod +x tools/lint/*.sh
    - ./tools/lint/lint-all.sh
```

## 📝 Configuração

### clang-format

Crie um arquivo `.clang-format` na raiz do projeto para personalizar as regras de formatação C/C++.

### markdownlint

As regras estão configuradas inline no script. Para personalizar, edite `lint-markdown.sh`.

## 🤝 Contribuindo

Ao adicionar suporte para novas linguagens:

1. Crie um novo script `lint-[linguagem].sh`
2. Siga o padrão dos scripts existentes
3. Adicione o novo linter à lista em `lint-all.sh`
4. Atualize este README

## 📄 Licença

Estes scripts fazem parte do projeto QuackOS e seguem a mesma licença.
