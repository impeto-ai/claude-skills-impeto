---
name: linear-teams
description: Orquestra Agent Teams com Linear (v2 — issue templates obrigatorios). O lead agent atua como PM/PO, lê issues do Linear, spawna teammates pra executar, e atualiza Linear conforme progresso. Activates for "executar issues", "executar projeto linear", "montar time linear", "issues do linear", "sprint linear", "rodar sprint".
chain: none
---

# Linear Teams — PM/PO Agent com Agent Teams (v2 — templates)

O lead agent vira PM/PO: lê issues do Linear, planeja o time, spawna teammates, coordena execucao, atualiza Linear automaticamente.

**v2 mudanca chave:** todas as issues criadas pelos teammates DEVEM usar `templateId` (1 dos 7 templates workspace).

## Convencao de issues / labels / branches / commits

**Single source of truth:** [linear-pm/SKILL.md](../linear-pm/SKILL.md)

Esta skill foca em **orquestracao** (Agent Teams + fluxo PM). Para regras de criacao, comentarios obrigatorios, convencao git/PR, workflow states e templates, ver linear-pm.

## Hierarquia Impeto (resumo)

```
Initiative → Project → Milestone (Épico) → Issue (via template) → Sub-issue
```

O lead opera no nivel de **Project/Milestone**: lê issues de um milestone, distribui pra teammates.

## Workflow de estados (resumo — detalhe em linear-pm)

```
Backlog → To Do → In Progress → In Review → Done
                                  🔒 GATE HUMANO
```

- Teammates movem ate **In Review** — NUNCA ate Done
- Em IAP/Innovagro: Emanuel = entrada, Danilo = review, Joao = gate Done

---

## Fluxo completo

```
User: "executa as issues do projeto X no Linear"
       │
       ▼
FASE 0: Linear Init (carregar contexto + templates)
       │ → API key, projetos, issues, estados, IDs templates
       ▼
FASE 1: Discovery (ler issues do projeto)
       │ → Quais issues? Quem faz? Dependencias?
       ▼
FASE 2: Planejamento (mapear issues → teammates)
       │ → Apresentar plano ao usuario
       ▼
FASE 3: Criacao (TeamCreate + Agent por issue/grupo)
       │ → Cada teammate recebe suas issues + IDs de templates
       ▼
FASE 4: Coordenacao (SendMessage + Linear updates)
       │ → Issues movem: To Do → In Progress → In Review
       ▼
FASE 5: Encerramento (shutdown + relatorio)
       │ → Resumo no Linear + TeamDelete
```

---

## FASE 0: Linear Init (OBRIGATORIO)

Antes de qualquer coisa, executar `/linear-init` (ou seguir o fluxo dele):

### 0a. Verificar API key

`.env` no diretorio atual OU `~/.claude/.env`. Se nao encontrar → PARAR.

### 0b. Identificar usuario + projetos + templates (CRITICO v2)

**O viewer.id e o DONO da sessao.** Guardar como VIEWER_ID, passar pra cada teammate.
**IDs dos templates** (issue + project) tambem precisam ser carregados pra teammates usarem.

```graphql
{
  viewer {
    id name email
    assignedIssues(filter: { state: { type: { nin: ["completed", "canceled"] } } }, first: 50) {
      nodes { id identifier title state { name type } project { name } }
    }
  }
  organization {
    templates { nodes { id name type } }
  }
}
```

### 0c. Perguntar qual projeto/milestone executar

```
LINEAR CONTEXT LOADED (v2 — com templates)

Projetos ativos:
  1. Mix Alimentos - Agent de Churn (IA) — 12 issues abertas
  2. NFAI - Emissor NF-e (IA) — 8 issues abertas
  3. Khrona - Workflow (WFW) — 5 issues abertas

Templates disponiveis: Feature, Bug, Hotfix, Refactor, Spike, Report, Knowledge

Qual projeto executar? (ou milestone especifico?)
```

