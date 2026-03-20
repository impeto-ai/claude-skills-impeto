---
name: agent-teams-manager
description: Use when user wants to create, manage, or coordinate a team of Claude Code agents. Activates for "time", "team", "agents", "multi-agent", "paralelo", "swarm", "equipe", "squad", "montar time", "criar time", "agent teams".
chain: none
---

# Agent Teams Manager

Gerenciador de times de agentes Claude Code. Cria TEAMMATES REAIS em tmux panes, NÃO subagents descartáveis.

---

## ⛔ REGRA #1 — ANTES DE CADA Agent() CALL, VERIFIQUE:

```
✅ Tem team_name?     → SIM (nome do time criado com TeamCreate)
✅ Tem name?          → SIM (nome único do teammate)
✅ Tem run_in_background? → NÃO! NUNCA!
✅ Tem isolation?     → NÃO! (worktree cria subagent isolado, não teammate)
```

Se QUALQUER dessas condições falhar, você está criando um SUBAGENT DESCARTÁVEL, não um teammate.

---

## TEAMMATE vs SUBAGENT — Entenda a diferença

| Parâmetro | Cria TEAMMATE real | Cria SUBAGENT descartável |
|---|---|---|
| `Agent(team_name="x", name="y", prompt="...")` | ✅ tmux pane, persiste, SendMessage | — |
| `Agent(prompt="...", run_in_background=true)` | — | ❌ morre após retornar |
| `Agent(prompt="...")` sem team_name/name | — | ❌ subagent inline |
| `Agent(prompt="...", isolation="worktree")` | — | ❌ subagent isolado |

---

## SCHEMAS EXATOS DAS TOOLS (referência obrigatória)

### TeamCreate — Criar o time

```json
TeamCreate({
  "team_name": "nome-do-time",      // OBRIGATÓRIO — kebab-case
  "description": "Objetivo do time"  // opcional
})
```

Cria:
- `~/.claude/teams/{team-name}.json` (config com members)
- `~/.claude/tasks/{team-name}/` (task list compartilhada)

### Agent — Spawnar teammate (CORRETO)

```json
Agent({
  "prompt": "Instruções detalhadas...",
  "team_name": "nome-do-time",      // OBRIGATÓRIO — mesmo nome do TeamCreate
  "name": "nome-do-teammate",       // OBRIGATÓRIO — identificador único
  "subagent_type": "general-purpose", // ou agent custom de .claude/agents/
  "model": "sonnet",                 // sonnet para tarefas diretas, opus para complexas
  "description": "3-5 palavras"      // OBRIGATÓRIO — resumo curto
})
```

⛔ PARÂMETROS PROIBIDOS para teammates:
- `run_in_background: true` → cria subagent descartável
- `isolation: "worktree"` → cria subagent isolado

### SendMessage — Comunicar com teammates

```json
// Mensagem direta (PREFERIR SEMPRE)
SendMessage({
  "to": "nome-do-teammate",
  "message": "Texto da mensagem",
  "summary": "5-10 palavras de preview"
})

// Broadcast (USAR COM PARCIMÔNIA — custo escala com N teammates)
SendMessage({
  "to": "*",
  "message": "Mensagem urgente para todos",
  "summary": "Resumo breve"
})

// Shutdown request
SendMessage({
  "to": "nome-do-teammate",
  "message": {
    "type": "shutdown_request",
    "reason": "Trabalho concluído"
  }
})
```

### TaskCreate — Criar tarefa na task list do time

```json
TaskCreate({
  "subject": "Título imperativo da tarefa",
  "description": "Descrição detalhada com critérios de aceite",
  "activeForm": "Gerúndio para spinner (ex: Implementando feature X)"
})
```

### TaskUpdate — Atualizar tarefa

```json
// Atribuir dono
TaskUpdate({ "taskId": "1", "owner": "nome-do-teammate" })

// Marcar em progresso
TaskUpdate({ "taskId": "1", "status": "in_progress" })

// Marcar completa
TaskUpdate({ "taskId": "1", "status": "completed" })

// Definir dependência (task 2 depende de task 1)
TaskUpdate({ "taskId": "2", "addBlockedBy": ["1"] })
```

### TaskList — Ver todas as tarefas

```json
TaskList({})  // sem parâmetros
```

### TeamDelete — Encerrar o time

```json
TeamDelete({})  // sem parâmetros — usa o time da sessão atual
```

⚠️ Falha se ainda houver teammates ativos. Faça shutdown de TODOS antes.

---

## FASE 1: Discovery (OBRIGATÓRIO — antes de criar qualquer coisa)

Extraia do usuário:

1. **"Quais projetos/repos os agentes vão trabalhar?"**
   - Identificar diretórios, stacks, CLAUDE.md de cada projeto
2. **"Qual a missão de cada agente?"**
   - Tarefas específicas, não genéricas
3. **"Tem dependência entre as tarefas?"**
   - Ordem, bloqueios, recursos compartilhados

