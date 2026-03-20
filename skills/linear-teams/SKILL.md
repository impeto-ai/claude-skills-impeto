---
name: linear-teams
description: Orquestra Agent Teams com Linear. O lead agent atua como PM/PO, lê issues do Linear, spawna teammates para executar, e atualiza o Linear conforme progresso. Activates for "executar issues", "executar projeto linear", "montar time linear", "issues do linear", "sprint linear", "rodar sprint".
chain: none
---

# Linear Teams — PM/PO Agent com Agent Teams

O lead agent vira PM/PO: lê issues do Linear, planeja o time, spawna teammates, coordena execução, e atualiza o Linear automaticamente.

## Fluxo completo

```
User: "executa as issues do projeto X no Linear"
       │
       ▼
FASE 0: Linear Init (carregar contexto)
       │ → API key, projetos, issues, estados
       ▼
FASE 1: Discovery (ler issues do projeto)
       │ → Quais issues? Quem faz o quê? Dependências?
       ▼
FASE 2: Planejamento (mapear issues → teammates)
       │ → Apresentar plano ao usuário
       ▼
FASE 3: Criação (TeamCreate + Agent por issue/grupo)
       │ → Cada teammate recebe suas issues
       ▼
FASE 4: Coordenação (SendMessage + Linear updates)
       │ → Issues movem: To Do → In Progress → In Review
       ▼
FASE 5: Encerramento (shutdown + relatório)
       │ → Resumo no Linear + TeamDelete
```

---

## FASE 0: Linear Init (OBRIGATÓRIO)

Antes de qualquer coisa, executar o fluxo do linear-init:

### 0a. Verificar API key

```
Procurar LINEAR_API_KEY em:
1. .env do diretório atual
2. ~/.claude/.env
```

Se não encontrar → PARAR e instruir o usuário.

### 0b. Identificar usuário + projetos

```graphql
{
  viewer {
    id name email
    assignedIssues(
      filter: { state: { type: { nin: ["completed", "canceled"] } } }
      first: 50
      orderBy: updatedAt
    ) {
      nodes {
        id identifier title
        state { id name type }
        priority estimate
        dueDate
        project { id name }
        projectMilestone { name }
        labels { nodes { id name } }
        team { id key }
        assignee { id name }
        children { nodes { identifier title state { name } } }
      }
    }
  }
}
```

### 0c. Perguntar qual projeto/milestone executar

```
LINEAR CONTEXT LOADED

Projetos ativos:
  1. Mix Alimentos - Agent de Churn (IA) — 12 issues abertas
  2. NFAI - Emissor NF-e (IA) — 8 issues abertas
  3. Khrona - Workflow (WFW) — 5 issues abertas

Qual projeto quer executar? (ou milestone específico?)
```

---

## FASE 1: Discovery (ler issues do projeto)

### 1a. Buscar issues do projeto/milestone escolhido

```graphql
{
  project(id: "PROJECT_ID") {
    name
    projectMilestones {
      nodes { id name sortOrder }
    }
    issues(
      filter: { state: { type: { nin: ["completed", "canceled"] } } }
      first: 100
    ) {
      nodes {
        id identifier title description
        state { id name type }
        priority estimate
        dueDate
        assignee { id name }
        projectMilestone { name }
        labels { nodes { id name } }
        team { id key }
        children {
          nodes {
            id identifier title
            state { id name type }
            assignee { name }
          }
        }
      }
    }
  }
}
```

### 1b. Classificar issues

Separar em:
- **Prontas pra executar** (To Do, sem dependência bloqueante)
- **Em progresso** (já começadas, talvez precisem continuar)
- **Bloqueadas** (dependem de outra issue)
- **Fora de escopo** (Backlog que não entrou no sprint)

### 1c. Identificar stacks/domínios

Agrupar issues por:
- Labels (frontend, backend, ai, devops)
- Diretórios que vão ser tocados
- Dependências entre issues

---

## FASE 2: Planejamento (mapear issues → teammates)

Apresentar ao usuário:

```markdown
## Plano de Execução — {Projeto}

**Issues selecionadas:** {N}
**Teammates necessários:** {N}

### Mapeamento

| Teammate | Tipo | Issues | Labels | Modelo |
|---|---|---|---|---|
| frontend-dev | general-purpose | IA-42, IA-45 | frontend | sonnet |
| backend-dev | general-purpose | IA-43, IA-46 | backend | sonnet |
| ai-dev | general-purpose | IA-44 | ai | opus |

### Issues por teammate

**frontend-dev:**
  - IA-42: Implementar tela de dashboard (P2, 5pts)
  - IA-45: Fix responsivo mobile (P3, 2pts)

**backend-dev:**
  - IA-43: Criar API de relatórios (P2, 8pts)
  - IA-46: Endpoint de export CSV (P3, 3pts)

**ai-dev:**
  - IA-44: Treinar modelo de churn (P1, 13pts) ← Opus por complexidade

### Dependências
- IA-46 depende de IA-43 (export precisa da API)

### File Ownership
- frontend-dev: src/app/, src/components/
- backend-dev: src/api/, src/services/
- ai-dev: src/agents/, src/models/

Confirma? (posso ajustar antes de criar)
```

---

## FASE 3: Criação (TeamCreate + Linear → Tasks → Teammates)

### 3a. Criar time

```
TeamCreate({
  team_name: "{projeto}-sprint",
  description: "Execução de {N} issues do {projeto}"
})
```

### 3b. Criar Tasks mapeadas das issues do Linear

Para CADA issue do Linear, criar uma Task local:

