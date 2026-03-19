---
name: forge
description: Playbook de construtores do ambiente Claude Code. Cria skills, agents, hooks, commands e teams. Activates for "forge", "criar skill", "criar agent", "criar hook", "criar command", "novo construtor", "scaffoldar", "/forge".
chain: none
---

# FORGE — Playbook de Construtores Claude Code

Switch de construtores para criar qualquer componente do ambiente Claude Code.

---

## Roteamento — O que você quer construir?

Ao ativar, pergunte:

```
⚡ FORGE ATIVADO

O que você quer construir?

1. /forge skill    → Criar nova skill (SKILL.md + hook trigger)
2. /forge agent    → Criar novo agent (agent.md em .claude/agents/)
3. /forge hook     → Criar novo hook script (+ registrar no settings.json)
4. /forge command  → Criar novo command (command.md em .claude/commands/)
5. /forge team     → Montar agent team (→ delega para agent-teams-manager)
6. /forge audit    → Auditar ambiente atual (gaps, orphans, conflitos)

Ou descreva o que precisa e eu escolho o construtor certo.
```

---

## 1. FORGE SKILL — Criar nova skill

### Interview (1 pergunta por vez)

```
Q1: Nome da skill? (kebab-case, ex: supabase-migrations)
Q2: O que essa skill deve fazer?
Q3: Quais palavras-chave ativam? (viram regex no activator)
Q4: Onde salvar? projeto (.claude/skills/) ou global (~/.claude/skills/)
Q5: Encadeia para outra skill após execução? (chain)
```

### Gerar SKILL.md

Localização: `{destino}/skills/{skill-name}/SKILL.md`

```markdown
---
name: {skill-name}
description: Use when {trigger}. Activates for: {keywords}.
chain: {next-skill | none}
---

# {Skill Title}

{Descrição em 1-2 frases}

## When to Use
- {Trigger 1}
- {Trigger 2}
- NOT when: {quando não usar}

## Instructions
{Instruções detalhadas para o Claude seguir}

## Examples
{Exemplos práticos de uso}

## Chain Behavior
{Se chain != none:}
After completing → ACTIVATE: {next-skill}
{Se condicional:}
- ON SUCCESS → {skill-on-success}
- ON FAILURE → create debt doc in /.debts/{skill-name}/

## Common Mistakes
- {Erro 1 a evitar}
- {Erro 2 a evitar}
```

### Registrar no skill-activator.sh

Localização: `~/.claude/hooks/skill-activator.sh`

Encontre a seção correta por prioridade (projeto-específico > ecosistema > genérico) e adicione:

```bash
# {SKILL-NAME-UPPERCASE} (chains to {next} | independent)
if echo "$prompt_lower" | grep -qiE '{regex-pattern}'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: {skill-name}\nREAD: ~/.claude/skills/{skill-name}/SKILL.md\nFOLLOW: {instrução breve}\n{CHAIN: After completion → {next-skill}  # se houver}\nOUTPUT: ⚡ SKILL_ACTIVATED: #{CODE-4CHR}\n</skill-instruction>"
      }
    }'
    exit 0
fi
```

### Regras de regex

| Tipo | Formato |
|------|---------|
| Palavra exata | `\bpalavra\b` |
| Acentos PT-BR | `[çc][aã]o` para "ção" |
| Flexível | `.?` entre palavras compostas |
| Alternativas | `\|` entre opções |
| Word boundary | Sempre usar `\b` para evitar false positives |

### Checklist pós-criação

```
[ ] SKILL.md criado com frontmatter correto
[ ] skill-activator.sh atualizado com if block
[ ] Posição correta no activator (prioridade)
[ ] Regex testado mentalmente contra keywords
[ ] chain target existe (se declarado)
[ ] Skill code único (#PREFIX-4CHR)
[ ] chmod +x no activator mantido
```

---

## 2. FORGE AGENT — Criar novo agent.md

