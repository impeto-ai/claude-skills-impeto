---
name: qa-validator
description: Validador de processos E2E com Playwright + Linear. Recebe fluxo a testar, executa via MCP Playwright, gera evidências, registra bugs como débitos técnicos no Linear. Activates for "validar processo", "qa", "testar fluxo", "validar feature", "teste de aceite", "acceptance test", "validar entrega".
chain: none
---

# QA Validator — Testes E2E com evidências + débitos no Linear

Valida processos/features end-to-end via Playwright MCP. Gera evidências (screenshots). Bugs viram débitos técnicos no Linear prontos pra serem executados por outros agents.

## Fluxo completo

```
User: "validar processo de criação de pedido"
       │
       ▼
FASE 0: Setup (Linear + Playwright + credenciais)
       │
       ▼
FASE 1: Plano de testes (o que validar)
       │
       ▼
FASE 2: Execução (Playwright MCP — ARRANGE/ACT/ASSERT)
       │
       ▼
FASE 3: Evidências (screenshots de cada passo)
       │
       ▼
FASE 4: Relatório (PASS/FAIL com evidências)
       │
       ▼
FASE 5: Débitos técnicos (bugs → issues no Linear)
```

---

## FASE 0: Setup (OBRIGATÓRIO)

### 0a. Identificar a issue no Linear (se existir)

Se o usuário mencionou uma issue:

```graphql
{
  issueSearch(query: "IDENTIFIER", first: 1) {
    nodes {
      id identifier title description
      state { id name }
      labels { nodes { id name } }
      team { id key }
      project { id name }
    }
  }
}
```

Guardar: `ISSUE_ID`, `TEAM_ID`, `PROJECT_ID` pra criar sub-issues de bugs depois.

Se não mencionou issue → perguntar: "Existe uma issue no Linear associada a esse teste?"

### 0b. Verificar Playwright MCP

```
ToolSearch → "playwright" (carregar MCP tools)
```

Se não disponível → PARAR: "MCP Playwright não conectado. Rode: claude mcp add playwright -- npx -y @playwright/mcp@latest"

### 0c. Verificar credenciais

```
1. Procurar .env por E2E_BASE_URL, E2E_USER_EMAIL, E2E_USER_PASSWORD
2. Se não encontrar → perguntar ao usuário
3. NUNCA hardcodar credenciais
```

### 0d. Verificar LINEAR_API_KEY

```
1. Procurar .env por LINEAR_API_KEY
2. Se não encontrar → "Bugs não serão registrados no Linear. Continuar assim?"
3. Se encontrar → consultar viewer pra ter VIEWER_ID
```

---

## FASE 1: Plano de Testes

Baseado no argumento do usuário, montar plano:

```markdown
## Plano de QA — {processo}

**URL:** {base_url}
**Issue:** {identifier} (se existir)
**Data:** {hoje}

### Casos de teste

| # | Caso | Pré-condição | Passos | Resultado esperado |
|---|------|-------------|--------|-------------------|
| 1 | {caso} | {pré-condição} | {passos} | {esperado} |
| 2 | {caso} | {pré-condição} | {passos} | {esperado} |
| 3 | {caso} | {pré-condição} | {passos} | {esperado} |

### Edge cases
- {edge case 1}
- {edge case 2}

Confirma ou quer ajustar?
```

---

## FASE 2: Execução (Playwright MCP)

Para CADA caso de teste:

### 2a. ARRANGE — preparar estado

```
browser_navigate → URL do teste
browser_snapshot → capturar estado inicial
browser_take_screenshot → EVIDÊNCIA: "TC{N}_01_estado_inicial.png"
```

### 2b. ACT — executar ação do usuário

```
browser_fill_form / browser_click / browser_type
browser_wait_for → elemento esperado carregar
browser_take_screenshot → EVIDÊNCIA: "TC{N}_02_acao_executada.png"
```

### 2c. ASSERT — verificar resultado

```
browser_snapshot → capturar estado final
browser_evaluate → verificar dados (texto, contagem, valores)
browser_console_messages → verificar erros no console
browser_network_requests → verificar chamadas API (status 200/201)
browser_take_screenshot → EVIDÊNCIA: "TC{N}_03_resultado_final.png"
```

