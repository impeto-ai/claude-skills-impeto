---
name: airtable-agile-pm
description: Use when managing projects, epics, tasks, stories in Airtable. Activates for "airtable", "epic", "task", "story", "sprint", "backlog", "criar projeto", "criar epic", "criar task".
chain: none
---

# Airtable Agile Project Manager

Especialista em gestao agil via Airtable MCP. Planeja com o usuario e executa criacao de Clientes, Projetos, Epics, Tasks e Stories seguindo metodologia agil, direto no Airtable.

## When to Use
- Criar ou gerenciar projetos no Airtable
- Criar epics, tasks, stories, sprints
- Planejar backlog e organizar trabalho
- Atualizar status de tasks/epics
- Consultar estado atual do projeto
- NOT when: trabalho puramente tecnico sem gestao de projeto

## Airtable MCP Setup

### Conexao
- Base ID: `applXPES8Ea0prJog` (AgileOps Workspace)
- MCP Tool: `mcp__airtable__AIRTABLE_EXECUTE_TOOL`
- MCP Search: `mcp__airtable__AIRTABLE_SEARCH_TOOLS`

### IMPORTANTE: Carregar Tools Antes de Usar
SEMPRE use `ToolSearch` para carregar as ferramentas do Airtable ANTES de chama-las:
```
ToolSearch: "+airtable execute"
```

### Tool Slugs Disponiveis
| Acao | Slug |
|------|------|
| Criar 1 registro | `AIRTABLE_CREATE_RECORD` |
| Criar ate 10 registros | `AIRTABLE_CREATE_RECORDS` |
| Atualizar registro | `AIRTABLE_UPDATE_RECORD` |
| Deletar registro | `AIRTABLE_DELETE_RECORD` |
| Listar registros | `AIRTABLE_LIST_RECORDS` |
| Buscar 1 registro | `AIRTABLE_GET_RECORD` |
| Schema da base | `AIRTABLE_GET_BASE_SCHEMA` |
| Listar bases | `AIRTABLE_LIST_BASES` |

### Formato de Chamada
```json
{
  "tool_slug": "AIRTABLE_CREATE_RECORD",
  "arguments": {
    "baseId": "applXPES8Ea0prJog",
    "tableIdOrName": "Tasks",
    "fields": { "Task": "...", "Notes": "...", "Status": "Todo", "Epic": ["recXXX"] },
    "typecast": true
  }
}
```

Para operacoes destrutivas (UPDATE, DELETE):
```json
"allow_destructive": true
```

---

## Schema AgileOps Workspace

### Tabela: Clientes
| Campo | Tipo | Notas |
|-------|------|-------|
| Name | singleLineText | Nome do cliente |
| Status | singleSelect | `In Progress`, `Done`, `onHold`, `Teste` |
| Escopo | multilineText | Descricao do escopo |
| Iniciado | checkbox | Se ja iniciou |
| Projetos | multipleRecordLinks | Link para Projects (auto) |
| Responsaveis | multipleRecordLinks | Link para Equipe |
| Stack Hub | multipleRecordLinks | Tecnologias |

### Tabela: Projects
| Campo | Tipo | Notas |
|-------|------|-------|
| Name | singleLineText | Nome do projeto |
| Clientes | multipleRecordLinks | Link para Clientes |
| Notes | multilineText | Descricao detalhada |
| Status | singleSelect | `Todo`, `In progress`, `Done` |
| Entrega Planejada | date | Data estimada de entrega |
| Responsavel (is) | multipleRecordLinks | Link para Equipe |
| Gestor de Projetos | multipleRecordLinks | Link para Epics |
| Projeto Editado | formula | `[Cliente] Nome` (auto) |

### Tabela: Epics
| Campo | Tipo | Notas |
|-------|------|-------|
| Name | singleLineText | Nome do epic (ex: "EP-01: Titulo") |
| Projeto | multipleRecordLinks | Link para Projects |
| Status | singleSelect | `Todo`, `In Progress`, `Done`, `Backlog` |
| Grau de Prioridade | number | 1-5 (1 = mais prioritario) |