### Interview

```
Q1: Nome do agent? (kebab-case)
Q2: O que esse agent faz? (descrição curta)
Q3: Esse agent pode EDITAR arquivos ou é só leitura?
    - LEITURA (read-only): tools: Read, Glob, Grep
    - LEITURA + BASH: tools: Read, Glob, Grep, Bash
    - ACESSO TOTAL: tools: Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch, Agent
    - CUSTOMIZADO: escolher quais tools
Q4: Qual modelo? (sonnet para tarefas diretas, opus para complexas, haiku para leitura)
Q5: Escopo global (~/.claude/agents/) ou projeto (.claude/agents/)?
Q6: Precisa de hooks específicos? (PreToolUse, PostToolUse)
```

⚠️ **IMPORTANTE sobre tools**: Se omitir o campo `tools:` no frontmatter, o agent tem acesso a TODAS as tools. Sempre perguntar ao usuário se o agent precisa editar ou só ler. Na dúvida, restringir.

### Perfis de acesso (atalhos)

| Perfil | tools: | Quando usar |
|--------|--------|-------------|
| **read-only** | `Read, Glob, Grep` | Pesquisador, auditor, analista |
| **read + bash** | `Read, Glob, Grep, Bash` | Debug, rodar testes, explorar |
| **editor** | `Read, Write, Edit, Glob, Grep` | Dev que edita mas não roda comandos |
| **full** | _(omitir campo)_ | Dev com acesso total |

### Gerar agent.md

Localização: `{destino}/agents/{agent-name}.md`

```markdown
---
name: {agent-name}
description: {Descrição curta — aparece na lista de subagent_type do Agent tool}
model: {sonnet | opus | haiku}
color: {cyan | yellow | green | red | magenta | blue}
tools: {lista de tools conforme perfil escolhido}
---

Você é o agent **{agent-name}**.

## Contexto
{Domínio de conhecimento e stack}

## Regras
{O que DEVE e NÃO DEVE fazer}

## Workflow
{Passo a passo do que executar}
```

### Frontmatter — campos disponíveis

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `name` | string | ✅ | Identificador único |
| `description` | string | ✅ | Quando usar este agent |
| `model` | string | ❌ | sonnet/opus/haiku (herda do pai se omitido) |
| `color` | string | ❌ | Cor no terminal |
| `tools` | string | ❌ | Lista de tools permitidas (**TODAS se omitido — cuidado!**) |
| `hooks` | object | ❌ | Hooks específicos deste agent |

### Hooks no agent (opcional)

```markdown
---
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "bash .claude/hooks/block-destructive-db.sh"
  PostToolUse:
    - matcher: "Write"
      hooks:
        - type: command
          command: "bash .claude/hooks/auto-format.sh"
---
```

Hooks no agent só rodam **enquanto esse agent está ativo**.

### Checklist pós-criação

```
[ ] agent.md criado com frontmatter correto
[ ] description clara (aparece na seleção de subagent_type)
[ ] tools restritivas se necessário (principle of least privilege)
[ ] model adequado ao nível de complexidade
[ ] Se agent de projeto: testar com Agent(subagent_type="{name}")
```

---

## 3. FORGE HOOK — Criar novo hook script

### Interview

```
Q1: Qual evento? (PreToolUse, PostToolUse, UserPromptSubmit, Stop, SessionStart, SubagentStop, etc.)
Q2: Qual matcher? (Bash, Edit|Write, mcp__*, "" para todos)
Q3: O que o hook deve fazer? (bloquear, formatar, logar, notificar, injetar contexto)
Q4: Escopo? settings.json (global) ou .claude/settings.json (projeto)
Q5: Async? (true para side-effects como log/notify, false para validação)
```

### Gerar script do hook

Localização: `~/.claude/hooks/{hook-name}.sh` ou `.claude/hooks/{hook-name}.sh`

#### Template: PreToolUse (validação/bloqueio)