### Contexto automático (faça sem perguntar):
- Leia o CLAUDE.md de cada projeto mencionado
- Identifique a stack (Next.js, Django, Go, etc.)
- Verifique se existem agents em `.claude/agents/`
- Mapeie arquivos que podem gerar conflito de edição

---

## FASE 2: Planejamento (apresente ANTES de criar)

```markdown
## Plano do Time

**Nome**: {team-name}
**Agentes**: {N}
**Modo**: tmux (cada agent em pane próprio)

### Agentes

| # | Nome | subagent_type | Projeto | Missão | Modelo |
|---|------|---------------|---------|--------|--------|
| 1 | {name} | {type} | {path} | {tarefa} | sonnet |
| 2 | {name} | {type} | {path} | {tarefa} | sonnet |

### Dependências
- Task X bloqueia Task Y (ou "Nenhuma — todas independentes")

### File Ownership (OBRIGATÓRIO)
- {agent-1}: {arquivos/dirs exclusivos}
- {agent-2}: {arquivos/dirs exclusivos}
- ⚠️ CONFLITO: {arquivo compartilhado} → resolver antes

Confirma? (posso ajustar antes de criar)
```

---

## FASE 3: Criação e Execução

### PASSO 0 — Verificar tmux (OBRIGATÓRIO antes de criar)

Antes de criar o time, verificar se estamos dentro do tmux:

```bash
echo "TMUX=$TMUX"
```

| Resultado | Significado | Ação |
|---|---|---|
| `TMUX=/private/tmp/tmux-501/default,...` | Dentro do tmux | Prosseguir — teammates abrem em panes |
| `TMUX=` (vazio) | FORA do tmux | AVISAR o usuário |

Se TMUX está **vazio**, informar:

```
⚠️ Você NÃO está dentro do tmux.

Os teammates vão funcionar em modo in-process (shift+↑/↓ pra navegar).
Para abrir em panes tmux separados:
  1. Saia do Claude Code (/exit)
  2. Entre no tmux: tmux
  3. Inicie o Claude Code: claude
  4. Peça pra montar o time de novo

Quer continuar em modo in-process ou prefere reiniciar no tmux?
```

**SEMPRE** perguntar antes de prosseguir. Não criar teammates silenciosamente em modo in-process se o usuário espera tmux.

### PASSO 1 — TeamCreate

```json
TeamCreate({
  "team_name": "meu-time",
  "description": "Objetivo do time"
})
```

### PASSO 2 — TaskCreate (ANTES de spawnar teammates)

Crie TODAS as tarefas primeiro:

```json
TaskCreate({
  "subject": "Implementar autenticação",
  "description": "Criar login com JWT...",
  "activeForm": "Implementando autenticação"
})
```

Se houver dependências:
```json
TaskUpdate({ "taskId": "2", "addBlockedBy": ["1"] })
```

### PASSO 3 — Spawnar Teammates (Agent com team_name + name)

⛔ CHECKLIST PRÉ-SPAWN:
- [ ] TeamCreate já executado?
- [ ] Tasks já criadas?
- [ ] Cada Agent() tem team_name E name?
- [ ] NENHUM Agent() tem run_in_background ou isolation?

Para CADA teammate:

```json
Agent({
  "description": "Spawn teammate backend-dev",
  "subagent_type": "general-purpose",
  "team_name": "meu-time",
  "name": "backend-dev",
  "model": "sonnet",
  "prompt": "Você é o teammate 'backend-dev' do time 'meu-time'.\n\n## Seu Projeto\n- Diretório: /path/to/project\n- Stack: FastAPI + PostgreSQL\n\n## Sua Missão\nImplementar endpoints de autenticação JWT.\n\n## File Ownership\nVocê SÓ pode editar: src/auth/, src/models/user.py\nNÃO toque em: src/api/routes/ (pertence ao api-dev)\n\n## Workflow\n1. TaskList() para ver suas tarefas\n2. TaskUpdate(taskId, status: 'in_progress') ao começar\n3. Execute o trabalho\n4. TaskUpdate(taskId, status: 'completed') ao terminar\n5. TaskList() para próxima tarefa disponível\n6. SendMessage(to: 'lead', message: 'Concluí task X') quando relevante"
})
```

**SPAWNE EM PARALELO** quando não há dependências — múltiplos Agent() calls na mesma mensagem.

### PASSO 4 — Atribuir Tasks

```json
TaskUpdate({ "taskId": "1", "owner": "backend-dev" })
TaskUpdate({ "taskId": "2", "owner": "frontend-dev" })
```

---

## FASE 4: Coordenação Ativa

O lead é COORDENADOR PURO. Não executa código.

### Mensagens chegam automaticamente
- NÃO precisa poll/check
- Teammates idle entre turns = NORMAL (não é erro)
- Idle notification após cada turn do teammate = comportamento padrão

### Comunicar
```json
// Orientar um teammate
SendMessage({ "to": "backend-dev", "message": "Priorize o endpoint /login", "summary": "Priorizar endpoint login" })

// Broadcast SÓ para emergências
SendMessage({ "to": "*", "message": "Bug crítico encontrado, parem tudo", "summary": "Bug crítico - parar" })
```

