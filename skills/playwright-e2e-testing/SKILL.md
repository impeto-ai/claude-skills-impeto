---
name: playwright-e2e-testing
description: Use when running E2E tests via MCP Playwright browser tools on web apps with authentication. Activates for: playwright, e2e, teste browser, testar sistema, teste automatizado, browser test.
chain: none
---

# Playwright E2E Testing (MCP Interactive)

Executa testes E2E interativos em web apps (Next.js/React) usando as tools MCP Playwright para controlar o browser em tempo real. Lida com sistemas que possuem credenciais e autenticacao.

## When to Use
- Testar fluxos completos de usuario em web apps
- Validar formularios, dashboards, CRUD operations
- Testar fluxos de login/autenticacao
- Debug visual de problemas em producao/staging
- Verificar se features novas funcionam end-to-end
- Explorar e mapear fluxos de um sistema via browser

## NOT When
- Testes unitarios (use testing-strategy)
- Testes de API sem browser (use curl/fetch)
- Testes de agents AI (use agent-tester)

## Prerequisites

Antes de comecar qualquer teste, verificar:

```
1. MCP Playwright disponivel (ToolSearch: "playwright")
2. Credenciais no .env ou informadas pelo usuario
3. URL do sistema alvo
```

## Instructions

### FASE 1: Setup & Autenticacao

**1.1 Descobrir credenciais**

NUNCA hardcode credenciais. Seguir esta ordem:

```
1. Verificar .env / .env.local por variaveis como:
   - TEST_USER_EMAIL, TEST_USER_PASSWORD
   - E2E_USERNAME, E2E_PASSWORD
   - PLAYWRIGHT_USER, PLAYWRIGHT_PASS

2. Se nao encontrar, PERGUNTAR ao usuario:
   "Preciso de credenciais para autenticar no sistema.
    Voce pode fornecer email/senha de teste?"

3. NUNCA salvar credenciais em arquivos .spec.ts ou SKILL.md
4. NUNCA commitar credenciais - verificar .gitignore
```

**1.2 Navegar e autenticar**

```
Passo 1: browser_navigate → URL de login
Passo 2: browser_snapshot → capturar estado da pagina
Passo 3: Identificar campos de login (email, password, submit)
Passo 4: browser_fill_form → preencher credenciais
Passo 5: browser_click → submit login
Passo 6: browser_snapshot → confirmar login bem-sucedido
Passo 7: browser_evaluate → salvar cookies/localStorage se necessario
```

**1.3 Persistir sessao (storageState pattern)**

Apos login bem-sucedido, capturar estado de autenticacao:

```javascript
// Via browser_evaluate, capturar session info
const cookies = await page.context().cookies();
const localStorage = await page.evaluate(() => JSON.stringify(localStorage));
// Salvar em .auth/storageState.json (gitignored)
```

Se o sistema usa NextAuth/Auth.js, verificar cookies `next-auth.session-token` ou `__Secure-next-auth.session-token`.

### FASE 2: Exploracao & Mapeamento

**2.1 Mapear a aplicacao**

Antes de testar, entender a estrutura:

```
1. browser_snapshot → capturar pagina atual
2. Identificar navegacao (menu, sidebar, breadcrumbs)
3. Listar rotas/paginas disponiveis
4. Identificar formularios e acoes criticas
5. Documentar fluxos principais para o usuario
```

**2.2 Snapshot Strategy**

SEMPRE usar `browser_snapshot` (nao screenshot) para:
- Ver elementos interagiveis com seus ref labels
- Identificar campos de formulario, botoes, links
- Entender hierarquia de componentes

Usar `browser_take_screenshot` apenas quando:
- Precisar mostrar resultado visual ao usuario
- Documentar um bug visual
- Capturar estado final de um teste

### FASE 3: Execucao de Testes

**3.1 Padrao de execucao**

Para cada teste, seguir:

```
1. ARRANGE: Navegar para pagina/estado inicial
   → browser_navigate + browser_snapshot

2. ACT: Executar acao do usuario
   → browser_click / browser_fill_form / browser_type

3. ASSERT: Verificar resultado
   → browser_snapshot + browser_evaluate

4. REPORT: Informar resultado ao usuario
   → "PASS: [descricao]" ou "FAIL: [descricao + evidencia]"
```

**3.2 Interacoes comuns**

```
# Preencher formulario
browser_fill_form → campos do form
browser_click → botao submit

# Navegar entre paginas
browser_click → link/menu item
browser_wait_for → elemento carregar

# Verificar dados
browser_evaluate → document.querySelector('.result').textContent

# Lidar com dialogs/modals
browser_handle_dialog → aceitar/rejeitar
browser_click → botao no modal

# Upload de arquivo
browser_file_upload → path do arquivo

# Esperar carregamento
browser_wait_for → seletor do elemento esperado
```