```bash
#!/bin/bash
# Hook: {hook-name}
# Evento: PreToolUse | Matcher: {matcher}
# Propósito: {descrição}

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Lógica de validação
if {condição_de_bloqueio}; then
  echo "BLOQUEADO: {motivo}" >&2
  exit 2  # exit 2 = BLOQUEIA a ação
fi

exit 0  # exit 0 = PERMITE
```

#### Template: PostToolUse (formatação/log)

```bash
#!/bin/bash
# Hook: {hook-name}
# Evento: PostToolUse | Matcher: {matcher}

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty')

# Lógica pós-execução (ex: format, lint, log)
{ação}

exit 0
```

#### Template: SessionStart (setup de ambiente)

```bash
#!/bin/bash
# Hook: {hook-name}
# Evento: SessionStart | Matcher: {startup|resume|compact}

if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export {VAR}={VALUE}' >> "$CLAUDE_ENV_FILE"
fi

# Stdout vira contexto injetado na sessão
echo "CONTEXTO: {informação importante para a sessão}"
exit 0
```

#### Template: Stop (notificação)

```bash
#!/bin/bash
# Hook: {hook-name}
# Evento: Stop

INPUT=$(cat)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')

# Evitar loop infinito
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

# Notificação macOS
osascript -e 'display notification "Claude terminou" with title "Claude Code" sound name "Glass"' 2>/dev/null
exit 0
```

### 4 Tipos de Handler — escolha o certo

#### Tipo 1: command (mais comum — shell script)

```json
{
  "type": "command",
  "command": "{path_do_script}",
  "timeout": 600,
  "async": false
}
```
- Recebe JSON via stdin, retorna via stdout/stderr
- ~10-20ms (bash), ~200ms (python)
- **Usar quando**: validação, formatação, log, notificação

#### Tipo 2: http (endpoint externo)

```json
{
  "type": "http",
  "url": "http://localhost:8080/hooks/{event}",
  "timeout": 30,
  "headers": { "Authorization": "Bearer $MY_TOKEN" },
  "allowedEnvVars": ["MY_TOKEN"]
}
```
- POST com mesmo JSON que command receberia
- Retorna JSON no response body
- **Usar quando**: validação corporativa remota, logging centralizado, webhook

#### Tipo 3: prompt (LLM avalia — Haiku por padrão)

```json
{
  "type": "prompt",
  "prompt": "Avalie se esta ação é segura: $ARGUMENTS",
  "model": "claude-haiku-4-5"
}
```
- LLM single-turn avalia e retorna `{"ok": true/false, "reason": "..."}`
- ~1-3s de latência
- **Usar quando**: decisões que precisam de julgamento (não apenas regex)

#### Tipo 4: agent (subagent com tools — mais poderoso)

```json
{
  "type": "agent",
  "prompt": "Verifique se os testes passam. Rode npm test e analise resultados. $ARGUMENTS",
  "timeout": 120
}
```
- Spawna subagent com até 50 tool-use turns
- Pode ler arquivos, rodar comandos, buscar código
- Retorna `{"ok": true/false, "reason": "..."}`
- ~5-60s
- **Usar quando**: quality gates complexos (rodar testes, verificar cobertura, auditar código)

### Registrar no settings.json

Localização conforme escopo:
- Global: `~/.claude/settings.json`
- Projeto: `.claude/settings.json`
- Projeto local: `.claude/settings.local.json`

Adicione dentro de `hooks.{EventName}`:

```json
{
  "matcher": "{matcher}",
  "hooks": [
    {
      // Escolha UM dos 4 tipos acima
      "type": "command",
      "command": "{path_do_script}",
      "timeout": 600,
      "async": false
    }
  ]
}
```

### Templates de Segurança (prontos pra usar)

#### Enforce read-only por agent name

Garante que um agent nunca edite arquivos, mesmo que o Claude tente:

