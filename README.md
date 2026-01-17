# QuackOS

QuackOS é um sistema operacional **UNIX-like**, educacional e experimental, projetado para ser **simples, legível e totalmente especificado**.

Ele foi pensado para ser implementável **do zero**, inclusive por inteligências artificiais, sem dependências modernas desnecessárias.

---

## Visão Geral

* 🦆 Sistema: **QuackOS**
* ⚙️ Kernel: **QKern**
* 🖥️ GUI: **QGUI**
* 📦 Biblioteca padrão: **libq**
* 🧠 Filosofia: *tudo é arquivo*
* 🌎 Linguagem humana: **português**

---

## Objetivos do Projeto

* Criar um sistema operacional didático, porém real
* Rodar em computadores x86-64 levemente antigos
* Evitar complexidade moderna (UEFI, systemd, aceleração 3D)
* Ser previsível, auditável e extensível

---

## Arquitetura

* BIOS + MBR
* Long mode (64 bits)
* Paging clássico (4 níveis)
* Kernel em C com assembly mínimo

---

## Componentes Principais

* **QKern**: kernel monolítico simples
* **QFS**: sistema de arquivos onde tudo é arquivo
* **QGUI**: servidor gráfico clássico em userspace
* **libq**: biblioteca padrão mínima
* **init**: processo inicial previsível

---

## Documentação

Todos os aspectos do sistema estão formalmente definidos:

* `QuackOS_SPEC.md`
* `BOOT.md`
* `SYSCALLS.md`
* `MEMORIA.md`
* `DISPOSITIVOS.md`
* `QGUI.md`
* `LIBQ.md`
* `INIT.md`
* `PORTING.md`
* `TESTES.md`

Esses documentos são **normativos**.

---

## Estado do Projeto

* Projeto em fase de especificação completa
* Pronto para implementação
* Ideal para aprendizado, pesquisa e experimentos assistidos por IA

---

## Licença

MIT.

---

QuackOS não tenta ser moderno.
Ele tenta ser **compreensível**.
