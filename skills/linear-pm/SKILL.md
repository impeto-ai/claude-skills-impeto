---
name: linear-pm
description: Use when creating, managing, or organizing tasks in Linear. Activates for "linear", "criar task", "criar projeto", "milestone", "issue", "sub-issue", "criar epic", "backlog linear", "mover task", "review task".
chain: none
---

# Linear PM - Gestao de Projetos via API

Skill autonoma para criar e gerenciar projetos, milestones, issues e sub-issues no Linear via GraphQL API. Segue a hierarquia padrao da Impeto e respeita o workflow obrigatorio com gate de revisao humana.

## When to Use
- Criar projeto novo no Linear
- Criar milestones (epicos) dentro de um projeto
- Criar issues (stories/tasks)
- Criar sub-issues dentro de uma issue
- Mover issues entre estados (Backlog → To Do → In Progress → Review → Done)
- Consultar status de projeto/issues
- Documentar conclusao de tasks com comentarios detalhados
- NOT when: consultas simples de leitura (use Linear MCP)
- NOT when: operacoes no Airtable (use airtable-agile-pm)

## Hierarquia Padrao Impeto

```
Initiative (estrategico, ex: "Receita Propria Q1 2026")
  └── Project (escopo fechado, ex: "Mix Alimentos - Agent de Churn")
        └── Milestone (= Epico, ex: "EP-01: Setup & Infraestrutura")
              └── Issue (= Story/Task, ex: "Configurar Supabase")
                    └── Sub-issue (= Subtask, ex: "Criar migrations")
```

## Configuracao

### API
- Endpoint: `https://api.linear.app/graphql`
- Auth: `Authorization: {LINEAR_API_KEY}`
- Metodo: POST com body JSON `{"query": "...", "variables": {...}}`

### Teams Impeto
| Team | ID | Key | Uso |
|------|----|-----|-----|
| Impeto AI Core | `55aebf79-3615-4c29-8612-a6d415be4bdc` | IA | Projetos proprios e clientes |
| Workflow | `23b3fdd3-3087-4c00-b650-ad3435d24252` | WFW | Projetos Workflow |
| Impeto AI Partners | `c399b23d-f3dc-443a-ba92-43ffd7faad91` | IAP | Parcerias |

---

## WORKFLOW OBRIGATORIO

### Estados e Transicoes

```
┌──────────┐    ┌──────────┐    ┌────────────┐    ┌──────────┐    ┌──────┐
│ Backlog  │───▶│  To Do   │───▶│In Progress │───▶│  Review  │───▶│ Done │
└──────────┘    └──────────┘    └────────────┘    └──────────┘    └──────┘
                                                   🔒 GATE HUMANO
```

### Regras INVIOLAVEIS

1. **NUNCA pular Review** — toda issue que sai de "In Progress" vai OBRIGATORIAMENTE para "Review" (ou "In Review")
2. **NUNCA mover de Review → Done automaticamente** — apenas humano pode aprovar a passagem para Done
3. **Ao mover para Review**: OBRIGATORIO adicionar um comentario detalhado (ver secao Comentarios)
4. **Tag Claude**: se a task foi executada pelo Claude Code, OBRIGATORIO adicionar a label "Claude" na issue
5. **Transicoes validas**:
   - Backlog → To Do (priorizada)
   - To Do → In Progress (alguem comecou)
   - In Progress → Review (trabalho concluido, aguardando revisao)
   - Review → Done (SOMENTE apos aprovacao humana)
   - Review → In Progress (revisao reprovou, precisa refazer)
   - Qualquer → Cancelled (cancelada)

### Workflow States (consultar IDs antes de usar)

```graphql
{ team(id: "TEAM_ID") { states { nodes { id name type } } } }
```

Mapear os states consultados para:
| State Logico | Linear State Type | Exemplos de nome |
|---|---|---|
| Backlog | `backlog` | Backlog |
| To Do | `unstarted` | Todo |
| In Progress | `started` | In Progress |
| Review | `started` ou `custom` | In Review, Review |
| Done | `completed` | Done |
| Cancelled | `cancelled` | Cancelled |

> **IMPORTANTE**: Sempre consultar os states REAIS do team via query antes de criar/mover issues. Os IDs mudam entre teams.

---

## COMENTARIOS OBRIGATORIOS

### Quando Adicionar Comentario
- **Sempre** ao mover issue para Review
- **Sempre** ao concluir sub-issues
- **Opcional** em outras transicoes

### Template de Comentario (task feita por Claude Code)

