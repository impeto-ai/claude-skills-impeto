---
name: linear-work
description: Operational skill for day-to-day Linear task management (v2 — templates obrigatorios). View personal tasks, move states, create issues, add comments. Activates for "linear-work", "minhas tasks", "mover task", "criar issue", "comentar issue", "atualizar linear".
chain: none
---

# Linear Work - Operacao Diaria (v2.1 — templates + Solicitante no texto)

Skill operacional pro dia-a-dia do dev. Foco em tasks pessoais, movimentacao de estados, criacao de issues **sempre via template**, comentarios.

> **v2.1 (2026-04-27) — MUDANCA IMPORTANTE:** removido o conceito de label `Source/<slug>`. O **solicitante** agora vai SEMPRE no texto do description, no campo `**Solicitante:**` que o template ja traz. NAO crie labels `Source/*` — o checkbox `Reportar` ja e suficiente como sinal pro webhook (n8n).

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

**IDs de states por team:** ver [`../_linear-shared/state-ids.md`](../_linear-shared/state-ids.md) (single source of truth).

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

### 4. CRIAR ISSUE (v2.1 — SEMPRE via template + Solicitante no texto)

**REGRAS:**
1. **SEMPRE escolher um dos 7 templates** (Feature/Bug/Hotfix/Refactor/Spike/Report/Knowledge). Se nao da pra inferir do contexto, perguntar.
2. **SEMPRE preencher `**Solicitante:**` no texto do description** (campo que o template ja traz). NAO criar label `Source/*`.
3. **SEMPRE perguntar "Reportar quando concluido?"** antes de criar — checkbox no description, sem label associada.
4. **UMA pergunta consolidada multi-campo** — nao 5-6 perguntas separadas.

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
- Solicitante: nome (vai no texto do description, NAO em label)
- Beneficiario: nome ou cliente (vai no texto do description)
- Reportar quando concluido? (s/n)  — checkbox no description
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
- **NAO incluir `Source/*` label** — esse padrao foi descontinuado em v2.1. Solicitante vai SEMPRE no texto do description.

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

#### Step D — Pos-criacao: preencher description (Solicitante + Reportar)

Apos `issueCreate`, o template aplica um description com placeholders vazios. Voce precisa preencher 3 campos do markdown e fazer um `issueUpdate`:

1. `**Solicitante:**` → nome da pessoa (ex: `Clodoaldo`)
2. `**Beneficiário:**` → cliente, time ou pessoa beneficiada (ex: `Innovagro / Mesa`)
3. `- [ ] Reportar` → trocar pra `- [x] Reportar` SE o usuario respondeu Reportar=sim. Se respondeu nao, deixa desmarcado.

**Mutation:**
```graphql
mutation {
  issueUpdate(id: "ISSUE_ID", input: {
    description: "{description completo do template, com Solicitante/Beneficiario preenchidos e checkbox Reportar marcado se aplicavel}"
  }) {
    issue { identifier description }
  }
}
```

**NAO criar label `Source/*`.** O nome do solicitante vai SO no texto. O sinal pro webhook (n8n) eh apenas o checkbox `[x] Reportar`.

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

## Templates, Type/* labels e outras labels

**Single source of truth:** [`../_linear-shared/templates.md`](../_linear-shared/templates.md)

