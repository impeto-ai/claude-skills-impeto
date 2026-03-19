---
name: linear-work
description: Operational skill for day-to-day Linear task management. View personal tasks, move states, create issues, add comments. Activates for "linear-work", "minhas tasks", "mover task", "criar issue", "comentar issue", "atualizar linear".
chain: none
---

# Linear Work - Operacao Diaria

Skill operacional para o dia-a-dia do dev. Foco em tasks pessoais, movimentacao de estados, criacao de issues e comentarios.

## When to Use
- Ver minhas tasks atuais
- Mover task entre estados (To Do → In Progress → Review)
- Criar nova issue/sub-issue
- Adicionar comentario em issue
- Atualizar prioridade, estimate, due date
- NOT when: criar projetos/milestones (use /linear-pm)
- NOT when: apenas carregar contexto (use /linear-init)

---

## PASSO 0: VERIFICAR API KEY (OBRIGATORIO)

**ANTES DE QUALQUER COISA**, verificar se existe a variavel `LINEAR_API_KEY`:

1. Procurar `.env` no diretorio atual do projeto
2. Se nao encontrar, procurar em `~/.claude/.env`
3. Se nao encontrar em nenhum dos dois:

```
⚠️  LINEAR_API_KEY nao encontrada!

Solicite sua key ao seu manager (Joao - joao@impeto.ai).

Apos receber:
1. Crie .env na raiz do projeto: LINEAR_API_KEY=lin_api_XXXXX
2. Rode /linear-init para carregar o contexto
```

**PARAR AQUI se nao encontrar a key. Nao tentar nenhuma operacao.**

---

## IDENTIFICAR USUARIO

Sempre comecar identificando quem e o usuario via `viewer`:

```graphql
{ viewer { id name email } }
```

Guardar o `id` para filtrar tasks atribuidas ao usuario.

---

## OPERACOES

### 1. VER MINHAS TASKS

```graphql
{
  viewer {
    assignedIssues(
      filter: { state: { type: { nin: ["completed", "canceled"] } } }
      first: 50
      orderBy: updatedAt
    ) {
      nodes {
        id identifier title
        state { id name type }
        priority estimate dueDate
        project { name }
        projectMilestone { name }
        labels { nodes { id name } }
        team { id key }
        children { nodes { identifier title state { name } } }
      }
    }
  }
}
```

Apresentar agrupado por estado:
```
━━━ IN PROGRESS ━━━
  IA-42 | Implementar API auth | P2 | Due: 2026-03-15
    └─ IA-43 | Criar middleware (Done)
    └─ IA-44 | Testes integracao (In Progress)

━━━ TODO ━━━
  WFW-18 | Setup CI/CD pipeline | P3 | Due: 2026-03-20

━━━ BACKLOG ━━━
  IAP-7 | Documentar API | P4 | Sem data
```

### 2. MOVER TASK

**REGRAS INVIOLAVEIS:**
- NUNCA pular "In Review" — In Progress vai para In Review, NUNCA direto para Done
- NUNCA mover de In Review → Done — somente humano aprova
- Ao mover para In Review: OBRIGATORIO adicionar comentario detalhado
- Se task feita pelo Claude Code: OBRIGATORIO adicionar label "Claude"

**Workflow de estados por team:**

| Team | Backlog | Todo | In Progress | In Review | Done | Canceled |
|------|---------|------|-------------|-----------|------|----------|
| IAP | `864e6d89` | `d9ee0a28` | `63d82e50` | `210d982d` | `782dfd8a` | `ec8f76dd` |
| WFW | `6a17e88b` | `73c302a8` | `ada57e06` | `375f55a8` | `dbb124d1` | `f5d62680` |
| IA  | `4e00167a` | `4e4c1171` | `08c23863` | `e23d1ccd` | `2fe9f7ed` | `1566587e` |

**IDs completos:**

| Team | State | ID |
|------|-------|----|
| IAP | Backlog | `864e6d89-2074-4e30-9f94-b5eba62d81a5` |
| IAP | Todo | `d9ee0a28-e8be-498a-9d52-18641d2f0633` |
| IAP | In Progress | `63d82e50-5899-4ad4-be39-09d265a3c7e3` |
| IAP | In Review | `210d982d-f9c1-46e0-9ebb-c8a7ffc1bea8` |
| IAP | Done | `782dfd8a-f433-43a1-9690-f04d00197dae` |
| IAP | Canceled | `ec8f76dd-b3c0-4eae-977f-0799f9742fe1` |
| WFW | Backlog | `6a17e88b-2fe0-4f68-af47-8250b00152a0` |
| WFW | Todo | `73c302a8-9375-4f10-b03c-4d7e4a3b619c` |
| WFW | In Progress | `ada57e06-3cd0-4700-8865-a1d8d272b740` |
| WFW | In Review | `375f55a8-f8fd-459c-a492-8566c4b77f25` |
| WFW | Done | `dbb124d1-e26e-4397-9e73-44de04149c00` |
| WFW | Canceled | `f5d62680-5214-42b4-8869-3e30ae228233` |
| IA | Backlog | `4e00167a-06d2-4dc9-9e4d-d706c3e864b1` |
| IA | Todo | `4e4c1171-8df3-40e2-9fed-c682f5e787ee` |
| IA | In Progress | `08c23863-0e85-46fd-851d-48b927855509` |
| IA | In Review | `e23d1ccd-da99-4572-887f-61e6d0a59e90` |
| IA | Done | `2fe9f7ed-200c-40f1-804a-73725e61183d` |
| IA | Canceled | `1566587e-db99-4718-a24f-3df272dcdb27` |

