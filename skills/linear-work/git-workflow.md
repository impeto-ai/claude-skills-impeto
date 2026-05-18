# Workflow Linear ↔ Git/GitHub — Detalhe Completo

Documento de referencia carregado sob demanda. Lido pelo agent quando vai criar branch, abrir PR, ou tirar duvida sobre integracao Linear-GitHub.

## Convencao de notacao (TUDO dinamico — nada hardcoded)

Todos os valores abaixo sao resolvidos em runtime via Linear API. O agent NAO deve assumir prefixo de team, nome de usuario, ou ID nenhum — sempre derivar.

| Placeholder | Como obter | Exemplo do shape |
|-------------|-----------|------------------|
| `{IDENTIFIER}` | `issue.identifier` da API Linear | `<TEAM_KEY>-<N>` (qualquer team do workspace) |
| `{team-lowercase}` | parte antes do `-` em `{IDENTIFIER}`, lowercase | `<team_key_lower>` |
| `{N}` | parte depois do `-` em `{IDENTIFIER}` | `<numero>` |
| `{usuario}` | `viewer.name` → primeiro nome lowercase sem acento | `<nome_lower>` |
| `{slug}` | `issue.title` → kebab-case sem acento, max ~50 chars | `<titulo-em-kebab>` |

Qualquer ocorrencia de string hardcoded tipo `IA-123`, `WFW-42`, `joao/...` neste documento e em qualquer codigo gerado pelo agent e BUG. Reportar e corrigir.

## Pre-requisitos (validar 1 vez por workspace)

1. Linear → Settings → Integrations → GitHub instalado, org `impeto-ai` autorizada, repos selecionados.
2. Em cada Team do workspace (IA, WFW, IAP, ...): Settings → Workflow → GitHub automations configurado:
   - Draft PR opened → In Progress
   - PR ready for review → In Review
   - PR merged (main/master) → Done
   - PR closed sem merge → Todo (volta)

Se o agent encontrar issue que nao linka apos seguir o fluxo, primeira hipotese: integracao nao instalada nesse repo. Pedir ao Joao.

---

## Fluxo Completo (Issue-First)

### Passo 1 — Issue ja existe
A issue existe no Linear ANTES da branch. Se nao existe, criar primeiro via `linear-pm` ou operacao 4 desta skill. Nunca criar branch sem issue.

### Passo 2 — Mover pra In Progress
Skill operacao 2: `In Progress` antes de codar. Linear ja avisa o time que o trabalho comecou.

### Passo 3 — Gerar nome de branch padronizado

**Formato:**
```
{usuario}/{team-lowercase}-{N}-{slug}
```

Replica exatamente o output do botao "Copy git branch name" da UI do Linear.

**Regras do slug:**
- Lowercase, sem acento
- Espaco e simbolos viram `-`
- Max ~50 chars

**Como o agent monta o nome (algoritmo, sem hardcode):**
```
1. issue.identifier        → "{IDENTIFIER}"        (ex shape: TEAMKEY-N)
2. identifier.toLowerCase  → "{team-lowercase}-{N}"
3. viewer.name → split " "[0] → strip acento → lower → "{usuario}"
4. issue.title → strip acento → kebab-case → truncate 50 → "{slug}"
5. branch_name = `${usuario}/${team-lowercase}-${N}-${slug}`
```

**Comando bash pra criar branch (substituicao em runtime):**
```bash
git checkout main
git pull
git checkout -b "${branch_name}"
```

### Passo 4 — Commits

Cada commit cita o {IDENTIFIER} da issue (resolvido em runtime). Recomendado no final da primeira linha entre parenteses:

```
<tipo>(<scope>): <descricao> ({IDENTIFIER})
```

Onde `<tipo>` segue conventional commits (feat/fix/refactor/docs/test/chore). Multiplos commits OK — qualquer um deles citando o ID basta pra rastreabilidade. Squash merge mantem links no body do commit final.

### Passo 5 — Abrir PR (sempre via `gh`)

**Template de comando (substituir `{IDENTIFIER}` pelo da issue real):**
```bash
gh pr create \
  --title "[{IDENTIFIER}] fix: descricao curta" \
  --body "$(cat <<'EOF'
Closes {IDENTIFIER}

## Contexto
Issue do Linear: {IDENTIFIER}

## O que muda
- [resumo 1-3 bullets]

## Como testar
- [passos]

## Notas pra revisor
- [se houver]
EOF
)" \
  --draft
```

**Por que `--draft`:**
- Linear mantem issue em `In Progress` (sinal correto pro time).
- Quando dev marcar "Ready for review" (`gh pr ready`), Linear move pra `In Review` automaticamente.
- Evita notification spam de PR ainda em construcao.

