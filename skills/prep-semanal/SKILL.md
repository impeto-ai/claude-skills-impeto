---
name: prep-semanal
description: Gera prep semanal cross-empresa do Joao — engloba todas as cadeiras ativas (descobertas dinamicamente em 00-Brain/empresas/), com Top 3 prioridades por empresa, deadlines, time, pessoal (4 pilares Soul-aligned), decisoes pendentes e links bidirecionais. Usar SEMPRE no domingo a noite ou segunda de manha pra planejar a semana, OU sexta a tarde pra fechar/review. Activates for "prep semanal", "semanal", "planejar semana", "weekly review", "prep weekly", "fechar semana", "review semanal", "semana".
---

# /prep-semanal — Prep Semanal Cross-Empresa do Joao

Gera o documento canonico de planejamento semanal, englobando todas as cadeiras de empresa ativas do Joao + dimensao pessoal (Soul axioma 4 — corpo/mente/dinheiro/sonhos).

## Quando usar

- **Domingo a noite ou segunda de manha:** planejar semana corrente — `/prep-semanal`
- **Sexta a tarde:** fechar semana que terminou — `/prep-semanal review`
- **Mid-week (quarta/quinta):** check-in — `/prep-semanal status`

## Regra fundamental

**NAO hardcode empresas.** Joao opera 3 hoje (Impeto, Innovagro, Workflow), pode ser 4 amanha (se Astrobale virar operacional) ou 2 (se consolidar). A skill **descobre via glob** `~/.docs/PeronalJN/00-Brain/empresas/*.md` toda vez. Cada arquivo encontrado vira 1 bloco no doc.

## Processo

### PASSO 1 — Identificar a semana

```bash
# Numero da semana ISO 8601 (segunda como primeiro dia)
WEEK_NUM=$(date +%V)
# Ano
YEAR=$(date +%Y)
# Periodo (segunda → domingo)
MON=$(date -v-Mon +%d/%m)
SUN=$(date -v+Sun +%d/%m)
```

Resultado: `W{NUM}` (ex: W18), periodo "DD/MM - DD/MM/YYYY".

### PASSO 2 — Descobrir empresas ativas

```bash
# Lista todas as empresas com paginas no Brain
empresas=()
for f in ~/.docs/PeronalJN/00-Brain/empresas/*.md; do
  slug=$(basename "$f" .md)
  empresas+=("$slug")
done
echo "Empresas ativas: ${empresas[@]}"
```

OU via Obsidian CLI:
```bash
obsidian search query="path:00-Brain/empresas/" format=json | jq -r '.[]' | xargs -I{} basename {} .md
```

Pra cada empresa encontrada, ler o arquivo:
```bash
obsidian read path="00-Brain/empresas/$slug.md"
```

Extrair:
- Papel do Joao (CTO formal, Dono, Responsavel tecnico, etc — frontmatter ou H1)
- Estado atual (resumo do overview)
- Pessoas-chave (lista do mapa de equipe)

### PASSO 3 — Coletar contexto

Em paralelo, ler:

1. **Brain:**
   - `00-Brain/_MAP.md` (indice)
   - `00-Brain/Soul.md` (axiomas)
   - `00-Brain/empresas/{cada}.md` (estado de cada cadeira)

2. **Network:**
   - `00-Network/_CONTEXT.md` (snapshot estado geral)
   - `00-Network/_FEED.md` (top 30 — ultima semana de atividade)

3. **Diario:**
   - `00-Brain/diario/{YYYY-MM}/{cada-dia-da-semana-anterior}.md`
   - Decisoes, follow-ups, sinais de sobrecarga
   - Compromissos da semana corrente (se ja registrados)

4. **Linear (via API ou linear-init):**
   - Issues atribuidas ao Joao P1-P2 abertas
   - Issues fechadas semana anterior (review)
   - Deadlines proximos (7 dias)
   - Por team: IA, IAP, WFW

5. **Memorias:**
   - `~/.claude/projects/-Users-joaod-nascimento-ops-impeto-managing-cto-ops/memory/MEMORY.md`
   - Especialmente memorias `project_*` (estado projetos), `feedback_*` (regras), `user_*` (perfil)

6. **Semanal anterior (se existir):**
   - `00-Brain/planning/{ano}/W{N-1}-prep-semanal.md`
   - Pra preencher Review Semana Anterior

7. **Eventos do calendar (se MCP disponivel):**
   - Compromissos fixos da semana
   - Reunioes recorrentes

### PASSO 4 — Gerar doc

Caminho final:
```
~/.docs/PeronalJN/00-Brain/planning/{YYYY}/W{NUM}-prep-semanal.md
```

Use o template:
```
~/.docs/PeronalJN/00-Brain/planning/_template-prep-semanal.md
```