### Tabela: Tasks
| Campo | Tipo | Notas |
|-------|------|-------|
| Task | singleLineText | Nome da task |
| Notes | multilineText | Descricao detalhada |
| Status | singleSelect | `Todo`, `In Progress`, `Done`, `Blocked` |
| Epic | multipleRecordLinks | Link para Epics |
| Projeto | lookup | COMPUTADO via Epic (NAO SETAR) |
| Responsavel | singleLineText | Nome do responsavel |
| Urgencia | singleSelect | Auto-calculado |
| Inicio Planejado | dateTime | Data/hora de inicio |
| id_sprint | multipleRecordLinks | Link para Sprints |

> **CRITICO**: O campo `Projeto` em Tasks e COMPUTADO (lookup via Epic). NUNCA tente setar diretamente. Basta linkar o Epic correto.

### Tabela: Sprints
| Campo | Tipo | Notas |
|-------|------|-------|
| Name | singleLineText | Nome do sprint |
| Inicio | date | Data inicio |
| Fim | date | Data fim |

---

## Workflow de Planejamento

### FASE 1: Discovery com o Usuario

Antes de criar qualquer registro, SEMPRE faça discovery:

```
1. "Qual o cliente? (verificar se ja existe no Airtable)"
2. "Qual o projeto? (verificar se ja existe)"
3. "Quais epics voce enxerga para esse projeto?"
4. "Para cada epic, quais tasks sao necessarias?"
5. "Alguma task ja foi realizada? (marcar como Done)"
```

### FASE 2: Verificacao de Existencia

SEMPRE verificar se o cliente/projeto ja existe antes de criar:

```json
{
  "tool_slug": "AIRTABLE_LIST_RECORDS",
  "arguments": {
    "baseId": "applXPES8Ea0prJog",
    "tableIdOrName": "Clientes",
    "filterByFormula": "FIND('NomeCliente', {Name})"
  }
}
```

Se ja existir, usar o record ID existente. NAO CRIAR DUPLICATAS.

### FASE 3: Criacao Hierarquica

Ordem OBRIGATORIA de criacao:
```
1. Cliente (se nao existe)
2. Projeto (linkado ao Cliente)
3. Epics (linkados ao Projeto)
4. Tasks (linkadas aos Epics)
```

Cada nivel depende do ID do nivel anterior. Criar SEQUENCIALMENTE.

### FASE 4: Apresentacao ao Usuario

Apos criar, apresentar resumo estruturado:

```
## [Cliente] - [Projeto]

### EP-01: Titulo (Status)
1. Task A (Status)
2. Task B (Status)
3. Task C (Status)

### EP-02: Titulo (Status)
1. Task D (Status)
2. Task E (Status)
```

---

## Padroes de Nomenclatura

### Epics
```
EP-{NN}: {Titulo Descritivo}
```
Exemplos:
- EP-01: Negociacao & Onboarding
- EP-02: Levantamento de Requisitos
- EP-03: Arquitetura & Setup
- EP-04: Desenvolvimento Core

### Tasks
Usar verbos no infinitivo:
- "Configurar ambiente de desenvolvimento"
- "Desenvolver Agent Qualificador"
- "Implementar pipeline RAG"
- "Testar retrieval com queries reais"

### Status Flow
```
Backlog → Todo → In Progress → Done
                       ↓
                   Blocked
```

---

## Templates de Epics por Tipo de Projeto

### Projeto AI Agent
```
EP-01: Negociacao & Onboarding
EP-02: Levantamento de Requisitos
EP-03: Arquitetura & Setup Tecnico
EP-04: Base de Conhecimento (RAG)
EP-05: Desenvolvimento dos Agents
EP-06: Interface & Deploy
EP-07: Testes & Validacao
EP-08: Go-Live & Monitoring
```

### Projeto Automacao
```
EP-01: Discovery & Mapeamento
EP-02: Desenho de Solucao
EP-03: Desenvolvimento
EP-04: Integracao
EP-05: Testes & QA
EP-06: Deploy & Treinamento
```

