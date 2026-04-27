---
name: linear-pm
description: Use when creating, managing, or organizing tasks in Linear (v2 — issue templates obrigatorios + project templates Software Dev / AI Dev). Activates for "linear", "criar task", "criar projeto", "milestone", "issue", "sub-issue", "criar epic", "backlog linear", "mover task", "review task".
chain: none
---

# Linear PM - Gestao de Projetos via API (v2.1 — templates + Solicitante no texto)

Skill autonoma pra criar e gerenciar projetos, milestones, issues e sub-issues no Linear via GraphQL API. **v2:** issue templates obrigatorios (1 dos 7) + project templates (Software Dev / AI Dev) ao criar projeto + Reportar gate.

> **v2.1 (2026-04-27):** removido o conceito de label `Source/<slug>`. O **solicitante** vai SEMPRE no texto do description (campo `**Solicitante:**` que o template ja traz). NAO crie labels `Source/*`.

## When to Use
- Criar projeto novo no Linear (escolhe template Software Dev ou AI Dev)
- Criar milestones (epicos) dentro de um projeto
- Criar issues (sempre via 1 dos 7 templates: Feature/Bug/Hotfix/Refactor/Spike/Report/Knowledge)
- Criar sub-issues dentro de uma issue
- Mover issues entre estados (gate humano em Review→Done)
- Consultar status de projeto/issues
- Documentar conclusao de tasks com comentarios detalhados
- NOT when: consultas simples de leitura (use Linear MCP)
- NOT when: operacoes no Airtable (use airtable-agile-pm)

## Hierarquia Padrao Impeto

```
Initiative (estrategico, ex: "Performar SGI & Agrino")
  └── Project (escopo fechado, ex: "Mix Alimentos - Agent de Churn")
        └── Milestone (= Epico, ex: "M1 - Foundation")
              └── Issue (= Story/Task, sempre via template)
                    └── Sub-issue (= Subtask)
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
| Impeto AI Partners | `c399b23d-f3dc-443a-ba92-43ffd7faad91` | IAP | Parcerias / Innovagro |

### Templates do Workspace (v2)

**Issue templates (workspace, todos teams herdam):**

| Template | ID | Type/* | Priority |
|----------|----|----|----|
| Feature | `e682d84c-1e1c-40e7-bdd6-19853c4a577f` | Type/Feature | 3 |
| Bug | `7c547bce-b64b-46ef-8e76-80ca5b234637` | Type/Bug | 2 |
| Hotfix | `8357bb00-4618-4474-9351-5a95c47d572e` | Type/Hotfix | 1 |
| Refactor | `85878d0f-b983-4ce7-9662-b15546c0494f` | Type/Refactor | 4 |
| Spike | `f9c21b5c-6a74-4b53-a4cb-94fa038e3219` | Type/Spike | 3 |
| Report | `bc934845-83d0-4b7d-b613-8b64425498b7` | Type/Report | 3 |
| Knowledge | `3ca2d511-8c86-432a-b374-2daef63f15ce` | Type/Knowledge | 4 |

**Project templates (workspace, type=project):**

| Template | ID | Use case |
|----------|----|----------|
| Software Development | `2cfa380e-7552-4eee-b50f-a56a960054e2` | Codigo tradicional (Next.js, FastAPI, Supabase, dashboards) |
| AI Development | `e4265043-9517-455c-8866-837f01404adc` | Agentes AI / LLM / Pydantic AI / multi-provider |

**Type/* label IDs (usar junto com templateId em issueCreate):**

| Label | ID |
|-------|----|
| Type/Feature | `d046098f-3937-4a28-bf19-57082d9bff71` |
| Type/Bug | `0fab8687-157d-4d07-bddc-f68a3f1fd887` |
| Type/Hotfix | `e05992d5-f5ae-45e6-8f2f-27ab187157b3` |
| Type/Refactor | `860bbe5a-c1d5-4104-bbe2-15c899f309db` |
| Type/Spike | `dc6567c6-b5a8-4cb6-a742-1b078cc5e54f` |
| Type/Report | `1018beba-b5d4-4a96-8766-d6f18c4c3df9` |
| Type/Knowledge | `3a4669b3-4b92-4b0d-a37d-a5683c186463` |

---

## WORKFLOW OBRIGATORIO

### Estados e Transicoes

```
┌──────────┐    ┌──────────┐    ┌────────────┐    ┌──────────┐    ┌──────┐
│ Backlog  │───▶│  To Do   │───▶│In Progress │───▶│  Review  │───▶│ Done │
└──────────┘    └──────────┘    └────────────┘    └──────────┘    └──────┘
                                                   🔒 GATE HUMANO
