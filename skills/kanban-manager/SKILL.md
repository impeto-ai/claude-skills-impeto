---
name: kanban-manager
description: Use when managing dev tasks via Obsidian Kanban boards. Activates for kanban, task, board, mover task, criar task, validar task.
chain: none
---

# Kanban Manager

Gerencia boards Kanban no Obsidian via MCP. Suporta multiplos projetos com boards independentes e fluxo de auditoria integrado.

## When to Use

- Criar/mover/atualizar tasks no kanban
- Criar novo kanban para um projeto
- Mover tasks entre colunas (fluxo)
- Listar tasks pendentes/em progresso
- Validar tasks (mover para Concluido)
- NOT when: tarefas de codigo (usar agents de dev)

## Arquitetura

```
01-Projects/
├── Dev-Kanban.md              # Index com links para boards
├── Dev-Kanban-Agrino.md       # Board agrino-web
├── Dev-Kanban-SGI.md          # Board SGI
└── Dev-Kanban-{Projeto}.md    # Novos projetos
```

## Fluxo de Colunas

```
Backlog → Em Progresso → Auditoria → Validacao → Concluido
```

| Coluna | Responsavel | Descricao |
|--------|-------------|-----------|
| Backlog | Lead/User | Tasks a serem feitas |
| Em Progresso | Agent dev | Agent trabalhando na task |
| Auditoria | Agent auditor | Codigo pronto, aguarda audit via agrino-dev-audit |
| Validacao | User | Audit aprovado, aguarda validacao do usuario |
| Concluido | - | Task validada e finalizada |

## Formato de Card

### Card novo (Backlog)
```
- [ ] {Titulo da task} #{projeto}
	**Solicitacao:** {descricao breve}
	**Criado:** {YYYY-MM-DD HH:mm}
```

### Card em progresso
```
- [ ] {Titulo} #{projeto}
	**Solicitacao:** {descricao}
	**Agent:** {nome-agent} | **Inicio:** {YYYY-MM-DD HH:mm}
```

### Card em auditoria
```
- [ ] {Titulo} #{projeto}
	**Feito:** {o que foi feito}
	**Agent:** {nome-agent} | **Aguardando audit**
```

### Card em validacao
```
- [ ] {Titulo} #{projeto}
	**Feito:** {o que foi feito}
	**Audit:** APROVADO | **Concluido:** {YYYY-MM-DD HH:mm}
```

### Card concluido
```
- [x] {Titulo} #{projeto}
	**Commit:** {hash} ({branch}) | {YYYY-MM-DD HH:mm}
```

## Instrucoes

### Criar novo kanban para projeto

1. Criar arquivo `01-Projects/Dev-Kanban-{NomeProjeto}.md`
2. Usar template:
```markdown
---

kanban-plugin: board

---

## Backlog



## Em Progresso



## Auditoria



## Validacao



## Concluido



%% kanban:settings
```
{"kanban-plugin":"board","lane-width":320,"show-checkboxes":true}
```
%%
```
3. Adicionar link no `Dev-Kanban.md` (index)

### Adicionar task

1. Identificar o board correto pelo projeto (tag #projeto)
2. Adicionar card na coluna Backlog com formato padrao
3. Usar mcp__obsidian-mcp-tools__str_replace ou obsidian_api

### Mover task entre colunas

1. Ler o board atual com mcp__obsidian-mcp-tools__view
2. Identificar o card pelo titulo
3. Remover da coluna atual (str_replace removendo o card)
4. Adicionar na coluna destino (str_replace inserindo apos o header da coluna)
5. Atualizar metadados do card conforme a coluna destino

### Fluxo completo de uma task

```
1. User cria task → Backlog
2. Agent pega task → Em Progresso (adiciona Agent + Inicio)
3. Agent termina → Auditoria (adiciona Feito + Aguardando audit)
4. Agent auditor roda audit:
   - APROVADO → Validacao (adiciona Audit: APROVADO)
   - REPROVADO → volta pra Em Progresso com feedback
5. User valida → Concluido (marca [x] + adiciona Commit)
```

### Listar boards existentes

Ler `01-Projects/Dev-Kanban.md` (index) para ver todos os boards disponiveis.

### Descobrir board de um projeto

- Verificar se existe `Dev-Kanban-{Projeto}.md`
- Se nao existe, perguntar ao user se quer criar

## Ferramentas MCP

Usar as seguintes tools do Obsidian MCP:

| Acao | Tool |
|------|------|
| Ler board | `mcp__obsidian-mcp-tools__view` |
| Editar card | `mcp__obsidian-mcp-tools__str_replace` |
| Criar board | `mcp__obsidian-mcp-tools__create` |
| Operacoes complexas | `mcp__obsidian-mcp-tools__obsidian_api` |

**IMPORTANTE:** O plugin Kanban do Obsidian converte `<br>` em tabs/newlines. Usar `\n\t` para quebras dentro de cards, NAO usar `<br>`.

## Regras

1. **Um board por projeto** - nunca misturar projetos no mesmo board
2. **Index sempre atualizado** - ao criar novo board, adicionar no Dev-Kanban.md
3. **Metadados obrigatorios** - todo card deve ter pelo menos titulo + tag do projeto
4. **Auditoria antes de validacao** - tasks NAO podem pular de Em Progresso direto pra Validacao
5. **Audit chain** - ao mover para Auditoria, disparar agrino-dev-audit (ou equivalente do projeto)
6. **Nao deletar cards** - mover para Concluido, nunca remover

## Common Mistakes

- Misturar tasks de projetos diferentes no mesmo board
- Pular a coluna Auditoria (ir direto de Em Progresso pra Validacao)
- Esquecer de atualizar o index ao criar novo board
- Usar `<br>` ao inves de `\n\t` nos cards (Obsidian converte)
- Nao incluir tag do projeto no card