Inclui: 7 issue templates (Feature/Bug/Hotfix/Refactor/Spike/Report/Knowledge), 2 project templates, Type/* label IDs, label Claude, labels de componente.

### ~~Source/* (DESCONTINUADO em v2.1)~~

> Em v2.0 a skill criava labels `Source/<slug>` automaticamente. **Foi removido em v2.1.** O nome do solicitante agora vai SEMPRE no texto do description (campo `**Solicitante:**` que o template ja traz). NAO crie labels novas.

---

## Validacao Pre-Criacao (v2 — checklist obrigatorio)

Antes de chamar `issueCreate`, validar:

- [ ] Template escolhido (1 dos 7)?
- [ ] Solicitante / Beneficiario sera preenchido NO TEXTO do description (NAO via label `Source/*`)?
- [ ] Pergunta "Reportar quando concluido?" feita ao usuario?
- [ ] Type/* label correspondente no labelIds (se passar labelIds)?
- [ ] Se Hotfix: dueDate definido?
- [ ] Title claro e especifico (verbo imperativo + objeto)?
- [ ] Plano de fazer `issueUpdate` pos-criacao pra preencher Solicitante + Beneficiario + checkbox Reportar?

Se algum FALHAR e usuario insistir: PARAR e pedir confirmacao explicita ("Quer mesmo criar issue sem Type? Vai ficar fora dos relatorios.").

---

## API Reference

- Endpoint: `https://api.linear.app/graphql`
- Auth: `Authorization: {LINEAR_API_KEY}`
- Metodo: POST com body JSON `{"query": "...", "variables": {...}}`

## Workflow Linear ↔ Git/GitHub (OBRIGATORIO)

**Conceito-chave:** integracao nativa Linear-GitHub move a issue automaticamente quando:
- Branch criada com nome contendo IDENTIFIER → confirma `In Progress`
- PR ready for review → move pra `In Review`
- **PR merged → move pra `Done` automaticamente** (gate humano ja feito no merge)

**Pra integracao funcionar, o agent DEVE seguir o fluxo:**

```
1. Issue ja existe no Linear (criada antes pelo PM/CTO/skill linear-pm)
2. Agent move issue pra In Progress (operacao 2 desta skill)
3. Agent cria branch no formato:
   {usuario}/{identifier-lowercase}-{slug}
4. Commits citam {IDENTIFIER} no final: "tipo(scope): descricao ({IDENTIFIER})"
5. Ao abrir PR:
   - Title: "[{IDENTIFIER}] tipo: descricao"
   - Body: PRIMEIRA linha "Closes {IDENTIFIER}" (magic word)
   - Draft inicialmente, depois "Ready for review" → Linear move pra In Review
6. Merge → Linear fecha issue automaticamente
```

**TODOS os valores sao DINAMICOS, derivados em runtime:**
- `{IDENTIFIER}` ← `issue.identifier` retornado pela API Linear. Traz o team key correto (qualquer team do workspace). NUNCA hardcode `IA-`, `WFW-`, `IAP-` etc.
- `{usuario}` ← primeiro nome de `viewer.name`, lowercase, sem acento. Funciona pra qualquer user que estiver com a API key.
- `{slug}` ← `issue.title` em kebab-case, sem acento, max ~50 chars.

**Magic words aceitas (qualquer uma fecha a issue no merge):**
`Closes {IDENTIFIER}` · `Fixes {IDENTIFIER}` · `Resolves {IDENTIFIER}` · `Implements {IDENTIFIER}`

**Detalhes completos, exemplos, comandos `gh` e troubleshooting:** ver [git-workflow.md](git-workflow.md)

**Template de PR body pronto:** ver [templates/pr-body.md](templates/pr-body.md)

## Common Mistakes
- Tentar operar sem API key → PARAR
- Mover direto pra Done pulando In Review → NUNCA
- Mover de In Review pra Done sem aprovacao humana
- Esquecer label Claude em tasks feitas pelo Claude Code
- Esquecer comentario ao mover pra In Review
- Usar `labelIds` sem consultar labels existentes (sobrescreve tudo)
- (v2) **Criar issue sem `templateId`** — fora da disciplina v2
- (v2) **Esquecer pergunta "Reportar?"** — webhook n8n nao dispara
- (v2.1) **Criar label `Source/<slug>`** — descontinuado. Solicitante vai SO no texto do description
- (v2.1) **Esquecer de fazer `issueUpdate` pos-criacao** preenchendo Solicitante/Beneficiario/Reportar — issue fica com placeholders vazios
- (v2) Passar `labelIds` junto com `templateId` SEM incluir Type/* label correspondente — sobrescreve template label
- (v2) Pular pergunta consolidada e fazer 5-6 perguntas separadas — Soul axioma 5
- (v2.2) Criar branch com nome aleatorio (`fix-bug`, `feature-x`) sem IDENTIFIER — Linear nao linka, integracao quebra
- (v2.2) **Hardcodar team key (IA, WFW, IAP) na branch/PR** — sempre derivar do `identifier` da issue (cada issue traz o team key correto via `viewer.assignedIssues[].identifier`)
- (v2.2) Abrir PR sem `Closes {IDENTIFIER}` / `Fixes {IDENTIFIER}` no body — issue fica orfa, nao fecha no merge
- (v2.2) Mover issue pra Done manualmente quando ja existe PR aberto — deixa o merge fazer (evita race condition Linear↔GitHub)