### Projeto Web/App
```
EP-01: Discovery & UX Research
EP-02: Design & Prototipacao
EP-03: Setup & Arquitetura
EP-04: Desenvolvimento Frontend
EP-05: Desenvolvimento Backend
EP-06: Integracao & API
EP-07: QA & Testes
EP-08: Deploy & Launch
```

---

## Operacoes Comuns

### Mover task para outro epic
```json
{
  "tool_slug": "AIRTABLE_UPDATE_RECORD",
  "arguments": {
    "baseId": "applXPES8Ea0prJog",
    "tableIdOrName": "Tasks",
    "recordId": "recXXX",
    "fields": { "Epic": ["recNovoEpicID"] }
  }
}
```

### Atualizar status em lote
Para cada task:
```json
{
  "tool_slug": "AIRTABLE_UPDATE_RECORD",
  "arguments": {
    "baseId": "applXPES8Ea0prJog",
    "tableIdOrName": "Tasks",
    "recordId": "recXXX",
    "fields": { "Status": "Done" }
  }
}
```

### Listar tasks de um epic
```json
{
  "tool_slug": "AIRTABLE_LIST_RECORDS",
  "arguments": {
    "baseId": "applXPES8Ea0prJog",
    "tableIdOrName": "Tasks",
    "filterByFormula": "FIND('recEpicID', ARRAYJOIN(Epic))"
  }
}
```

### Listar tasks por status
```json
{
  "tool_slug": "AIRTABLE_LIST_RECORDS",
  "arguments": {
    "baseId": "applXPES8Ea0prJog",
    "tableIdOrName": "Tasks",
    "filterByFormula": "{Status}='In Progress'"
  }
}
```

---

## Armadilhas Conhecidas

1. **Campo `Projeto` em Tasks e COMPUTED** - nunca tente setar. Ele herda do Epic automaticamente.
2. **Campo `Name` em Clientes** (nao `Nome`) - o field name e case-sensitive.
3. **Links sao arrays** - sempre usar `["recXXX"]` mesmo para link unico.
4. **AIRTABLE_UPDATE_RECORD e AIRTABLE_DELETE_RECORD precisam de `allow_destructive: true`**.
5. **`typecast: true`** ajuda com selects que podem nao existir ainda.
6. **Verificar existencia ANTES de criar** - evitar duplicatas como criamos "Mixalimentos" quando ja existia "MIX Alimentos".
7. **filterByFormula** - field names sao CASE SENSITIVE. Usar exatamente como no schema.
8. **Criar em ordem hierarquica** - Cliente > Projeto > Epic > Task. Cada nivel precisa do ID do anterior.

---

## Exemplos de Uso

### Exemplo 1: Criar projeto completo
```
Usuario: "Cria um projeto pro cliente X com epics e tasks"

1. Verificar se cliente X existe no Airtable
2. Se existe, pegar record ID
3. Se nao existe, criar cliente
4. Criar projeto linkado ao cliente
5. Apresentar template de epics para o tipo de projeto
6. Confirmar epics com usuario
7. Criar epics linkados ao projeto
8. Para cada epic, definir tasks com usuario
9. Criar tasks linkadas aos epics
10. Apresentar resumo final
```

### Exemplo 2: Atualizar status
```
Usuario: "Atualiza as tasks do EP-03 para In Progress"

1. Listar tasks do EP-03
2. Confirmar com usuario quais atualizar
3. Atualizar cada task
4. Apresentar resultado
```

### Exemplo 3: Adicionar tasks a epic existente
```
Usuario: "Adiciona mais 3 tasks no EP-05"

1. Listar tasks atuais do EP-05
2. Confirmar novas tasks com usuario
3. Criar tasks linkadas ao EP-05
4. Apresentar resumo atualizado
```

---

## Common Mistakes
- Criar cliente duplicado sem verificar se ja existe
- Tentar setar o campo "Projeto" em Tasks (e computed)
- Esquecer `allow_destructive: true` em updates/deletes
- Usar field names errados (case sensitive)
- Criar registros sem ordem hierarquica
- Nao usar `typecast: true` ao criar com selects
- Chamar tools MCP sem carregar via ToolSearch primeiro
