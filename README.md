# ImpetOS Skills

Skills para Claude Code com hooks de auto-ativação.

## Filosofia

**Skill sem hook = Skill que Claude esquece de usar.**

Toda skill é registrada em `skill-activator.sh` para ativação automática garantida.

## Instalação

```bash
# Via marketplace
/plugin marketplace add impetos/claude-skills-impeto
/plugin install impetos-skills@claude-skills-impeto
```

## Skills Incluídas

### TIER 1 - Core Development

| Skill | Trigger | Descrição |
|-------|---------|-----------|
| `skill-creator` | "criar skill", "/smith" | Cria novas skills + hooks |
| `test-driven-development` | "tdd", "test first" | RED-GREEN-REFACTOR cycle |
| `systematic-debugging` | "debug", "erro", "bug" | Root cause analysis 4 fases |
| `writing-plans` | "plan", "planejar" | Cria planos detalhados |
| `executing-plans` | "executar", "implementar" | Execução batch com checkpoints |

### TIER 2 - Collaboration

| Skill | Trigger | Descrição |
|-------|---------|-----------|
| `brainstorming` | "brainstorm", "ideias" | Refinamento socrático |
| `requesting-code-review` | "review", "PR pronto" | Pre-review checklist |
| `receiving-code-review` | "feedback review" | Processa review feedback |
| `dispatching-parallel-agents` | "parallel", "subagents" | Orquestra agents concorrentes |

### TIER 3 - Git/DevOps

| Skill | Trigger | Descrição |
|-------|---------|-----------|
| `using-git-worktrees` | "worktree", "branches paralelas" | Git worktrees management |
| `finishing-a-development-branch` | "merge", "finalizar branch" | Merge/PR workflow |
| `verification-before-completion` | "verify", "está pronto?" | Validação antes de fechar |

### TIER 4 - Agentic Graph-Based Switch

| Skill | Trigger | Descrição | Chain |
|-------|---------|-----------|-------|
| `brainstorming-agents` | "pesquisar agent", "agent patterns" | **WebSearch expert** for agent research | → graph-agent |
| `graph-agent` | "agent", "pydantic ai", "graph" | Build production agents | → audit |
| `agent-audit-graph` | "audit agent", "validar agent" | Heavy audit with context7 | → tester or /.debts/ |
| `agent-tester` | "testar agent", "mock llm" | TDD-inspired agent testing | End |
| `tool-specialist` | "tool", "function call" | Create agent tools | - |
| `agent-state-machine` | "state", "persistence", "checkpoint" | Durable state patterns | - |
| `agent-prompt-engineer` | "prompt", "system message" | Craft effective prompts | - |
| `agent-observability` | "observability", "tracing", "eval" | 5 pillars of observability | - |
| `agent-resilience` | "resilience", "retry", "fallback" | Fault tolerance patterns | - |
| `agent-multi-pattern` | "multi-agent", "supervisor", "swarm" | Multi-agent architectures | - |

#### Skill Chaining Flow

```
brainstorming-agents (WebSearch research)
       │
       ▼
graph-agent (creates/modifies agent)
       │
       ▼
agent-audit-graph (validates with context7)
       │
   ┌───┴───┐
   ▼       ▼
PASS    FAIL
   │       │
   ▼       ▼
agent-  /.debts/graph-agent/
tester  (debt documentation)
```

### TIER 5 - Development & DevOps

| Skill | Trigger | Descrição | Chain |
|-------|---------|-----------|-------|
| `brainstorming-dev` | "pesquisar tech", "qual framework" | **WebSearch expert** for tech research | - |
| `clean-code` | "refactor", "SOLID", "code smell" | SOLID principles, refactoring | → code-reviewer |
| `code-reviewer` | "review code", "analyze", "lint" | Automated code review | - |
| `testing-strategy` | "test pyramid", "coverage" | Test architecture | - |
| `ci-cd-pipeline` | "CI/CD", "GitHub Actions" | Pipeline automation | - |
| `deploy-railway` | "Railway", "railway up" | Railway deployment | - |
| `deploy-gcp` | "GCP", "Cloud Run", "gcloud" | GCP Cloud Run deploy | - |
| `docker-optimizer` | "Docker", "Dockerfile", "image size" | Dockerfile optimization | - |
| `database-migrations` | "migration", "schema change" | Safe migrations | - |
| `api-design` | "API design", "REST", "GraphQL" | API best practices | - |
| `security-hardening` | "security", "OWASP", "XSS" | Security patterns | - |

### TIER 6 - Business & Client Success

| Skill | Trigger | Descrição | Chain |
|-------|---------|-----------|-------|
| `brainstorming-business` | "pesquisar mercado", "concorrentes" | **WebSearch expert** for market research | - |
| `pricing-strategy` | "precificar", "pricing", "quanto cobrar" | Value-based pricing AI/SaaS | → proposal-builder |
| `client-discovery` | "discovery", "entender cliente", "requisitos" | Requirements gathering, JTBD | → proposal-builder |
| `proposal-builder` | "proposta", "orçamento", "SOW" | Create compelling proposals | → project-kickoff |
| `project-kickoff` | "kickoff", "início projeto" | Project kickoff checklist | → delivery-tracker |
| `delivery-tracker` | "entrega", "milestone", "status" | Milestone tracking, health | → client-communication |
| `client-communication` | "update cliente", "weekly update" | Status updates, templates | - |
| `scope-guardian` | "escopo", "scope creep", "change request" | Scope management, CR process | - |
| `retrospective` | "retro", "lessons learned", "post-mortem" | Sprint/project retrospectives | - |
| `business-metrics` | "métricas", "receita", "churn", "LTV" | Revenue, health scores, KPIs | - |
| `ai-product-strategy` | "estratégia AI", "MVP AI", "roadmap" | AI product vision, build vs buy | → pricing-strategy |