```bash
#!/bin/bash
# Hook: enforce-readonly.sh
# Evento: PreToolUse | Matcher: Write|Edit

INPUT=$(cat)
AGENT=$(echo "$INPUT" | jq -r '.agent_type // empty')
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Agents que são read-only (adicione nomes aqui)
READONLY_AGENTS=("researcher" "auditor" "explorer" "analyst")

for ro_agent in "${READONLY_AGENTS[@]}"; do
  if [[ "$AGENT" == "$ro_agent" ]] && [[ "$TOOL" =~ ^(Write|Edit)$ ]]; then
    echo "BLOQUEADO: agent '$AGENT' é read-only, não pode usar $TOOL" >&2
    exit 2
  fi
done

exit 0
```

#### Bloquear comandos destrutivos

```bash
#!/bin/bash
# Hook: block-destructive.sh
# Evento: PreToolUse | Matcher: Bash

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

DANGEROUS=("rm -rf" "git push.*--force" "DROP TABLE" "DROP DATABASE" "TRUNCATE"
           "DELETE FROM" "git reset --hard" "dd if=/dev" "mkfs\.")

for pattern in "${DANGEROUS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "BLOQUEADO: comando destrutivo detectado: '$pattern'" >&2
    exit 2
  fi
done

exit 0
```

#### Proteger arquivos sensíveis

```bash
#!/bin/bash
# Hook: protect-secrets.sh
# Evento: PreToolUse | Matcher: Read|Write|Edit

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

PROTECTED=(".env" ".env.local" ".env.production" "credentials" "secrets"
           ".ssh/id_" ".aws/credentials" ".kube/config" ".pgpass")

for pattern in "${PROTECTED[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "BLOQUEADO: arquivo protegido: $pattern" >&2
    exit 2
  fi
done

exit 0
```

#### Audit log de todas as operações

```bash
#!/bin/bash
# Hook: audit-log.sh
# Evento: PostToolUse | Matcher: "" (todos)
# IMPORTANTE: usar async: true pra não bloquear

INPUT=$(cat)
echo "$INPUT" | jq -c '{
  ts: (now | todate),
  tool: .tool_name,
  agent: (.agent_type // "main"),
  input: .tool_input
}' >> ~/.claude/audit.log

exit 0
```

### Referência de exit codes

| Código | Efeito |
|--------|--------|
| 0 | Permite a ação. Stdout = contexto (SessionStart/UserPromptSubmit) |
| 2 | BLOQUEIA a ação. Stderr = feedback pro Claude |
| Outro | Erro não-bloqueante. Ação prossegue. |

### Checklist pós-criação

```
[ ] Script criado e executável (chmod +x)
[ ] Lê stdin como JSON ($(cat) + jq)
[ ] Exit codes corretos (0=allow, 2=block)
[ ] Registrado no settings.json correto
[ ] Matcher específico (evitar "" quando possível)
[ ] Timeout razoável
[ ] Testado: echo '{"tool_input":{"command":"test"}}' | bash hook.sh
```

---

## 4. FORGE COMMAND — Criar novo slash command

### Interview

```
Q1: Nome do command? (vira /nome)
Q2: O que ele faz?
Q3: Precisa de argumentos? ($ARGUMENTS)
Q4: Escopo? global (~/.claude/commands/) ou projeto (.claude/commands/)
```

### Gerar command.md

Localização: `{destino}/commands/{command-name}.md`

```markdown
{Instruções que o Claude recebe quando /command é invocado}

$ARGUMENTS
```

`$ARGUMENTS` é substituído pelo texto após o comando. Ex: `/deploy staging` → `$ARGUMENTS` = "staging"

### Exemplos de commands úteis

#### /pr — Abrir Pull Request

```markdown
Crie um Pull Request seguindo este padrão:

1. git status para ver mudanças
2. git diff para entender o que mudou
3. Crie branch se necessário (feat/... ou fix/...)
4. Push com -u
5. gh pr create com:
   - Título curto (<70 chars)
   - Body com ## Summary + ## Test Plan
   - Labels relevantes

$ARGUMENTS
```