```markdown
## 🤖 Task executada por Claude Code

### O que foi feito
- {descricao detalhada do que foi implementado}
- {arquivos criados/modificados}
- {decisoes tecnicas tomadas}

### Como foi feito
- {abordagem/estrategia utilizada}
- {ferramentas/libs usadas}
- {padroes seguidos}

### Arquivos alterados
- `path/to/file1.ts` — {o que mudou}
- `path/to/file2.ts` — {o que mudou}

### Testes
- {testes executados e resultados}
- {cobertura ou validacao feita}

### Observacoes para o Revisor
- {pontos de atencao}
- {trade-offs feitos}
- {sugestoes de melhoria futura}

### Status
✅ Pronto para revisao humana
```

### Template de Comentario (task feita por humano)

```markdown
## Conclusao

### O que foi feito
- {descricao}

### Observacoes
- {notas relevantes}

### Status
✅ Pronto para revisao
```

### Mutation para Comentar

```graphql
mutation {
  commentCreate(input: {
    issueId: "ISSUE_ID"
    body: "conteudo markdown do comentario"
  }) {
    comment { id body }
  }
}
```

---

## LABEL CLAUDE (obrigatoria para tasks feitas pelo Claude Code)

### Label
| Label | ID | Uso |
|-------|-----|-----|
| Claude | _consultar via query_ | Tasks executadas por Claude Code |

### Consultar Label ID
```graphql
{
  issueLabels(filter: { name: { eq: "Claude" } }) {
    nodes { id name }
  }
}
```

### Adicionar Label a Issue
Usar `labelIds` no `issueCreate` ou `issueUpdate`:
```graphql
mutation {
  issueUpdate(id: "ISSUE_ID", input: {
    labelIds: ["EXISTING_LABELS...", "CLAUDE_LABEL_ID"]
  }) {
    issue { identifier labels { nodes { name } } }
  }
}
```

> **Cuidado**: `labelIds` SUBSTITUI todas as labels. Primeiro consultar labels existentes da issue, depois passar o array completo incluindo a nova.

---

## Labels Conhecidas

| Label | ID | Uso |
|-------|----|-----|
| frontend | `27e77b77-aa4a-41ec-b8fe-bd0a9b86b58c` | UI/frontend |
| backend | `7bcc0759-f2a7-4184-b4f7-df2256f1eeb5` | API/backend |
| ai | `66de6fae-5f2f-46f8-af7f-72dabefb20fc` | Inteligencia artificial |
| devops | `e47f1131-2f62-4ec2-ab19-5a1d93b06834` | Infra/CI/CD |
| Feature | `d046098f-3937-4a28-bf19-57082d9bff71` | Nova funcionalidade |
| Improvement | `3f2c540f-923b-4a4b-9bf1-69e61c3be161` | Melhoria |
| Bug | `0fab8687-157d-4d07-bddc-f68a3f1fd887` | Correcao de bug |

---

## Mutations Reference

### 1. Criar Projeto
```graphql
mutation {
  projectCreate(input: {
    name: "Nome do Projeto"
    description: "Descricao curta (max 255 chars)"
    teamIds: ["TEAM_ID"]
    state: "started"
    targetDate: "2026-MM-DD"
  }) {
    project { id name }
  }
}
```

### 2. Linkar Projeto a Initiative
```graphql
mutation {
  initiativeToProjectCreate(input: {
    initiativeId: "INITIATIVE_ID"
    projectId: "PROJECT_ID"
  }) {
    initiativeToProject { id }
  }
}
```
> Initiative "Receita Propria Q1 2026": `be9540d9-2675-4dc8-bcde-acb11d409db5`

### 3. Criar Milestone (Epico)
```graphql
mutation {
  projectMilestoneCreate(input: {
    name: "EP-01: Nome do Epico"
    projectId: "PROJECT_ID"
  }) {
    projectMilestone { id name }
  }
}
```

### 4. Criar Issue
```graphql
mutation {
  issueCreate(input: {
    title: "Nome da issue"
    teamId: "TEAM_ID"
    projectId: "PROJECT_ID"
    projectMilestoneId: "MILESTONE_ID"
    stateId: "STATE_ID"
    priority: 2
    estimate: 3
    dueDate: "2026-MM-DD"
    labelIds: ["LABEL_ID"]
    assigneeId: "USER_ID"
  }) {
    issue { id identifier title url }
  }
}
```

Priority: 0=None, 1=Urgent, 2=High, 3=Medium, 4=Low
Estimate: pontos de story (1, 2, 3, 5, 8, 13)

### 5. Criar Sub-issue
```graphql
mutation {
  issueCreate(input: {
    title: "Nome da sub-issue"
    teamId: "TEAM_ID"
    parentId: "PARENT_ISSUE_ID"
    stateId: "STATE_ID"
  }) {
    issue { id identifier }
  }
}
```