#### Business Flow

```
client-discovery ─────→ proposal-builder ─────→ project-kickoff
                              ↑                        │
pricing-strategy ─────────────┘                        ▼
       ↑                                        delivery-tracker
       │                                               │
ai-product-strategy                                    ▼
                                            client-communication
```

## Brainstorming Especializado (WebSearch Experts)

Cada tier tem um brainstorming especializado que usa **WebSearch agressivamente**:

| Skill | Tier | Foco | Pesquisa |
|-------|------|------|----------|
| `brainstorming` | 2 | General | Opções, trade-offs |
| `brainstorming-agents` | 4 | AI Agents | Frameworks, patterns, docs |
| `brainstorming-dev` | 5 | Development | Tech stack, benchmarks |
| `brainstorming-business` | 6 | Business | Market, competitors, pricing |

## Arquitetura

```
claude-skills-impeto/
├── .claude-plugin/
│   └── plugin.json         # Manifest do marketplace
├── hooks/
│   └── skill-activator.sh  # TODOS os triggers em um arquivo
├── skills/
│   ├── skill-creator/              # TIER 1 - Core
│   ├── test-driven-development/
│   ├── systematic-debugging/
│   ├── writing-plans/
│   ├── executing-plans/
│   ├── brainstorming/              # TIER 2 - Collaboration
│   ├── requesting-code-review/
│   ├── receiving-code-review/
│   ├── dispatching-parallel-agents/
│   ├── using-git-worktrees/        # TIER 3 - Git/DevOps
│   ├── finishing-a-development-branch/
│   ├── verification-before-completion/
│   ├── brainstorming-agents/       # TIER 4 - Agentic
│   ├── graph-agent/
│   ├── agent-audit-graph/
│   ├── agent-tester/
│   ├── tool-specialist/
│   ├── agent-state-machine/
│   ├── agent-prompt-engineer/
│   ├── agent-observability/
│   ├── agent-resilience/
│   ├── agent-multi-pattern/
│   ├── brainstorming-dev/          # TIER 5 - DevOps
│   ├── clean-code/
│   ├── code-reviewer/
│   ├── testing-strategy/
│   ├── ci-cd-pipeline/
│   ├── deploy-railway/
│   ├── deploy-gcp/
│   ├── docker-optimizer/
│   ├── database-migrations/
│   ├── api-design/
│   ├── security-hardening/
│   ├── brainstorming-business/     # TIER 6 - Business
│   ├── pricing-strategy/
│   ├── client-discovery/
│   ├── proposal-builder/
│   ├── project-kickoff/
│   ├── delivery-tracker/
│   ├── client-communication/
│   ├── scope-guardian/
│   ├── retrospective/
│   ├── business-metrics/
│   └── ai-product-strategy/        # 44 skills total
└── README.md
```

## Como Funciona

```
Você digita: "tenho um bug no login"
         │
         ▼
skill-activator.sh intercepta (UserPromptSubmit)
         │
         ▼
Regex match: "bug" → systematic-debugging
         │
         ▼
Injeta: "ACTIVATE SKILL: systematic-debugging"
         │
         ▼
Claude lê SKILL.md e segue instruções
         │
         ▼
Output: ⚡ SKILL_ACTIVATED: #DBG-3F7K
```

## Configuração do Hook

Copie para `.claude/hooks/skill-activator.sh` e adicione em `.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash .claude/hooks/skill-activator.sh"
        }]
      }
    ]
  }
}
```

## Criando Novas Skills

Use o skill-creator! Basta dizer:

```
"criar skill para gerenciar migrations"
```

O skill-creator vai:
1. Entrevistar sobre nome, propósito, keywords
2. Gerar SKILL.md no formato correto
3. Adicionar trigger no skill-activator.sh
4. Verificar instalação

## Skill Code Format

Cada skill tem um código único para rastreamento:

```
⚡ SKILL_ACTIVATED: #PREFIX-4CHR

Exemplos:
- #SMTH-8K2X (skill-creator/smith)
- #TDD-5A1B  (test-driven-development)
- #DBG-3F7K  (systematic-debugging)
- #GRPH-4A7X (graph-agent)
- #BRAG-5K2M (brainstorming-agents)
- #BRDV-8L4N (brainstorming-dev)
- #BRBS-2M7P (brainstorming-business)
- #PRIC-4N8Q (pricing-strategy)
- #DISC-7Q3R (client-discovery)
```

## Foco: AI Agents + Business

Skills otimizadas para:
- **Pydantic AI** - Schemas, agents, tools
- **LangGraph** - Multi-agent workflows
- **Postgres/Supabase** - Migrations, RLS, Edge Functions
- **Web/Mobile** - React, Next.js, React Native
- **Business** - Pricing, proposals, client success

## Licença

MIT - ImpetOS