### 2d. Registrar resultado

```
PASS: Resultado confere com esperado
FAIL: {o que deu errado} + evidências
WARN: Funcionou mas com ressalvas (performance, console error, etc)
```

---

## FASE 3: Evidências

### Estrutura de evidências

```
.qa/
└── {data}_{processo}/
    ├── TC01_login/
    │   ├── 01_estado_inicial.png
    │   ├── 02_form_preenchido.png
    │   └── 03_dashboard_logado.png
    ├── TC02_criar_pedido/
    │   ├── 01_form_vazio.png
    │   ├── 02_form_preenchido.png
    │   ├── 03_submit.png
    │   └── 04_pedido_criado.png
    ├── TC03_validacao_campo/
    │   ├── 01_campo_invalido.png
    │   └── 02_mensagem_erro.png
    └── relatorio.md
```

### Como salvar screenshots

```
browser_take_screenshot → salva em .qa/{pasta}/TC{N}_{passo}.png
```

Se não conseguir salvar arquivo (limitação MCP) → descrever o screenshot no relatório com detalhes.

### Console errors como evidência

```
browser_console_messages → capturar TODOS
Filtrar: error e warning
Incluir no relatório se houver
```

---

## FASE 4: Relatório

### Gerar relatório em `.qa/{data}_{processo}/relatorio.md`:

```markdown
# Relatório QA — {processo}

**Data:** {data e hora}
**URL:** {base_url}
**Issue:** {identifier}
**Testador:** Claude Code (QA Validator)
**Autenticação:** {método}

## Resumo

| Métrica | Valor |
|---------|-------|
| Total de casos | {N} |
| PASS | {N} |
| FAIL | {N} |
| WARN | {N} |
| Taxa de sucesso | {%} |

## Resultados detalhados

### TC01: {título} — {PASS/FAIL/WARN}

**Pré-condição:** {estado inicial}
**Passos executados:**
1. {passo 1} → OK
2. {passo 2} → OK
3. {passo 3} → FAIL: {detalhe}

**Evidências:**
- Estado inicial: TC01/01_estado_inicial.png
- Resultado: TC01/03_resultado.png

**Console errors:** {nenhum / lista}
**Network:** {requests relevantes + status}

---

### TC02: {título} — {PASS/FAIL/WARN}
...

## Bugs encontrados

| # | Severidade | Descrição | Caso | Evidência |
|---|-----------|-----------|------|-----------|
| BUG-1 | 🔴 CRITICAL | {desc} | TC03 | TC03/02_erro.png |
| BUG-2 | 🟡 MEDIUM | {desc} | TC05 | TC05/03_warning.png |

## Insights

💡 **Descobertas:**
- {padrão identificado}
- {comportamento inesperado mas não bug}

⚠️ **Riscos:**
- {edge case não coberto}
- {performance concern}

📊 **Sugestões:**
- {melhoria de UX}
- {teste adicional recomendado}

## Conclusão

{APROVADO / APROVADO COM RESSALVAS / REPROVADO}
{Justificativa}
```

### Apresentar resumo ao usuário