### 6. Atualizar Issue (mover estado, atribuir, etc.)
```graphql
mutation {
  issueUpdate(id: "ISSUE_ID", input: {
    stateId: "NEW_STATE_ID"
    assigneeId: "USER_ID"
    dueDate: "2026-MM-DD"
    projectMilestoneId: "MILESTONE_ID"
    labelIds: ["LABEL_IDS..."]
  }) {
    issue { identifier title state { name } }
  }
}
```

### 7. Criar Cycle (Sprint)
```graphql
mutation {
  cycleCreate(input: {
    teamId: "TEAM_ID"
    name: "Sprint 01 - Mar/2026"
    startsAt: "2026-03-01T00:00:00Z"
    endsAt: "2026-03-14T00:00:00Z"
  }) {
    cycle { id name }
  }
}
```

### 8. Adicionar Comentario
```graphql
mutation {
  commentCreate(input: {
    issueId: "ISSUE_ID"
    body: "Conteudo markdown"
  }) {
    comment { id body }
  }
}
```

---

## Queries Reference

### Listar Projetos do Team
```graphql
{
  team(id: "TEAM_ID") {
    projects(first: 50) {
      nodes { id name state description }
    }
  }
}
```

### Consultar Issues de um Projeto
```graphql
{
  project(id: "PROJECT_ID") {
    name
    projectMilestones { nodes { id name } }
    issues(first: 100) {
      nodes {
        identifier title
        state { name type }
        assignee { name }
        projectMilestone { name }
        labels { nodes { name } }
        priority
        estimate
        dueDate
      }
    }
  }
}
```

### Buscar Issue por Identifier
```graphql
{
  issueSearch(query: "IMP-123", first: 1) {
    nodes {
      id identifier title
      state { id name type }
      labels { nodes { id name } }
      assignee { name }
      comments { nodes { body createdAt user { name } } }
    }
  }
}
```

### Listar Milestones de um Projeto
```graphql
{
  project(id: "PROJECT_ID") {
    projectMilestones {
      nodes { id name sortOrder }
    }
  }
}
```

### Consultar Labels
```graphql
{
  issueLabels(first: 50) {
    nodes { id name color }
  }
}
```

---

## Workflow Autonomo: Mover Issue para Review

Quando uma task e concluida pelo Claude Code, executar TODOS estes passos em sequencia:

### Passo 1: Consultar issue atual
```graphql
{
  issueSearch(query: "IDENTIFIER", first: 1) {
    nodes {
      id identifier
      state { id name }
      labels { nodes { id name } }
    }
  }
}
```

### Passo 2: Consultar state "Review" do team
```graphql
{ team(id: "TEAM_ID") { states { nodes { id name type } } } }
```

### Passo 3: Consultar label "Claude"
```graphql
{ issueLabels(filter: { name: { eq: "Claude" } }) { nodes { id name } } }
```

### Passo 4: Atualizar issue (estado + label Claude)
```graphql
mutation {
  issueUpdate(id: "ISSUE_ID", input: {
    stateId: "REVIEW_STATE_ID"
    labelIds: ["...labels_existentes...", "CLAUDE_LABEL_ID"]
  }) {
    issue { identifier state { name } labels { nodes { name } } }
  }
}
```

### Passo 5: Adicionar comentario detalhado
```graphql
mutation {
  commentCreate(input: {
    issueId: "ISSUE_ID"
    body: "## 🤖 Task executada por Claude Code\n\n### O que foi feito\n- ...\n\n### Como foi feito\n- ...\n\n### Arquivos alterados\n- ...\n\n### Testes\n- ...\n\n### Observacoes para o Revisor\n- ...\n\n### Status\n✅ Pronto para revisao humana"
  }) {
    comment { id }
  }
}
```

### Passo 6: Informar o usuario
```
✅ Issue {IDENTIFIER} movida para Review
   - Label "Claude" adicionada
   - Comentario detalhado adicionado
   - ⏳ Aguardando revisao humana para mover para Done
```

---

## Workflow Padrao para Novo Projeto

1. **Perguntar**: nome do projeto, team (IA, WFW ou IAP), descricao
2. **Consultar states** do team escolhido
3. **Consultar labels** disponiveis
4. **Criar projeto** com projectCreate
5. **(Opcional)** Linkar a initiative existente
6. **SEMPRE criar EP-00: Setup & Infraestrutura** (ver template abaixo)
7. **Perguntar milestones adicionais** (epicos) — nomes e descricoes
8. **Criar milestones** com projectMilestoneCreate
9. **Perguntar issues** por milestone — titulo, label, priority, estimate, dueDate, assignee
10. **Criar issues** com issueCreate linkando ao milestone (estado inicial: Backlog ou To Do)
11. **(Opcional)** Criar sub-issues se necessario
12. **Resumir** tudo criado com tabela organizada

---

## Template EP-00: Setup & Infraestrutura (OBRIGATORIO em todo projeto novo)