#### /test — Rodar testes

```markdown
Execute os testes do projeto:

1. Identifique o framework de teste (pytest, jest, go test, etc.)
2. Rode os testes
3. Se falhar, analise e proponha fix
4. Reporte cobertura se disponível

Foco em: $ARGUMENTS
```

#### /deploy-check — Checklist de deploy

```markdown
Antes de fazer deploy, verifique:

- [ ] Testes passando
- [ ] Sem secrets hardcoded
- [ ] Migrations rodaram
- [ ] .env.example atualizado
- [ ] CHANGELOG atualizado
- [ ] Branch correta

Ambiente: $ARGUMENTS
```

### Checklist pós-criação

```
[ ] command.md criado na localização correta
[ ] $ARGUMENTS incluído se aceita parâmetros
[ ] Testado com /nome-do-command
```

---

## 5. FORGE TEAM — Delegar para agent-teams-manager

Quando o usuário pede `/forge team`:

```
→ DELEGAR para skill: agent-teams-manager
→ READ: ~/.claude/skills/agent-teams-manager/SKILL.md
→ Seguir as 5 fases: Discovery → Planejamento → Criação → Coordenação → Encerramento
→ CRITICAL: Usar TeamCreate + Agent(team_name, name) — NUNCA run_in_background
```

---

## 6. FORGE AUDIT — Auditar ambiente atual

Quando o usuário pede `/forge audit`:

### Verificações automáticas

```bash
# 1. Skills sem trigger no activator
for skill in ~/.claude/skills/*/SKILL.md; do
  name=$(grep "^name:" "$skill" | cut -d' ' -f2-)
  if ! grep -q "$name" ~/.claude/hooks/skill-activator.sh; then
    echo "⚠️ Skill '$name' sem trigger no skill-activator.sh"
  fi
done

# 2. Agents sem description
for agent in ~/.claude/agents/*.md; do
  if ! grep -q "^description:" "$agent"; then
    echo "⚠️ Agent '$agent' sem description no frontmatter"
  fi
done

# 3. Hooks referenciando scripts inexistentes
# Parsear settings.json e verificar cada command path

# 4. Skills com chain apontando para skill inexistente
# Parsear chain: no frontmatter e verificar existência

# 5. Permissões com secrets expostos no settings.local.json
# Grep por patterns de tokens/passwords na allow list
```

### Output esperado

```
🔍 FORGE AUDIT

Skills: 80 encontradas
  ✅ 75 com trigger no activator
  ⚠️ 5 orphans (sem trigger)
    - skill-x
    - skill-y

Agents: 3 encontrados
  ✅ Todos com frontmatter correto

Hooks: 1 script (skill-activator.sh)
  ✅ 460 linhas, 30+ triggers
  ⚠️ Nenhum hook de segurança (PreToolUse)

Commands: 7 encontrados
  ✅ Todos válidos

Settings:
  ⚠️ settings.local.json tem 317 allow rules
  ⚠️ 3 regras com secrets expostos (Notion, Obsidian, PGPASSWORD)
  ⚠️ 0 deny rules (recomendado: bloquear .env, rm -rf)

Recomendações:
1. Criar hooks de segurança (forge hook)
2. Limpar allow rules acumuladas
3. Adicionar deny rules básicas
4. Registrar skills orphans no activator
```

---

## Regras do Forge

1. **Uma pergunta por vez** — não bombardeie o usuário
2. **Sempre confirme antes de criar** — mostre preview
3. **Respeite a estrutura existente** — skills em symlink, hooks no activator
4. **Teste mentalmente** — regex, paths, exit codes
5. **Incremente, não substitua** — adicione ao activator, não reescreva
6. **chmod +x** em todo script de hook
7. **Skill codes únicos** — verifique existentes antes de gerar
