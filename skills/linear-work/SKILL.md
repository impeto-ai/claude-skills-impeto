---
name: linear-work
description: Operational skill for day-to-day Linear task management (v2 — templates obrigatorios). View personal tasks, move states, create issues, add comments. Activates for "linear-work", "minhas tasks", "mover task", "criar issue", "comentar issue", "atualizar linear".
chain: none
---

# Linear Work - Operacao Diaria (v2 — templates + Reportar gate)

Skill operacional pro dia-a-dia do dev. Foco em tasks pessoais, movimentacao de estados, criacao de issues **sempre via template**, comentarios.

## When to Use
- Ver minhas tasks atuais
- Mover task entre estados (To Do → In Progress → In Review)
- Criar nova issue/sub-issue (sempre escolhe template)
- Adicionar comentario em issue
- Atualizar prioridade, estimate, due date
- NOT when: criar projetos/milestones (use /linear-pm)
- NOT when: apenas carregar contexto (use /linear-init)

---

## PASSO 0: VERIFICAR API KEY (OBRIGATORIO)

**ANTES DE QUALQUER COISA**, verificar `LINEAR_API_KEY`:

1. `.env` no diretorio atual
2. Senao, `~/.claude/.env`
3. Se nao encontrar:

```
⚠️  LINEAR_API_KEY nao encontrada!
Solicite ao manager (Joao - joao@impeto.ai).
Apos receber: crie .env com LINEAR_API_KEY=lin_api_XXXXX → /linear-init
```

**PARAR se nao encontrar.**

---

## IDENTIFICAR USUARIO (OBRIGATORIO)

```graphql
{ viewer { id name email } }
```

Guardar `viewer.id` — usar como `assigneeId` default em criacao de issues e como filtro em "minhas tasks".

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

**REGRAS INVIOLAVEIS (v2):**
- NUNCA pular "In Review" — In Progress → In Review, NUNCA direto pra Done
- NUNCA mover de In Review → Done — somente humano (Joao gate executive)
- Ao mover pra In Review: OBRIGATORIO comentario detalhado
- Se task feita pelo Claude Code: OBRIGATORIO label `Claude`

**State Ownership (v2 — papeis Innovagro/IAP):**
- **Emanuel Montenegro** = triagem (Backlog/Todo → In Progress)
- **Danilo Saraiva** = review tecnico (In Progress → In Review)
- **Joao Nascimento** = gate humano executive (In Review → Done — raro, geralmente Danilo fecha)
- IA/WFW: Joao decide quem move state (mais flexivel)

**IDs de states por team:**

| Team | Backlog | Todo | In Progress | In Review | Done | Canceled |
|------|---------|------|-------------|-----------|------|----------|
| IAP | `864e6d89` | `d9ee0a28` | `63d82e50` | `210d982d` | `782dfd8a` | `ec8f76dd` |
| WFW | `6a17e88b` | `73c302a8` | `ada57e06` | `375f55a8` | `dbb124d1` | `f5d62680` |
| IA  | `4e00167a` | `4e4c1171` | `08c23863` | `e23d1ccd` | `2fe9f7ed` | `1566587e` |

**IDs completos (referencia):**

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

**Mutation pra mover:**
```graphql
mutation {
  issueUpdate(id: "ISSUE_ID", input: {
    stateId: "NEW_STATE_ID"
  }) {
    issue { identifier title state { name } }
  }
}
```

### 3. MOVER PARA IN REVIEW (workflow especial)

Ao mover pra In Review, executar TODOS os passos:

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
   - Aguardando revisao humana (Danilo / Joao)
```

### 4. CRIAR ISSUE (v2 — SEMPRE via template + Reportar gate)

**REGRAS:**
1. **SEMPRE escolher um dos 7 templates** (Feature/Bug/Hotfix/Refactor/Spike/Report/Knowledge). Se nao da pra inferir do contexto, perguntar.
2. **SEMPRE perguntar "Reportar quando concluido?"** antes de criar.
3. **UMA pergunta consolidada multi-campo** — nao 5-6 perguntas separadas.

**Fluxo conversacional:**

#### Step A — Inferir ou perguntar template

Inferir do contexto se possivel:
- "fix", "quebrou", "erro" → Bug
- "implementar", "adicionar", "nova funcionalidade" → Feature
- "urgente prod parado" → Hotfix
- "limpar codigo", "renomear", "extrair" → Refactor
- "investigar", "POC", "spike" → Spike
- "relatorio", "dashboard", "analise" → Report
- "documentar", "ata reuniao", "transcricao" → Knowledge

Se nao da pra inferir → perguntar:
```
Qual template? Feature / Bug / Hotfix / Refactor / Spike / Report / Knowledge
```

#### Step B — Pergunta consolidada UNICA (Soul axioma 5)

Faz UMA mensagem so com tudo:

```
Vou criar issue com template: {Template}