Todo projeto novo da Impeto DEVE comecar com o milestone EP-00 contendo estas 4 tasks padrao.
Adaptar descricoes conforme a stack do projeto (Python, Go, Next.js, etc).

### Milestone
```
EP-00: Setup & Infraestrutura (sortOrder: 0 — sempre primeiro)
```

### Task 1: Setup do Repositorio
```
Titulo: Setup do Repositorio
Estado: Todo
Prioridade: Urgent (1)
Labels: devops, backend
Descricao:
  - Criar repo na org impeto-ai (GitHub)
  - Branch protection em main (require PR + 1 review)
  - .gitignore (adequado a stack)
  - .editorconfig
  - CLAUDE.md com instrucoes do projeto (stack, convencoes, comandos)
  - .env.example com todas as variaveis documentadas
  - README minimo (como rodar, pre-requisitos)
  Criterio de Done: outro dev consegue clonar e rodar
```

### Task 2: Provisionar Infraestrutura
```
Titulo: Provisionar Infraestrutura
Estado: Todo
Prioridade: High (2)
Labels: devops
Descricao:
  - Criar projeto no Supabase / banco escolhido
  - Provisionar hosting (Railway / GCP Cloud Run / outro)
  - Configurar secrets no hosting
  - Dominio/DNS (se aplicavel)
  - Variaveis de ambiente em staging
  Criterio de Done: ambiente staging acessivel com banco conectado
```

### Task 3: CI/CD Base
```
Titulo: CI/CD Base
Estado: Backlog
Prioridade: Medium (3)
Labels: devops
Descricao:
  - GitHub Actions: lint + test no PR
  - Deploy automatico em staging no merge em main
  - Secrets configurados no GitHub
  Criterio de Done: PR roda checks automaticos, merge em main faz deploy em staging
```

### Task 4: Onboarding do Time
```
Titulo: Onboarding do Time
Estado: Backlog
Prioridade: Medium (3)
Labels: devops
Descricao:
  - Cada dev roda setup local e confirma que projeto roda
  - Rodar linear-setup.sh (instalar skills Linear)
  - /linear-init para carregar contexto
  - Primeiro PR de teste (pode ser trivial)
  Criterio de Done: todos os devs do projeto com ambiente rodando e Linear integrado
```

### Notas
- Tasks 1 e 2 em **Todo** (prontas pra pegar imediatamente)
- Tasks 3 e 4 em **Backlog** (dependem das primeiras)
- Adaptar descricoes conforme stack (ex: se nao usa Supabase, trocar na Task 2)
- O responsavel por EP-00 e sempre o **dev lead** do projeto

---

## Convencao GitHub

### Branch
```
feat/{IDENTIFIER}-{slug}     → feature
fix/{IDENTIFIER}-{slug}      → bugfix
chore/{IDENTIFIER}-{slug}    → infra/devops
```
Exemplo: `feat/IMP-124-configurar-api-key`

### Commit
```
feat: descricao curta [{IDENTIFIER}]
fix: corrigir bug [{IDENTIFIER}]
chore: configuracao [{IDENTIFIER}]
```
Exemplo: `feat: setup supabase auth [IMP-111]`

### PR Description
```markdown
## Linear
Closes {IDENTIFIER}

## O que foi feito
- Item 1
- Item 2

## Test plan
- [ ] Teste 1
- [ ] Teste 2
```

---

## Gotchas & Limites

- `description` do projeto: max **255 caracteres**
- `initiativeId` NAO funciona em `projectCreate` — usar mutation separada `initiativeToProjectCreate`
- `parentId` (nao `parent_id`) para sub-issues
- `labelIds` no update **SUBSTITUI** todas as labels — sempre consultar existentes antes
- Query complexity limit: **10.000** — limitar `first: 100` e evitar campos aninhados demais
- Labels: verificar IDs antes de usar (podem mudar entre workspaces)
- Cycles no Linear sao automaticos por data (ativam quando a data chega)
- **Segregacao**: Linear nao segrega por projeto, apenas por Team

## Common Mistakes

- Esquecer de consultar os states do team antes de criar issues (IDs mudam entre teams)
- Usar `parent_id` ao inves de `parentId`
- Description do projeto com mais de 255 chars (API rejeita)
- Criar issues sem `projectMilestoneId` (ficam orfas, sem milestone)
- Query GraphQL muito complexa (usar `first: 100`, evitar nested relations)
- Nao linkar initiative separadamente (nao e campo do projectCreate)
- **Pular o estado Review** — NUNCA fazer In Progress → Done direto
- **Mover para Done sem aprovacao humana** — NUNCA, sempre aguardar revisao
- **Esquecer de adicionar label Claude** quando task foi feita pelo Claude Code
- **Esquecer comentario detalhado** ao mover para Review
- **Sobrescrever labels** usando `labelIds` sem consultar as existentes primeiro