```
TaskCreate({
  subject: "{IDENTIFIER}: {título}",
  description: "Issue Linear: {identifier}\nPrioridade: {priority}\nEstimate: {estimate}\nDescrição: {description}\n\nCritérios de aceite: completar a issue e mover para In Review no Linear.",
  activeForm: "Executando {identifier}"
})
```

Se issue A bloqueia issue B:
```
TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })
```

### 3c. Spawnar teammates

Para CADA teammate do plano:

```
Agent({
  description: "Spawn {teammate-name}",
  subagent_type: "general-purpose",
  team_name: "{projeto}-sprint",
  name: "{teammate-name}",
  model: "{model}",
  prompt: "Você é o teammate '{name}' do time '{projeto}-sprint'.

## Seu Projeto
- Diretório: {cwd}
- Stack: {stack}

## Suas Issues (do Linear)
{lista de issues com identifier, título, descrição, estimate}

## File Ownership
Você SÓ edita: {dirs}
NÃO toque em: {dirs dos outros}

## Workflow OBRIGATÓRIO
1. TaskList() → ver suas tarefas
2. TaskUpdate(taskId, status: 'in_progress') ao começar
3. Implementar a issue
4. Ao terminar CADA issue, executar o fluxo Linear:
   a. Mover issue para 'In Review' via GraphQL:
      - Consultar state 'In Review' do team
      - Consultar labels existentes da issue
      - issueUpdate com stateId + labelIds (manter existentes + adicionar 'Claude')
      - commentCreate com relatório detalhado do que foi feito
5. TaskUpdate(taskId, status: 'completed')
6. TaskList() → próxima tarefa

## API Linear
- Endpoint: https://api.linear.app/graphql
- Auth: Authorization: {LINEAR_API_KEY do .env}
- Label Claude ID: 6dad8eed-291b-413b-9bfc-524e7aae0521

## Template de comentário ao mover pra Review
mutation {
  commentCreate(input: {
    issueId: \"ISSUE_ID\"
    body: \"## Task executada por Claude Code\\n\\n### O que foi feito\\n- ...\\n\\n### Arquivos alterados\\n- ...\\n\\n### Testes\\n- ...\\n\\n### Observações para o Revisor\\n- ...\\n\\n### Status\\nPronto para revisão humana\"
  }) { comment { id } }
}

## Regras
- NUNCA mover para Done — só até In Review
- SEMPRE adicionar label Claude
- SEMPRE comentar ao mover pra Review
- Se bloqueado, avise o lead via SendMessage"
})
```

### 3d. Atribuir tasks

```
TaskUpdate({ taskId: "1", owner: "frontend-dev" })
TaskUpdate({ taskId: "2", owner: "backend-dev" })
```

---

## FASE 4: Coordenação (PM/PO ativo)

O lead é **PM/PO puro**. Não coda. Coordena.

### Monitorar

- Mensagens dos teammates chegam automaticamente
- TaskList() pra ver progresso geral
- Se teammate termina issue → verificar se Linear foi atualizado

### Verificar updates no Linear

Periodicamente (quando teammates reportam conclusão):

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
- SendMessage pro teammate de B: "IA-43 concluída, pode começar IA-46"

### Reportar progresso ao usuário

```
━━━ PROGRESSO DO SPRINT ━━━━━━━━━━━━━━━━

  ✅ IA-42: Tela dashboard        → In Review (frontend-dev)
  🔄 IA-43: API relatórios        → In Progress (backend-dev)
  ⏳ IA-44: Modelo churn           → In Progress (ai-dev)
  🔒 IA-46: Export CSV             → Blocked by IA-43

  Completas: 1/4 | Em progresso: 2/4 | Blocked: 1/4
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## FASE 5: Encerramento

### 5a. Verificar completude

- TaskList() → todas completed?
- Verificar no Linear: todas as issues em "In Review"?

### 5b. Relatório final no Linear

Criar comentário no projeto ou milestone:

```
## Sprint Report — {data}

### Executado por Agent Team ({N} teammates)

| Issue | Teammate | Status | Estimate |
|---|---|---|---|
| IA-42 | frontend-dev | In Review | 5pts |
| IA-43 | backend-dev | In Review | 8pts |
| IA-44 | ai-dev | In Review | 13pts |
| IA-46 | backend-dev | In Review | 3pts |

**Total:** {N} issues, {sum} pontos
**Todas em In Review** — aguardando aprovação humana.
```

### 5c. Shutdown teammates

```
SendMessage({ to: "{name}", message: { type: "shutdown_request", reason: "Sprint concluído" } })
```

Para CADA teammate. Depois:

```
TeamDelete({})
```

### 5d. Resumo final ao usuário

```
━━━ SPRINT CONCLUÍDO ━━━━━━━━━━━━━━━━━━

  4 issues executadas → In Review
  3 teammates encerrados
  0 issues com problema

  Próximo passo: revisar no Linear e mover para Done.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Regras de Ouro

1. **Lead = PM/PO** — nunca coda, só coordena
2. **Linear é source of truth** — issues vêm de lá, updates voltam pra lá
3. **NUNCA mover pra Done** — só até In Review, humano aprova
4. **SEMPRE label Claude** em issues feitas por teammates
5. **SEMPRE comentar** ao mover pra Review
6. **Teammates REAIS** — team_name + name, NUNCA run_in_background
7. **File ownership** — cada teammate edita seus arquivos
8. **Desbloquear via SendMessage** — quando dependência resolve

## Anti-Patterns

| Errado | Correto |
|---|---|
| Lead coda | Lead coordena, delega tudo |
| Teammate move pra Done | Só até In Review |
| Ignora Linear | Atualiza Linear a cada issue concluída |
| Sem comentário no Review | Template completo obrigatório |
| Sem label Claude | Sempre adicionar |
| Issues sem TaskCreate | Mapear 1:1 Linear issue → Task local |