### Desbloquear
- Teammate A termina → TaskUpdate unblocks Task de B automaticamente
- Se teammate trava → SendMessage com contexto/solução
- Nova tarefa surge → TaskCreate + TaskUpdate com owner

### Consolidar
Quando todas as tasks completam:
1. Revisar trabalho de cada teammate (ler arquivos alterados)
2. Verificar conflitos entre alterações
3. Rodar testes se aplicável
4. Reportar resultado ao usuário

---

## FASE 5: Encerramento (OBRIGATÓRIO)

```
1. TaskList() → todas completed?
2. Para CADA teammate:
   SendMessage({
     "to": "nome-do-teammate",
     "message": { "type": "shutdown_request", "reason": "Trabalho concluído" }
   })
3. Aguardar confirmação de shutdown de todos
4. TeamDelete() para limpar recursos
5. Reportar resumo final ao usuário
```

**SEMPRE encerre o time.** Teammates não encerrados continuam consumindo recursos.

---

## Templates de Times Comuns

### Fullstack (2 agents)
| Nome | subagent_type | Missão | Modelo |
|------|---------------|--------|--------|
| frontend-dev | general-purpose | Front (Next.js/React) | sonnet |
| backend-dev | general-purpose | Back (Django/Go/FastAPI) | sonnet |

### Feature + Review (3 agents)
| Nome | subagent_type | Missão | Modelo |
|------|---------------|--------|--------|
| implementer | general-purpose | Implementa a feature | sonnet |
| tester | general-purpose | Escreve testes | sonnet |
| reviewer | general-purpose | Code review ao final | opus |

### Multi-Projeto (N agents)
| Nome | subagent_type | Missão | Modelo |
|------|---------------|--------|--------|
| sgi-dev | sgi | Trabalho exclusivo no SGI | sonnet |
| agrino-dev | agrino-web | Trabalho exclusivo no Agrino | sonnet |

### Pesquisa + Build (2 agents)
| Nome | subagent_type | Missão | Modelo |
|------|---------------|--------|--------|
| researcher | Explore | Pesquisa docs, APIs, exemplos (READ-ONLY) | sonnet |
| builder | general-purpose | Implementa baseado nos achados | sonnet |

⚠️ **Explore e Plan são READ-ONLY** — não podem editar arquivos. Só atribua pesquisa/análise a eles.

---

## Regras de Ouro

1. **NUNCA `run_in_background`** — cria subagent, não teammate
2. **NUNCA `isolation: "worktree"`** — cria subagent isolado
3. **SEMPRE `team_name` + `name`** — os dois OBRIGATÓRIOS no Agent()
4. **SEMPRE TeamCreate ANTES** de spawnar qualquer teammate
5. **SEMPRE TaskCreate ANTES** de spawnar teammates
6. **Um arquivo = um dono** — nunca dois agents no mesmo arquivo
7. **Lead não coda** — coordena, delega, audita, consolida
8. **Max 3-5 teammates** — mais = overhead > ganho
9. **Idle é NORMAL** — não reaja a idle notifications sem necessidade
10. **SEMPRE encerre** — shutdown_request + TeamDelete

---

## Anti-Patterns (PROIBIDO)

| Anti-Pattern | Resultado | Correto |
|---|---|---|
| `Agent(run_in_background=true)` | Subagent descartável | `Agent(team_name="x", name="y")` |
| `Agent(isolation="worktree")` | Subagent isolado | `Agent(team_name="x", name="y")` |
| `Agent(prompt="...")` sem team_name | Subagent inline | Adicionar team_name + name |
| Lead executando código | Perde coordenação | Delegar via Task + SendMessage |
| Broadcast para tudo | Custo O(N) | SendMessage direto pro destinatário |
| Spawnar sem TaskCreate | Teammates sem direção | Criar tasks ANTES |
| Não definir file ownership | Conflitos de edição | Definir no prompt de cada teammate |
| Não encerrar time | Resource leak | shutdown_request + TeamDelete |
| Usar Agent() pra "verificar" | Cria subagent avulso | SendMessage pro teammate |

---

## Troubleshooting

| Problema | Causa | Solução |
|---------|-------|---------|
| Teammates em background | Usou `run_in_background` | Recriar com team_name + name |
| Teammate não vê tasks | Faltou `team_name` no Agent | Spawnar com team_name correto |
| Teammate não responde | Idle (normal) | SendMessage para acordar |
| Conflito de arquivos | Dois agents no mesmo file | Redistribuir file ownership |
| tmux panes não aparecem | Não está em tmux session | Iniciar com `tmux` antes |
| Teammate sumiu | Crashed ou timeout | Spawnar novo com mesmo nome |
| TeamDelete falha | Teammates ainda ativos | shutdown_request para todos primeiro |

---

## Output Esperado

Ao ativar esta skill:

```
⚡ AGENT TEAMS MANAGER ATIVADO

Vou montar seu time. Me conta:
1. Quais projetos/tarefas os agentes vão trabalhar?
2. O que cada um deve fazer?
(Ou descreva tudo de uma vez que eu organizo)
```