Preenche substituindo:
- `{N}` → numero da semana (18, 19, etc)
- `{periodo}` → DD/MM - DD/MM/YYYY
- `{ONE THING}` → priorizar a mais critica detectada (ex: deadline P1 em risco, milestone que destrava cascade)
- Para CADA empresa descoberta, criar bloco com:
  - Top 3 prioridades (extraidas de issues Linear P1-P2 + decisoes pendentes Brain)
  - Decisoes pendentes (do diario + memorias)
  - Cobrar (3+ dias sem update no FEED ou Linear)
  - Linear ativo (lista de IDs P1-P2)
  - Quem owns (do mapa de equipe)
- Deadlines da semana (do diario + Linear due dates)
- Time alocacao (do estado atual de cada empresa)
- Pessoal 4 pilares (do diario + Soul)
- Eventos fixos (do calendar)
- Decisoes a tomar (do diario)
- Ideias capturadas (do diario)
- Links bidirecionais ([[empresas/X]], [[diario/{cada}]], [[planning/W{N-1}]])

### PASSO 5 — Output ao usuario

Mostrar pro Joao:
- Caminho do doc gerado
- ONE THING destacado
- Top 3 prioridades por empresa (sumario)
- Deadlines criticos da semana
- Pergunta: "preencheu o suficiente, ou quer ajustar X campo?"

NAO automatizar 100%. Joao deve revisar ONE THING + Pessoal antes de "ativar" a semana.

### PASSO 6 — Atualizar links

- Append em `00-Network/_FEED.md`: `### {data} — @cto-ops · Prep semanal W{N} criado`
- Atualizar diario do dia (`00-Brain/diario/{YYYY-MM}/{YYYY-MM-DD}.md`) com link pro prep
- Se ja existe semanal anterior, atualizar link "→ proxima" nela

## Modos de invocacao

### `/prep-semanal` (default)
Cria/atualiza doc da semana corrente.

### `/prep-semanal next`
Cria doc da proxima semana (planejamento sunday-night).

### `/prep-semanal review`
Modo review — preenche so secao "Review Domingo" da semana corrente. Usar sexta tarde.

### `/prep-semanal status`
Modo check-in — abre doc da semana corrente, mostra status atual (deadlines em risco, top 3 ainda nao iniciadas, etc). Nao reescreve, so reporta.

### `/prep-semanal W{N}`
Forca semana especifica (ex: `/prep-semanal W20` cria/abre semana 20).

## Regras

1. **Empresas dinamicas** — sempre glob `00-Brain/empresas/*.md`. NAO hardcode.
2. **Idempotente** — se rodar 2x na mesma semana, NAO sobrescreve. Apenas adiciona/atualiza campos.
3. **Soul-aligned** — pessoal nao e opcional. 4 pilares (corpo/mente/dinheiro/sonhos) sempre presentes.
4. **Sem floreio** — denso, acionavel, sem emojis salvo nos titulos canonicos do template.
5. **Linkar tudo** — wiki links bidirecionais. Brain v2 funciona por links.

## Chains (skills relacionadas)

Pode invocar/sugerir:
- `/weekly-innovagro` — apresentacao formal Innovagro (sexta 17:30)
- `/weekly` — review Impeto + Workflow (sexta 17:00)
- `/checkup` — 4 pilares pessoais (alimenta secao Pessoal)
- `/deadlines` — check de prazos ativos (alimenta secao Deadlines)
- `/team` — status do time (alimenta secao Time)
- `/capturar` — capturar ideia da semana

## Output esperado

```
PREP SEMANAL CRIADO

Semana: W18 (27/04 - 03/05/2026)
Path: 00-Brain/planning/2026/W18-prep-semanal.md
Empresas detectadas: impeto, innovagro, workflow (3 cadeiras)

ONE THING: Quarta 30/04 — bloquear 8h sagradas pra M4 LotAI com Robson

Top deadlines:
- Qua 30/04 → M4 LotAI Pair Robson (sagrado)
- Qui 01/05 → Estimulus semanal #2 + Resposta Claudione TN
- Sex 02/05 → Med Mais arquitetura + Weeklys

Pessoal: dentista pendente, sono curto domingo, treino retomar
Time: Joao 50% bandwidth (alerta), Robson 100%, Danilo 100%, Emanuel Mendes saindo ferias 04/05

Revise ONE THING + secao Pessoal antes de ativar a semana.
```

## Common mistakes

- Hardcode "Impeto + Innovagro + Workflow" — sempre descobrir via glob
- Pular a secao Pessoal "porque ele e operator" — Soul.md axioma 4 exige base solida
- Sobrescrever doc semanal corrente sem perguntar (perde trabalho do Joao)
- Esquecer de linkar diario dia-a-dia
- Criar fora de `00-Brain/planning/{ano}/` — local canonico

## Dominios

Tag: #prep-semanal #weekly #planning