**3.3 Lidar com loading states**

Web apps modernos tem loading states. SEMPRE:

```
1. Apos click em submit/action:
   → browser_wait_for com timeout adequado

2. Se pagina usa SPA routing:
   → browser_wait_for no elemento principal da nova pagina

3. Se tem skeleton/loading:
   → browser_wait_for no conteudo real (nao no skeleton)
```

### FASE 4: Relatorio

**4.1 Formato de relatorio**

Apos executar testes, apresentar:

```markdown
## Resultado E2E Testing

**Sistema:** [URL]
**Data:** [timestamp]
**Autenticacao:** [metodo usado]

### Testes Executados

| # | Fluxo | Status | Observacao |
|---|-------|--------|------------|
| 1 | Login | PASS | Login em 2.3s |
| 2 | Criar registro | PASS | Form validou corretamente |
| 3 | Editar registro | FAIL | Campo X nao salvou |

### Falhas Encontradas
- **Teste 3:** Campo X retorna valor antigo apos save
  - Screenshot: [se capturado]
  - Console errors: [se houver]

### Recomendacoes
- [Acao 1]
- [Acao 2]
```

## Seguranca de Credenciais

### REGRAS ABSOLUTAS

```
NUNCA:
- Logar credenciais em output visivel
- Salvar senhas em arquivos rastreados pelo git
- Usar credenciais de producao (apenas staging/test)
- Expor tokens/cookies no relatorio
- Commitar .auth/ ou storageState

SEMPRE:
- Verificar que .auth/ esta no .gitignore
- Mascarar senhas no output: "****"
- Perguntar ao usuario antes de navegar para URLs desconhecidas
- Confirmar com usuario antes de executar acoes destrutivas (delete, etc)
- Fechar browser ao terminar (browser_close)
```

### Variaveis de Ambiente

```bash
# Padrao esperado no .env ou .env.local
E2E_BASE_URL=https://staging.example.com
E2E_USER_EMAIL=test@example.com
E2E_USER_PASSWORD=secure-test-password

# Nunca usar valores default hardcoded
# Sempre ler de env ou perguntar ao usuario
```

## MCP Tools Reference

```
browser_navigate     → Ir para URL
browser_snapshot     → Capturar DOM acessivel (preferir sobre screenshot)
browser_take_screenshot → Captura visual (para evidencia)
browser_click        → Clicar em elemento (por ref ou texto)
browser_fill_form    → Preencher multiplos campos de form
browser_type         → Digitar texto em campo focado
browser_press_key    → Pressionar tecla (Enter, Tab, Escape)
browser_hover        → Hover em elemento
browser_select_option → Selecionar option em select
browser_wait_for     → Esperar elemento aparecer
browser_handle_dialog → Aceitar/rejeitar dialog
browser_file_upload  → Upload de arquivo
browser_evaluate     → Executar JS no contexto da pagina
browser_console_messages → Ver console.log/error
browser_network_requests → Ver requests HTTP
browser_tabs         → Listar/trocar abas
browser_close        → Fechar browser
browser_navigate_back → Voltar pagina
browser_resize       → Redimensionar viewport
browser_drag         → Drag and drop
browser_run_code     → Executar codigo Playwright diretamente
```

## Common Mistakes

- Nao esperar loading terminar antes de assertar
- Usar screenshot quando snapshot seria melhor (snapshot mostra refs para click)
- Esquecer de fechar browser ao terminar
- Tentar interagir com elementos cobertos por overlay/modal
- Nao verificar console errors apos acoes
- Pular autenticacao e assumir que sessao esta ativa
- Hardcodar credenciais no prompt ou em arquivos
- Nao confirmar com usuario antes de acoes destrutivas (DELETE, reset, etc)

## Workflow Example

```
Usuario: "Testa o fluxo de criar um contrato no Price"

1. ToolSearch → "playwright" (carregar MCP tools)
2. Verificar .env por credenciais
3. Perguntar URL se nao obvio
4. browser_navigate → URL login
5. browser_snapshot → ver form login
6. browser_fill_form → email + senha
7. browser_click → submit
8. browser_snapshot → confirmar dashboard
9. browser_navigate → /contratos/novo (ou clicar no menu)
10. browser_snapshot → ver form contrato
11. browser_fill_form → dados do contrato
12. browser_click → salvar
13. browser_snapshot → confirmar criacao
14. browser_evaluate → verificar dados salvos
15. Reportar resultado ao usuario
16. browser_close → limpar
```