Por favor confirme/preencha:
- Titulo: {sugerido baseado no contexto, ou "?"}
- Team: IAP / WFW / IA  (default: IA)
- Project: {listar 3 projetos ativos do team default}, ou outro?
- Milestone: {listar do project escolhido}, ou nenhum?
- Priority: {default do template — Bug=2, Hotfix=1, Feature/Spike/Report=3, Refactor/Knowledge=4}
- Estimate (1/2/3/5/8/13): ?
- Due date: ?  (opcional, mas obrigatorio se Hotfix)
- Solicitante: @quem? (do template)
- Beneficiario: @quem ou cliente:slug? (do template)
- Reportar quando concluido? (s/n)  ← novo
- Atribuir a: viewer (default), ou outro?
```

#### Step C — Mutation com templateId

```graphql
mutation {
  issueCreate(input: {
    title: "Titulo claro e especifico"
    teamId: "TEAM_ID"
    templateId: "<template_id>"          # populá description + priority + Type/* label
    projectId: "PROJECT_ID"               # opcional
    projectMilestoneId: "MILESTONE_ID"    # opcional
    estimate: 3
    dueDate: "2026-MM-DD"                 # obrigatorio se Hotfix
    assigneeId: "USER_ID"                 # default: viewer.id
    labelIds: ["<TYPE_LABEL_ID>", "<EXTRAS>..."]   # ATENÇÃO: ver nota abaixo
  }) {
    issue { id identifier title url }
  }
}
```

**ATENCAO sobre `labelIds` + `templateId`:**
- Linear comportamento testado: passar `labelIds` JUNTO com `templateId` **SOBRESCREVE** as labels do template (nao adiciona).
- Solucao: SEMPRE incluir o `Type/*` label correspondente no array, junto com extras.
- Se nao precisa de labels extras, OMITIR `labelIds` (deixa o template aplicar so o Type/*).

**Type/* label IDs (sempre incluir o do template escolhido):**

| Template | Type/* label ID |
|----------|-----------------|
| Feature | `d046098f-3937-4a28-bf19-57082d9bff71` |
| Bug | `0fab8687-157d-4d07-bddc-f68a3f1fd887` |
| Hotfix | `e05992d5-f5ae-45e6-8f2f-27ab187157b3` |
| Refactor | `860bbe5a-c1d5-4104-bbe2-15c899f309db` |
| Spike | `dc6567c6-b5a8-4cb6-a742-1b078cc5e54f` |
| Report | `1018beba-b5d4-4a96-8766-d6f18c4c3df9` |
| Knowledge | `3a4669b3-4b92-4b0d-a37d-a5683c186463` |

#### Step D — Pos-criacao: Reportar gate

Se usuario respondeu **Reportar = sim**:
1. Buscar/criar `Source/<slug>` label (slug = solicitante ou cliente)
2. Atualizar issue marcando o checkbox `Reportar` no description (descriptionData patch — ver nota abaixo) E adicionar `Source/<slug>` aos labelIds

Se usuario respondeu **Reportar = nao**:
- Deixa default (checkbox desmarcado, sem Source label)

**Mutation pra criar Source/<slug> se nao existe:**
```graphql
mutation {
  issueLabelCreate(input: {
    name: "Source/<slug>"
    color: "#f2994a"
    description: "Solicitante/beneficiario que dispara notificacao no Done"
  }) { issueLabel { id name } }
}
```

**Patch descriptionData pra marcar checkbox Reportar=true:**
- Mais simples: `issueUpdate(input: { description: "...new markdown com - [x] Reportar..." })`
- Linear re-converte markdown para descriptionData ProseMirror automaticamente.

#### Step E — Confirmar ao usuario

```
✅ Issue {IDENTIFIER} criada
   Template: {Template} | Priority: {N} | Reportar: {sim/nao}
   URL: {url}
```

### 5. CRIAR SUB-ISSUE (templateId opcional)

Sub-issues geralmente NAO precisam template (herdam contexto da pai). Mas se for Bug/Spike especifico, vale.

```graphql
mutation {
  issueCreate(input: {
    title: "Titulo da sub-issue"
    teamId: "TEAM_ID"
    parentId: "PARENT_ISSUE_ID"
    stateId: "TODO_STATE_ID"
    assigneeId: "USER_ID"
    templateId: "<template_id>"   # opcional
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

## Templates do Workspace (referencia rapida)

### Issue Templates (workspace, todos teams herdam)

| Template | ID | Type/* aplicado | Priority default |
|----------|----|----|----|
| Feature | `e682d84c-1e1c-40e7-bdd6-19853c4a577f` | Type/Feature | 3 |
| Bug | `7c547bce-b64b-46ef-8e76-80ca5b234637` | Type/Bug | 2 |
| Hotfix | `8357bb00-4618-4474-9351-5a95c47d572e` | Type/Hotfix | 1 |
| Refactor | `85878d0f-b983-4ce7-9662-b15546c0494f` | Type/Refactor | 4 |
| Spike | `f9c21b5c-6a74-4b53-a4cb-94fa038e3219` | Type/Spike | 3 |
| Report | `bc934845-83d0-4b7d-b613-8b64425498b7` | Type/Report | 3 |
| Knowledge | `3ca2d511-8c86-432a-b374-2daef63f15ce` | Type/Knowledge | 4 |

## Labels Conhecidas

### Type group (Type/*) — exclusivo, OBRIGATORIO via template
Ver tabela acima.

### Origem
| Label | ID |
|-------|----|
| Claude | `6dad8eed-291b-413b-9bfc-524e7aae0521` |

### Componente (legado — coexistem casing duplicado, cleanup pendente)
| Label | ID |
|-------|----|
| frontend | `27e77b77-aa4a-41ec-b8fe-bd0a9b86b58c` |
| backend | `7bcc0759-f2a7-4184-b4f7-df2256f1eeb5` |
| Frontend (cap, WFW) | `74550db2-01cb-4da8-b6d0-13d4507427d7` |
| Backend (cap, WFW) | `c430dcd3-6b98-4e84-8101-489f6362c539` |
| ai | `66de6fae-5f2f-46f8-af7f-72dabefb20fc` |
| devops | `e47f1131-2f62-4ec2-ab19-5a1d93b06834` |

### Source/* (criada on-demand quando Reportar=sim)
Pattern: `Source/<slug>` onde slug = `joao`, `mix-alimentos`, `meu-micro`, `agrofarm`, `estimulus`, etc.
Cor padrao: `#f2994a`. Criada via `issueLabelCreate` se nao existir.

---

## Validacao Pre-Criacao (v2 — checklist obrigatorio)

Antes de chamar `issueCreate`, validar:

- [ ] Template escolhido (1 dos 7)?
- [ ] Pergunta "Reportar quando concluido?" feita ao usuario?
- [ ] Se Reportar=sim: `Source/<slug>` label preparada?
- [ ] Type/* label correspondente no labelIds?
- [ ] Se Hotfix: dueDate definido?
- [ ] Title claro e especifico (verbo imperativo + objeto)?

Se algum FALHAR e usuario insistir: PARAR e pedir confirmacao explicita ("Quer mesmo criar issue sem Type? Vai ficar fora dos relatorios.").

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
- Tentar operar sem API key → PARAR
- Mover direto pra Done pulando In Review → NUNCA
- Mover de In Review pra Done sem aprovacao humana
- Esquecer label Claude em tasks feitas pelo Claude Code
- Esquecer comentario ao mover pra In Review
- Usar `labelIds` sem consultar labels existentes (sobrescreve tudo)
- (v2) **Criar issue sem `templateId`** — fora da disciplina v2
- (v2) **Esquecer pergunta "Reportar?"** — webhook n8n nao notifica solicitante
- (v2) Passar `labelIds` junto com `templateId` SEM incluir Type/* label correspondente — sobrescreve template label
- (v2) Pular pergunta consolidada e fazer 5-6 perguntas separadas — Soul axioma 5