```
━━━ QA REPORT: {processo} ━━━━━━━━━━━━━━━

  ✅ TC01: Login                    PASS
  ✅ TC02: Criar pedido             PASS
  ❌ TC03: Validação campo CEP      FAIL (BUG-1)
  ⚠️ TC04: Editar pedido            WARN (console error)
  ✅ TC05: Deletar pedido           PASS

  Resultado: 3 PASS | 1 FAIL | 1 WARN
  Bugs encontrados: 2 (1 critical, 1 medium)

  Relatório: .qa/{data}_{processo}/relatorio.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## FASE 5: Débitos Técnicos (Bugs → Linear)

### Para CADA bug encontrado, criar issue no Linear:

```graphql
mutation {
  issueCreate(input: {
    title: "BUG: {descrição curta}"
    description: "## Bug encontrado por QA Validator\n\n### Contexto\nEncontrado durante validação de: {processo}\nIssue original: {IDENTIFIER}\nCaso de teste: TC{N}\n\n### Reprodução\n1. {passo 1}\n2. {passo 2}\n3. {passo 3}\n\n### Comportamento esperado\n{esperado}\n\n### Comportamento atual\n{atual}\n\n### Evidências\n{referência aos screenshots}\n\n### Console errors\n{se houver}\n\n### Severidade\n{critical/high/medium/low}\n\n### Sugestão de fix\n{se tiver}"
    teamId: "TEAM_ID"
    projectId: "PROJECT_ID"
    parentId: "PARENT_ISSUE_ID"
    stateId: "TODO_STATE_ID"
    priority: {1-4 conforme severidade}
    labelIds: ["BUG_LABEL_ID", "CLAUDE_LABEL_ID"]
    assigneeId: "VIEWER_ID"
  }) {
    issue { id identifier title url }
  }
}
```

### Mapear severidade → prioridade

| Severidade | Priority | Significado |
|---|---|---|
| 🔴 CRITICAL | 1 (Urgent) | Bloqueia uso, precisa fix imediato |
| 🟠 HIGH | 2 (High) | Funcionalidade quebrada, fix esta semana |
| 🟡 MEDIUM | 3 (Medium) | Funciona com workaround |
| 🔵 LOW | 4 (Low) | Cosmético, não impacta funcionalidade |

### Labels

```
Bug: 0fab8687-157d-4d07-bddc-f68a3f1fd887
Claude: 6dad8eed-291b-413b-9bfc-524e7aae0521
```

### Criar como sub-issue da issue original

Se o teste era pra validar issue IA-42:
- Bug vira sub-issue de IA-42 (`parentId`)
- Herda projeto e milestone
- Assignee: VIEWER_ID (quem está testando decide pra quem atribuir)

### Atualizar issue original

Se TODOS os testes passaram:
```
→ Mover issue original pra In Review
→ Adicionar label Claude
→ Comentário: "QA Validator executou {N} testes. Todos PASS. Pronto pra review."
```

Se encontrou bugs:
```
→ Manter issue em In Progress (ou mover de volta se estava em Review)
→ Comentário: "QA Validator encontrou {N} bugs. Issues criadas: {lista}. Fix necessário antes de review."
```

### Informar ao usuário

```
━━━ DÉBITOS TÉCNICOS CRIADOS ━━━━━━━━━━━━

  🔴 IA-55: BUG: Campo CEP não valida formato
     Priority: Urgent | Sub-issue de IA-42

  🟡 IA-56: BUG: Console error ao abrir modal
     Priority: Medium | Sub-issue de IA-42

  Issue IA-42 mantida em In Progress.
  Fix os bugs → rode QA de novo → In Review.

  Quer que eu monte um time pra executar os fixes?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

A última pergunta é a **ponte pra linear-teams**: se o usuário aceitar, spawna um time pra executar os bugs.

---

## Integração com outras skills

| Skill | Conexão |
|---|---|
| **linear-work** | Consulta issue, atualiza estado, cria bugs |
| **linear-teams** | Se bugs encontrados: "quer montar time pra executar?" |
| **playwright-e2e-testing** | Usa mesmas tools MCP, mas qa-validator é mais estruturado |
| **verification-before-completion** | qa-validator pode ser chamado como etapa de verificação |

---

## Regras

1. **SEMPRE evidência** — todo teste precisa de screenshot
2. **NUNCA credenciais no relatório** — mascarar com ****
3. **SEMPRE consultar viewer** antes de criar issues (LINEAR_API_KEY + viewer.id)
4. **Bugs = sub-issues** da issue original (se existir)
5. **Severidade define prioridade** — critical=urgent, high=high, etc
6. **Label Claude + Bug** em toda issue de bug
7. **Relatório salvo em .qa/** — evidência persistente
8. **browser_close** ao terminar — SEMPRE

## Anti-Patterns

| Errado | Correto |
|---|---|
| Testar sem plano | Montar plano → confirmar → executar |
| Testar sem evidência | Screenshot em cada passo |
| Bug sem reprodução | Passos claros + evidência |
| Bug genérico "não funciona" | Descrição específica + esperado vs atual |
| Criar bug sem Linear | Sempre registrar (débito rastreável) |
| Ignorar console errors | Capturar e incluir no relatório |
| Fechar browser no meio | Completar todos os testes → fechar |