**Mutation para mover:**
```graphql
mutation {
  issueUpdate(id: "ISSUE_ID", input: {
    stateId: "NEW_STATE_ID"
  }) {
    issue { identifier title state { name } }
  }
}
```

### 3. MOVER PARA REVIEW (workflow especial)

Ao mover para In Review, executar TODOS os passos:

**3a.** Consultar issue atual (pegar labels existentes):
```graphql
{
  issue(id: "ISSUE_ID") {
    id identifier labels { nodes { id name } }
    team { id key }
  }
}
```

**3b.** Atualizar estado + adicionar label Claude (se aplicavel):
```graphql
mutation {
  issueUpdate(id: "ISSUE_ID", input: {
    stateId: "IN_REVIEW_STATE_ID"
    labelIds: ["...labels_existentes...", "6dad8eed-291b-413b-9bfc-524e7aae0521"]
  }) {
    issue { identifier state { name } labels { nodes { name } } }
  }
}
```

Label Claude ID: `6dad8eed-291b-413b-9bfc-524e7aae0521`

**CUIDADO:** `labelIds` SUBSTITUI todas as labels. Sempre incluir as existentes + a nova.

**3c.** Adicionar comentario detalhado:
```graphql
mutation {
  commentCreate(input: {
    issueId: "ISSUE_ID"
    body: "## Task executada por Claude Code\n\n### O que foi feito\n- {descricao}\n\n### Arquivos alterados\n- {lista}\n\n### Testes\n- {resultados}\n\n### Observacoes para o Revisor\n- {pontos de atencao}\n\n### Status\nPronto para revisao humana"
  }) {
    comment { id }
  }
}
```

**3d.** Confirmar ao usuario:
```
✅ {IDENTIFIER} movida para In Review
   - Label "Claude" adicionada
   - Comentario detalhado adicionado
   - Aguardando revisao humana para Done
```

### 4. CRIAR ISSUE

Perguntar ao usuario:
- Titulo
- Team (IAP, WFW, IA)
- Projeto (listar projetos ativos do team)
- Milestone (listar milestones do projeto)
- Prioridade (1=Urgent, 2=High, 3=Medium, 4=Low)
- Estimate (1, 2, 3, 5, 8, 13 pontos)
- Labels (listar disponiveis)
- Due date (opcional)
- Atribuir a quem? (default: viewer)

```graphql
mutation {
  issueCreate(input: {
    title: "Titulo"
    teamId: "TEAM_ID"
    projectId: "PROJECT_ID"
    projectMilestoneId: "MILESTONE_ID"
    stateId: "TODO_STATE_ID"
    priority: 3
    estimate: 3
    dueDate: "2026-MM-DD"
    labelIds: ["LABEL_IDS"]
    assigneeId: "USER_ID"
  }) {
    issue { id identifier title url }
  }
}
```

### 5. CRIAR SUB-ISSUE

```graphql
mutation {
  issueCreate(input: {
    title: "Titulo da sub-issue"
    teamId: "TEAM_ID"
    parentId: "PARENT_ISSUE_ID"
    stateId: "TODO_STATE_ID"
    assigneeId: "USER_ID"
  }) {
    issue { id identifier title }
  }
}
```

### 6. COMENTAR EM ISSUE

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

### 7. BUSCAR ISSUE POR IDENTIFIER

```graphql
{
  issueSearch(query: "IA-42", first: 1) {
    nodes {
      id identifier title description
      state { id name type }
      assignee { id name }
      labels { nodes { id name } }
      priority estimate dueDate
      project { name }
      projectMilestone { name }
      team { id key }
      children { nodes { identifier title state { name } } }
      comments(first: 10) { nodes { body createdAt user { name } } }
    }
  }
}
```

---

## Labels Conhecidas

| Label | ID |
|-------|----|
| Claude | `6dad8eed-291b-413b-9bfc-524e7aae0521` |
| Frontend | `74550db2-01cb-4da8-b6d0-13d4507427d7` |
| Backend | `c430dcd3-6b98-4e84-8101-489f6362c539` |
| frontend | `27e77b77-aa4a-41ec-b8fe-bd0a9b86b58c` |
| backend | `7bcc0759-f2a7-4184-b4f7-df2256f1eeb5` |
| ai | `66de6fae-5f2f-46f8-af7f-72dabefb20fc` |
| devops | `e47f1131-2f62-4ec2-ab19-5a1d93b06834` |
| Feature | `d046098f-3937-4a28-bf19-57082d9bff71` |
| Improvement | `3f2c540f-923b-4a4b-9bf1-69e61c3be161` |
| Bug | `0fab8687-157d-4d07-bddc-f68a3f1fd887` |

---

## API Reference

- Endpoint: `https://api.linear.app/graphql`
- Auth: `Authorization: {LINEAR_API_KEY}`
- Metodo: POST com body JSON `{"query": "...", "variables": {...}}`

## Convencao Git (ao trabalhar em tasks)

- Branch: `feat/{IDENTIFIER}-{slug}` | `fix/{IDENTIFIER}-{slug}`
- Commit: `feat: descricao [{IDENTIFIER}]`
- PR: inclui `Closes {IDENTIFIER}` no body

## Common Mistakes
- Tentar operar sem API key → PARAR e pedir para chamar o manager
- Mover direto para Done pulando In Review → NUNCA
- Mover de In Review para Done → SOMENTE humano
- Esquecer label Claude em tasks feitas pelo Claude Code
- Esquecer comentario ao mover para In Review
- Usar `labelIds` sem consultar labels existentes (sobrescreve tudo)
- Usar `parent_id` em vez de `parentId` para sub-issues