---

## FASE 1: Discovery (ler issues do projeto)

### 1a. Buscar issues do projeto/milestone escolhido

```graphql
{
  project(id: "PROJECT_ID") {
    name
    projectMilestones { nodes { id name sortOrder } }
    issues(filter: { state: { type: { nin: ["completed", "canceled"] } } }, first: 100) {
      nodes {
        id identifier title description
        state { id name type }
        priority estimate dueDate
        assignee { id name }
        projectMilestone { name }
        labels { nodes { id name } }
        team { id key }
        children { nodes { id identifier title state { name type } assignee { name } } }
      }
    }
  }
}
```

### 1b. Classificar issues

- **Prontas pra executar** (To Do, sem dependencia bloqueante)
- **Em progresso** (ja comecadas, talvez precisem continuar)
- **Bloqueadas** (dependem de outra issue)
- **Fora de escopo** (Backlog que nao entrou no sprint)

### 1c. Identificar stacks/dominios

Agrupar issues por:
- Labels Type/* (Feature/Bug/Refactor/etc — se ja foi taggeada via template)
- Labels componente (frontend, backend, ai, devops)
- Diretorios que vao ser tocados
- Dependencias entre issues

---

## FASE 2: Planejamento (mapear issues → teammates)

Apresentar ao usuario:

```markdown
## Plano de Execucao — {Projeto}

**Issues selecionadas:** {N}
**Teammates necessarios:** {N}

### Mapeamento

| Teammate | Tipo | Issues | Labels | Modelo |
|---|---|---|---|---|
| frontend-dev | general-purpose | IA-42 (Type/Feature), IA-45 (Type/Bug) | frontend | sonnet |
| backend-dev | general-purpose | IA-43 (Type/Feature), IA-46 (Type/Refactor) | backend | sonnet |
| ai-dev | general-purpose | IA-44 (Type/Spike) | ai | opus |

### Issues por teammate

**frontend-dev:**
  - IA-42: Implementar tela de dashboard (P2, 5pts) [Type/Feature]
  - IA-45: Fix responsivo mobile (P3, 2pts) [Type/Bug]

**backend-dev:**
  - IA-43: Criar API de relatorios (P2, 8pts) [Type/Feature]
  - IA-46: Endpoint export CSV (P3, 3pts) [Type/Refactor]

**ai-dev:**
  - IA-44: Spike modelo de churn (P1, 13pts) [Type/Spike] ← Opus por complexidade

### Dependencias
- IA-46 depende de IA-43 (export precisa da API)

### File Ownership
- frontend-dev: src/app/, src/components/
- backend-dev: src/api/, src/services/
- ai-dev: src/agents/, src/models/

Confirma? (posso ajustar antes de criar)
```

---

## FASE 3: Criacao (TeamCreate + Linear → Tasks → Teammates)

### 3a. Criar time

```
TeamCreate({
  team_name: "{projeto}-sprint",
  description: "Execucao de {N} issues do {projeto}"
})
```

### 3b. Criar Tasks mapeadas das issues do Linear

Pra CADA issue do Linear, criar uma Task local:

```
TaskCreate({
  subject: "{IDENTIFIER}: {titulo}",
  description: "Issue Linear: {identifier}\nPrioridade: {priority}\nEstimate: {estimate}\nType: {label_type}\nDescricao: {description}\n\nCriterios de aceite: completar a issue e mover pra In Review no Linear.",
  activeForm: "Executando {identifier}"
})
```

Se issue A bloqueia issue B:
```
TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })
```

### 3c. Spawnar teammates (v2 — prompt com IDs de templates)

Pra CADA teammate do plano:

```
Agent({
  description: "Spawn {teammate-name}",
  subagent_type: "general-purpose",
  team_name: "{projeto}-sprint",
  name: "{teammate-name}",
  model: "{model}",
  prompt: "Voce e o teammate '{name}' do time '{projeto}-sprint'.

## Seu Projeto
- Diretorio: {cwd}
- Stack: {stack}

## Suas Issues (do Linear)
{lista de issues com identifier, titulo, descricao, estimate, type label}

## File Ownership
Voce SO edita: {dirs}
NAO toque em: {dirs dos outros}

## Workflow OBRIGATORIO
1. TaskList() → ver suas tarefas
2. TaskUpdate(taskId, status: 'in_progress') ao comecar
3. Implementar a issue
4. Ao terminar CADA issue, executar fluxo Linear:
   a. Mover issue pra 'In Review' via GraphQL:
      - Consultar state 'In Review' do team
      - Consultar labels existentes da issue
      - issueUpdate com stateId + labelIds (manter existentes + adicionar 'Claude')
      - commentCreate com relatorio detalhado (template em /linear-pm)
5. TaskUpdate(taskId, status: 'completed')
6. TaskList() → proxima tarefa

## Se PRECISAR criar issue nova durante execucao (Bug encontrado, Spike, etc):
- SEMPRE usar templateId (1 dos 7). Tabela completa em /linear-pm.
- Pre-feridos pra teammate dev:
  * Bug encontrado: templateId=7c547bce-b64b-46ef-8e76-80ca5b234637 (Type/Bug)
  * Spike de pesquisa: templateId=f9c21b5c-6a74-4b53-a4cb-94fa038e3219 (Type/Spike)
  * Refactor escopo extra: templateId=85878d0f-b983-4ce7-9662-b15546c0494f (Type/Refactor)
- Mutation: issueCreate(input: { title, teamId, templateId, parentId? }) — Linear popula description + Type/* label + priority do template
- SEMPRE perguntar ao lead via SendMessage 'Reportar quando concluido?' antes de criar — nao crie sozinho

## API Linear
- Endpoint: https://api.linear.app/graphql
- Auth: Authorization: {LINEAR_API_KEY do .env}
- Label Claude ID: 6dad8eed-291b-413b-9bfc-524e7aae0521

## Template de comentario ao mover pra Review
(Ver template completo em /linear-pm/SKILL.md secao COMENTARIOS OBRIGATORIOS)

## Regras
- NUNCA mover pra Done — so ate In Review
- SEMPRE adicionar label Claude
- SEMPRE comentar ao mover pra Review com insights (Descobertas/Riscos/Sugestoes/Conexoes)
- Se bloqueado, avise o lead via SendMessage"
})
```

### 3d. Atribuir tasks

```
TaskUpdate({ taskId: "1", owner: "frontend-dev" })
TaskUpdate({ taskId: "2", owner: "backend-dev" })
```

---

## FASE 4: Coordenacao (PM/PO ativo)

O lead e **PM/PO puro**. Nao coda. Coordena.

### Monitorar

- Mensagens dos teammates chegam automaticamente
- TaskList() pra ver progresso geral
- Se teammate termina issue → verificar se Linear foi atualizado

### Verificar updates no Linear

Periodicamente (quando teammates reportam conclusao):

```graphql
{
  project(id: "PROJECT_ID") {
    issues(first: 100) {
      nodes {
        identifier title
        state { name }
        labels { nodes { name } }
        comments(last: 1) { nodes { body createdAt } }
      }
    }
  }
}
```

### Desbloquear

- Issue A termina → TaskUpdate desbloqueia Task B automaticamente
- SendMessage pro teammate de B: "IA-43 concluida, pode comecar IA-46"

### Reportar progresso ao usuario

```
━━━ PROGRESSO DO SPRINT ━━━━━━━━━━━━━━━━

  ✅ IA-42: Tela dashboard        → In Review (frontend-dev)
  🔄 IA-43: API relatorios        → In Progress (backend-dev)
  ⏳ IA-44: Spike modelo churn    → In Progress (ai-dev)
  🔒 IA-46: Export CSV             → Blocked by IA-43

  Completas: 1/4 | Em progresso: 2/4 | Blocked: 1/4
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## FASE 5: Encerramento

### 5a. Verificar completude

- TaskList() → todas completed?
- Verificar no Linear: todas as issues em "In Review"?

### 5b. Relatorio final no Linear

Criar comentario no projeto ou milestone:

```markdown
## Sprint Report — {data}

### Executado por Agent Team ({N} teammates)

| Issue | Type | Teammate | Status | Estimate |
|---|---|---|---|---|
| IA-42 | Feature | frontend-dev | In Review | 5pts |
| IA-43 | Feature | backend-dev | In Review | 8pts |
| IA-44 | Spike | ai-dev | In Review | 13pts |
| IA-46 | Refactor | backend-dev | In Review | 3pts |

**Total:** {N} issues, {sum} pontos
**Todas em In Review** — aguardando aprovacao humana (Danilo / Joao).
```

### 5c. Shutdown teammates

```
SendMessage({ to: "{name}", message: { type: "shutdown_request", reason: "Sprint concluido" } })
```

Pra CADA teammate. Depois:

```
TeamDelete({})
```

### 5d. Resumo final ao usuario

```
━━━ SPRINT CONCLUIDO ━━━━━━━━━━━━━━━━━━

  4 issues executadas → In Review
  3 teammates encerrados
  0 issues com problema

  Proximo passo: revisar no Linear e mover pra Done.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Insights obrigatorios — o que o Claude DEVE reportar

Ao concluir CADA issue, teammate DEVE incluir no comentario pelo menos 2 insights de cada categoria:

**💡 Descobertas (o que aprendeu):**
- Padroes existentes no codigo que seguiu
- Convencoes que identificou e respeitou
- Codigo relacionado que pode ser impactado

**⚠️ Riscos (o que pode dar errado):**
- Edge cases nao cobertos
- Performance em escala
- Dependencias frageis
- Dados que podem estar inconsistentes

**📊 Sugestoes (o que poderia melhorar):**
- Refatoracoes que fariam sentido (criar issue Type/Refactor!)
- Testes que deveriam existir
- Documentacao que esta faltando
- Abstracoes que poderiam ser criadas

**🔗 Conexoes (impacto em outras partes):**
- Outras issues que podem ser afetadas
- Componentes que compartilham logica
- APIs que consumidores dependem

Esses insights sao o **diferencial** — o revisor humano recebe nao so o codigo, mas a analise do Claude sobre o que fez e por que.

---

## Regras de Ouro

1. **Lead = PM/PO** — nunca coda, so coordena
2. **Linear e source of truth** — issues vem de la, updates voltam pra la
3. **NUNCA mover pra Done** — so ate In Review, humano aprova (Joao gate)
4. **SEMPRE label Claude** em issues feitas por teammates
5. **SEMPRE comentar** ao mover pra Review (template detalhado em /linear-pm)
6. **Teammates REAIS** — team_name + name, NUNCA run_in_background
7. **File ownership** — cada teammate edita seus arquivos
8. **Desbloquear via SendMessage** — quando dependencia resolve
9. **(v2) Issue criada por teammate SEMPRE via templateId** — 1 dos 7 templates
10. **(v2) Insights podem virar issue Type/Refactor ou Type/Spike** — teammate sugere, lead decide criar

## Anti-Patterns

| Errado | Correto |
|---|---|
| Lead coda | Lead coordena, delega tudo |
| Teammate move pra Done | So ate In Review |
| Ignora Linear | Atualiza Linear a cada issue concluida |
| Sem comentario no Review | Template completo obrigatorio |
| Sem label Claude | Sempre adicionar |
| Issues sem TaskCreate | Mapear 1:1 Linear issue → Task local |
| **(v2) Teammate cria issue sem templateId** | Sempre usar 1 dos 7 templates |
| **(v2) Lead esquece de passar IDs templates pro teammate** | FASE 3.3 inclui tabela de templates no prompt |