```

### Regras INVIOLAVEIS (v2)

1. **NUNCA pular Review** — toda issue que sai de "In Progress" vai pra "In Review" obrigatoriamente
2. **NUNCA mover de Review → Done automaticamente** — somente humano (Joao = gate executive)
3. **Ao mover pra Review:** OBRIGATORIO comentario detalhado (ver secao Comentarios)
4. **Tag Claude:** se task feita por Claude Code, OBRIGATORIO label `Claude` na issue
5. **(v2) Taxonomia obrigatoria:** issue criada SEMPRE via `templateId` (1 dos 7) + Type/* label correspondente
6. **(v2.1) Solicitante no texto:** SEMPRE preencher `**Solicitante:**` no description (campo do template). NAO criar label `Source/*`. Tambem perguntar "Reportar quando concluido?" e marcar checkbox `[x] Reportar` se sim.
7. **(v2) State Ownership (foco IAP/Innovagro):**
   - Emanuel Montenegro = triagem (Backlog/Todo → In Progress)
   - Danilo Saraiva = review tecnico (In Progress → In Review)
   - Joao Nascimento = gate humano executive (In Review → Done — raro)
   - IA/WFW: Joao decide quem move
8. **Transicoes validas:**
   - Backlog → To Do (priorizada)
   - To Do → In Progress
   - In Progress → Review (trabalho concluido)
   - Review → Done (somente humano)
   - Review → In Progress (revisao reprovou)
   - Qualquer → Cancelled (com justificativa)

### Workflow States (consultar IDs antes de usar)

```graphql
{ team(id: "TEAM_ID") { states { nodes { id name type } } } }
```

> **IMPORTANTE:** Sempre consultar states REAIS do team via query antes de criar/mover. IDs mudam entre teams. Tabelas em [linear-work](../linear-work/SKILL.md).

---

## COMENTARIOS OBRIGATORIOS

### Quando Adicionar Comentario
- **Sempre** ao mover issue pra Review
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

### Mutation pra Comentar

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

## LABEL CLAUDE (obrigatoria pra tasks feitas pelo Claude Code)

| Label | ID | Uso |
|-------|----|----|
| Claude | `6dad8eed-291b-413b-9bfc-524e7aae0521` | Tasks executadas por Claude Code |

### Adicionar Label a Issue

```graphql
mutation {
  issueUpdate(id: "ISSUE_ID", input: {
    labelIds: ["EXISTING_LABELS...", "CLAUDE_LABEL_ID"]
  }) {
    issue { identifier labels { nodes { name } } }
  }
}
```

> **Cuidado:** `labelIds` SUBSTITUI todas as labels. Sempre consultar existentes da issue antes, depois passar array completo.

---

## Mutations Reference

### 1. Criar Projeto (v2 — sempre via project template)

**Pergunta obrigatoria ao user:** "Software Development ou AI Development?"

```graphql
mutation {
  projectCreate(input: {
    name: "Nome do Projeto"
    description: "Descricao curta (max 255 chars)"
    teamIds: ["TEAM_ID"]
    templateId: "<software_dev_or_ai_dev_id>"   # OBRIGATORIO v2
    state: "started"
    targetDate: "2026-MM-DD"
  }) {
    project { id name }
  }
}
```

**Templates:**
- Software Development: `2cfa380e-7552-4eee-b50f-a56a960054e2` (5 milestones M0-M4)
- AI Development: `e4265043-9517-455c-8866-837f01404adc` (5 milestones M0-M4)

**Linear cria os milestones automaticamente.** Nao precisa criar manualmente.

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

> Initiatives ativas (consultar via `query { initiatives { nodes { id name owner { name } } } }`). Existem ~10 por tema.

### 3. Criar Milestone Adicional (raro — templates ja criam M0-M4)

```graphql
mutation {
  projectMilestoneCreate(input: {
    name: "M5 — Nome do Epico Extra"
    projectId: "PROJECT_ID"
    targetDate: "2026-MM-DD"   # recomendado obrigatorio v2
  }) {
    projectMilestone { id name }
  }
}
```

### 4. Criar Issue (v2 — SEMPRE via templateId)

**Pergunta consolidada UNICA ao user (Soul axioma 5):**

```
Vou criar issue com template: {Template (Feature/Bug/Hotfix/Refactor/Spike/Report/Knowledge)}

Confirme/preencha:
- Titulo: ?
- Team: IA / IAP / WFW
- Project: {listar ativos}, ou outro?
- Milestone: {listar do project}, ou nenhum?
- Estimate (1/2/3/5/8/13): ?
- Due date: ? (obrigatorio se Hotfix)
- Solicitante / Beneficiario: nome (vai NO TEXTO do description, NAO em label)
- Reportar quando concluido? (s/n) — checkbox no description
- Atribuir a: viewer (default), ou outro?
```

**Mutation:**

```graphql
mutation {
  issueCreate(input: {
    title: "Titulo claro e especifico"
    teamId: "TEAM_ID"
    templateId: "<TEMPLATE_ID>"            # OBRIGATORIO v2
    projectId: "PROJECT_ID"
    projectMilestoneId: "MILESTONE_ID"
    estimate: 3
    dueDate: "2026-MM-DD"
    assigneeId: "USER_ID"
    labelIds: [
      "<TYPE_LABEL_ID>",                    # OBRIGATORIO incluir Type/* do template
      "<COMPONENT_LABEL_ID>"                # opcional
      # NAO usar `Source/*` — descontinuado em v2.1
    ]
  }) {
    issue { id identifier title url }
  }
}
```

**Priority:** vem do template (Bug=2, Hotfix=1, Feature/Spike/Report=3, Refactor/Knowledge=4). Override so se necessario via `priority: N`.

**ATENCAO sobre `labelIds` + `templateId`:**
- Linear behavior testado: `labelIds` SOBRESCREVE labels do template.
- Solucao: SEMPRE incluir `<TYPE_LABEL_ID>` no array junto com extras.
- Se nao precisa de extras, omitir `labelIds` (template aplica Type/* sozinho).

**Pos-criacao (SEMPRE):**

Apos `issueCreate`, fazer `issueUpdate` pra preencher os campos do template no description:
1. `**Solicitante:**` → nome (ex: `Clodoaldo`)
2. `**Beneficiário:**` → cliente, time ou pessoa
3. `- [ ] Reportar` → trocar pra `- [x] Reportar` SE Reportar=sim

```graphql
mutation {
  issueUpdate(id: "ISSUE_ID", input: {
    description: "{description completo do template, com Solicitante/Beneficiario preenchidos e checkbox Reportar marcado se aplicavel}"
  }) { issue { identifier description } }
}
```

> **NAO use `Source/<slug>` label.** Foi descontinuado em v2.1. Solicitante vai SOMENTE no texto do description. O webhook (n8n) usa apenas o checkbox `[x] Reportar` como sinal.

### 5. Criar Sub-issue

Sub-issues geralmente herdam contexto da pai. Template e opcional.

```graphql
mutation {
  issueCreate(input: {
    title: "Nome da sub-issue"
    teamId: "TEAM_ID"
    parentId: "PARENT_ISSUE_ID"
    stateId: "STATE_ID"
    templateId: "<template_id>"   # opcional
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

### Listar Initiatives Ativas (v2)
```graphql
{
  initiatives(filter: { status: { eq: "Active" } }) {
    nodes { id name status owner { name } }
  }
}
```

### Listar Templates do Workspace
```graphql
{
  organization {
    templates {
      nodes { id name type }
    }
  }
}
```

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
        priority estimate dueDate
      }
    }
  }
}
```

### Buscar Issue por Identifier
```graphql
{
  issueSearch(query: "IA-123", first: 1) {
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
      nodes { id name targetDate sortOrder }
    }
  }
}
```

### Consultar Labels
```graphql
{
  issueLabels(first: 200) {
    nodes { id name color parent { name } }
  }
}
```

---

## Workflow Autonomo: Mover Issue pra Review

Quando task concluida pelo Claude Code, executar TODOS estes passos:

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

### Passo 2: Consultar state "In Review" do team
```graphql
{ team(id: "TEAM_ID") { states { nodes { id name type } } } }
```

### Passo 3: Atualizar issue (estado + label Claude)
```graphql
mutation {
  issueUpdate(id: "ISSUE_ID", input: {
    stateId: "REVIEW_STATE_ID"
    labelIds: ["...labels_existentes...", "6dad8eed-291b-413b-9bfc-524e7aae0521"]
  }) {
    issue { identifier state { name } labels { nodes { name } } }
  }
}
```

### Passo 4: Adicionar comentario detalhado
(Ver template em "COMENTARIOS OBRIGATORIOS")

### Passo 5: Informar usuario
```
✅ Issue {IDENTIFIER} movida para In Review
   - Label "Claude" adicionada
   - Comentario detalhado adicionado
   - ⏳ Aguardando revisao humana (Danilo / Joao)
```

---

## Workflow Padrao pra Novo Projeto (v2 — via project template)

1. **Perguntar ao user (UMA mensagem):**
   - Nome do projeto
   - Team (IA/IAP/WFW)
   - **Software Development ou AI Development?** (escolhe project template)
   - Descricao curta
   - Initiative pai (opcional)
   - Target date (opcional)

2. **Criar projeto com `templateId`:**
   ```graphql
   mutation {
     projectCreate(input: {
       name: "..."
       teamIds: ["..."]
       templateId: "2cfa380e-..." OR "e4265043-..."
       description: "..."
       state: "started"
     }) { project { id name } }
   }
   ```

3. **Linear automaticamente cria 5 milestones (M0-M4) baseados no template.**

4. **(Opcional)** Linkar a Initiative existente:
   ```graphql
   mutation {
     initiativeToProjectCreate(input: {
       initiativeId: "<initiative_id>"
       projectId: "<new_project_id>"
     }) { initiativeToProject { id } }
   }
   ```

5. **(Opcional)** Adicionar issues iniciais por milestone (sempre via template):
   - Pra cada milestone, perguntar quais issues
   - Cada issue criada com `templateId` correspondente (Feature/Bug/Spike/etc)

6. **Resumir** ao user com tabela do que foi criado.

---

## Convencao GitHub

### Branch
```
feat/{IDENTIFIER}-{slug}     → feature
fix/{IDENTIFIER}-{slug}      → bugfix
chore/{IDENTIFIER}-{slug}    → infra/devops
```
Exemplo: `feat/IA-124-configurar-api-key`

### Commit
```
feat: descricao curta [{IDENTIFIER}]
fix: corrigir bug [{IDENTIFIER}]
chore: configuracao [{IDENTIFIER}]
```
Exemplo: `feat: setup supabase auth [IA-111]`

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

## Validacao Pre-Criacao (v2 — checklist obrigatorio)

Antes de chamar `issueCreate`, garantir:

| Campo | Obrigatorio | Como validar |
|-------|-------------|--------------|
| `templateId` | sim | 1 dos 7 IDs |
| `<TYPE_LABEL_ID>` no labelIds | sim (se passar labelIds) | senao `templateId` aplica sozinho |
| `dueDate` | sim se Hotfix | regra: Hotfix sem dueDate = recusa |
| `Reportar?` perguntado ao user | **sim, sempre** | Checkbox `[x] Reportar` marcado no description se sim. NAO usar `Source/*` label. |
| `projectMilestoneId` | recomendado | issue ficar orfa do milestone e perda |

Antes de chamar `projectCreate`:

| Campo | Obrigatorio | Validacao |
|-------|-------------|-----------|
| `templateId` | **sim, v2** | Software Dev OU AI Dev |
| `teamIds` | sim | 1 dos 3 teams |

---

## Gotchas & Limites

- `description` do projeto: max **255 caracteres**
- `initiativeId` NAO funciona em `projectCreate` — usar `initiativeToProjectCreate` separado
- `parentId` (nao `parent_id`) pra sub-issues
- `labelIds` no update **SUBSTITUI** todas as labels — sempre consultar existentes antes
- Query complexity limit: **10000** — limitar `first: 100` e evitar campos aninhados demais
- Cycles no Linear sao automaticos por data (ativam quando data chega)
- **Segregacao:** Linear nao segrega por projeto, apenas por Team
- **(v2)** `templateId` em `issueCreate` aplica description + Type/* label + priority do template. Se passar `labelIds` JUNTO, sobrescreve labels — sempre incluir Type/* manualmente
- **(v2)** `templateId` em `projectCreate` cria milestones automaticamente — nao precisa criar manualmente

## Common Mistakes

- Esquecer de consultar states do team antes de criar issues (IDs mudam entre teams)
- Usar `parent_id` ao inves de `parentId`
- Description do projeto com mais de 255 chars (API rejeita)
- Criar issues sem `projectMilestoneId` (ficam orfas)
- Query GraphQL muito complexa (usar `first: 100`)
- Nao linkar initiative separadamente (nao e campo do projectCreate)
- **Pular o estado Review** — NUNCA fazer In Progress → Done direto
- **Mover pra Done sem aprovacao humana** — NUNCA, gate executive Joao
- **Esquecer de adicionar label Claude** quando task feita pelo Claude Code
- **Esquecer comentario detalhado** ao mover pra Review
- **Sobrescrever labels** usando `labelIds` sem consultar existentes
- **(v2) Criar issue sem `templateId`** — fora da disciplina v2, fora dos relatorios
- **(v2) Esquecer pergunta "Reportar quando concluido?"** — webhook n8n nao dispara
- **(v2.1) Criar label `Source/<slug>`** — descontinuado. Solicitante vai SO no texto do description
- **(v2.1) Esquecer `issueUpdate` pos-criacao** preenchendo Solicitante/Beneficiario/Reportar — issue fica com placeholders vazios
- **(v2) Passar `labelIds` junto com `templateId` SEM incluir Type/* correspondente** — sobrescreve template
- **(v2) Criar projeto sem `templateId`** — perde os 5 milestones automaticos
- **(v2) Fazer 5-6 perguntas separadas ao user** — Soul axioma 5: UMA pergunta consolidada