**Magic words aceitas no body (qualquer uma fecha a issue no merge):**
- `Closes {IDENTIFIER}`
- `Fixes {IDENTIFIER}`
- `Resolves {IDENTIFIER}`
- `Implements {IDENTIFIER}` (suportado desde 2026)

Pode listar multiplas issues do MESMO ou de teams DIFERENTES no mesmo PR: `Closes {IDENTIFIER_1}, Fixes {IDENTIFIER_2}`.

**ATENCAO:** magic word precisa estar no **body** do PR, nao so no title. Title ajuda na UI mas nao dispara o close automatico do GitHub. O body sim.

### Passo 6 — Ready for review
Quando codigo pronto pra revisar:
```bash
gh pr ready
```
Linear detecta e move issue pra `In Review`. Notificacao chega pros reviewers no Linear E no Discord (se webhook configurado).

### Passo 7 — Merge → Done automatico
Quando PR for mergeado em `main` (squash recomendado):
- GitHub fecha PR.
- Linear detecta `pull_request.merged` e move issue pra `Done`.
- Issue aparece no relatorio semanal como `completedAt = data do merge`.

**Agent NAO deve mover issue manualmente pra Done quando ha PR aberto** — deixar o merge cuidar. Mover manualmente cria race condition (Linear pode reverter pra In Review se o webhook do merge chegar depois).

---

## Casos Especiais

### Issue dividida em multiplos PRs
Cada PR cita a issue. Magic word com `Closes` so funciona se o PR efetivamente fecha o trabalho. Pra PRs intermediarios use:
```
Part of {IDENTIFIER}
```
(nao e magic word — so referencia visual). Quando ultimo PR fechar, ai sim `Closes {IDENTIFIER}`.

### Sub-issues (parent IDENTIFIER, children N+1..N+k)
Cada sub-issue tem sua propria branch e PR. Magic word fecha so a sub-issue. Parent fica aberta ate manualmente movida quando todas children completas.

### Hotfix (Priority 1)
Mesmo fluxo, mas branch parte de `main` (nao `develop`) e PR vai pra `main` direto. Squash merge.

### Reverter merge
Se precisa reverter (`git revert`), criar **nova issue** de hotfix referenciando a original. Nao reabrir a issue fechada — Linear nao tem fluxo bonito pra isso e bagunca metricas.

### PR multi-team (issues de teams diferentes)
PR pode fechar issues de teams diferentes no mesmo merge — listar todos os {IDENTIFIER}s no body, um por linha, com magic word. Cada team recebe o webhook e move sua propria issue.

---

## Troubleshooting

| Sintoma | Causa provavel | Fix |
|---------|----------------|-----|
| PR mergeado, issue NAO foi pra Done | Magic word ausente no body | Comentar `Closes {IDENTIFIER}` no PR (ainda dispara webhook) |
| Issue nao moveu pra In Review qdo PR ready | Integracao nao instalada nesse repo OU team mapping ausente | Settings Linear → adicionar repo OU configurar workflow do team |
| Branch criada, issue nao moveu pra In Progress | Nome da branch sem IDENTIFIER | Renomear: `git branch -m novo-nome` + force push |
| Issue linkou em PR errado | Multiplos PRs com mesmo IDENTIFIER | Editar body dos PRs incorretos pra remover magic word |
| PR fechado sem merge moveu issue pra Todo (queria manter In Progress) | Comportamento esperado | Reabrir PR ou mover issue manualmente |
| Branch com team key errado vs IDENTIFIER da issue | Hardcode no agent | Revisar: derivar team key DO `issue.identifier`, sempre. Rename branch. |

---

## Comandos Cheat-Sheet

Todos os placeholders sao resolvidos em runtime pela skill (ver tabela "Convencao de notacao" no topo). Zero hardcode.

```bash
# Criar branch
git checkout -b "${branch_name}"

# Commit citando issue
git commit -m "<tipo>(<scope>): <descricao> (${IDENTIFIER})"

# Abrir PR draft
gh pr create --draft \
  --title "[${IDENTIFIER}] <tipo>: <descricao>" \
  --body "Closes ${IDENTIFIER}"

# Marcar pronto pra review (move Linear pra In Review)
gh pr ready

# Ver status
gh pr status

# Merge (squash) — fecha issue no Linear automaticamente
gh pr merge --squash --delete-branch
```

---

## Referencias

- [Linear GitHub Integration Docs](https://linear.app/docs/github-integration)
- [Linear Magic Words](https://linear.app/docs/github-integration#using-magic-words)
- [GitHub closing keywords](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue)
