#!/bin/bash
# ImpetOS Skill Activator
# Auto-activates skills based on keywords in user prompt
# Location: .claude/hooks/skill-activator.sh or ~/.claude/hooks/skill-activator.sh

# Read JSON from stdin
input=$(cat)

# Extract prompt from JSON
prompt=$(echo "$input" | jq -r '.prompt // .user_prompt // empty' 2>/dev/null)

# If extraction failed, use raw input
if [ -z "$prompt" ]; then
    prompt="$input"
fi

# Convert to lowercase for matching
prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

# =============================================================================
# SKILL TRIGGERS - ImpetOS Core Skills
# Format: pattern → skill-name → instruction
# =============================================================================

# SKILL-CREATOR
if echo "$prompt_lower" | grep -qE '/smith|criar skill|nova skill|create skill|automatizar|new skill'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: skill-creator\nREAD: .claude/skills/skill-creator/SKILL.md\nFOLLOW: Interview user, create SKILL.md, update skill-activator.sh\nOUTPUT: ⚡ SKILL_ACTIVATED: #SMTH-8K2X\n</skill-instruction>"
      }
    }'
    exit 0
fi

# TEST-DRIVEN-DEVELOPMENT
if echo "$prompt_lower" | grep -qE '\btdd\b|test.?first|teste.?primeiro|red.?green|test.?driven|escrever teste'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: test-driven-development\nREAD: .claude/skills/test-driven-development/SKILL.md\nFOLLOW: RED-GREEN-REFACTOR cycle strictly\nOUTPUT: ⚡ SKILL_ACTIVATED: #TDD-5A1B\n</skill-instruction>"
      }
    }'
    exit 0
fi

# SYSTEMATIC-DEBUGGING
if echo "$prompt_lower" | grep -qE '\bdebug|erro|n[aã]o.?funciona|\bbug\b|quebrou|failing|exception|traceback|stack.?trace'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: systematic-debugging\nREAD: .claude/skills/systematic-debugging/SKILL.md\nFOLLOW: Four-phase debugging: REPRODUCE → ISOLATE → IDENTIFY → FIX\nOUTPUT: ⚡ SKILL_ACTIVATED: #DBG-3F7K\n</skill-instruction>"
      }
    }'
    exit 0
fi

# WRITING-PLANS
if echo "$prompt_lower" | grep -qE '\bplan\b|plano|planejar|roadmap|arquitetura|design.*system|como.?implementar|strategy'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: writing-plans\nREAD: .claude/skills/writing-plans/SKILL.md\nFOLLOW: Create detailed plan with phases, tasks, checkpoints\nOUTPUT: ⚡ SKILL_ACTIVATED: #PLAN-2X9M\n</skill-instruction>"
      }
    }'
    exit 0
fi

# EXECUTING-PLANS
if echo "$prompt_lower" | grep -qE 'executar|execute.?plan|implementar.?plano|rodar.?plano|seguir.?plano|continuar.?plano'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: executing-plans\nREAD: .claude/skills/executing-plans/SKILL.md\nFOLLOW: Batch execution with checkpoints, track progress\nOUTPUT: ⚡ SKILL_ACTIVATED: #EXEC-7B4N\n</skill-instruction>"
      }
    }'
    exit 0
fi

# BRAINSTORMING
if echo "$prompt_lower" | grep -qE '\bbrainstorm|ideias|pensar.?sobre|explorar.?op[çc][õo]es|alternativas|como.?fazer|op[çc][õo]es'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: brainstorming\nREAD: .claude/skills/brainstorming/SKILL.md\nFOLLOW: Socratic questioning, explore multiple options before deciding\nOUTPUT: ⚡ SKILL_ACTIVATED: #BRST-6C2P\n</skill-instruction>"
      }
    }'
    exit 0
fi

# REQUESTING-CODE-REVIEW
if echo "$prompt_lower" | grep -qE 'review.*c[oó]digo|code.?review|revisar.?pr|\bpr\b.*pronto|pull.?request|pronto.?para.?review|pre.?review'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: requesting-code-review\nREAD: .claude/skills/requesting-code-review/SKILL.md\nFOLLOW: Complete pre-review checklist before requesting\nOUTPUT: ⚡ SKILL_ACTIVATED: #RREQ-4D8S\n</skill-instruction>"
      }
    }'
    exit 0
fi

# RECEIVING-CODE-REVIEW
if echo "$prompt_lower" | grep -qE 'feedback.*review|review.?comments|addressing.?review|reviewer.?disse|comentarios.?review|responder.?review'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: receiving-code-review\nREAD: .claude/skills/receiving-code-review/SKILL.md\nFOLLOW: Categorize feedback, address systematically, respond constructively\nOUTPUT: ⚡ SKILL_ACTIVATED: #RRCV-1E5T\n</skill-instruction>"
      }
    }'
    exit 0
fi

# DISPATCHING-PARALLEL-AGENTS
if echo "$prompt_lower" | grep -qE '\bparallel|paralelo|concurrent|subagents|em.?paralelo|agents?.?simultaneo|fan.?out|multi.?agent'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: dispatching-parallel-agents\nREAD: .claude/skills/dispatching-parallel-agents/SKILL.md\nFOLLOW: Dispatch concurrent agents with clear boundaries and sync points\nOUTPUT: ⚡ SKILL_ACTIVATED: #PARA-9F1U\n</skill-instruction>"
      }
    }'
    exit 0
fi

# USING-GIT-WORKTREES
if echo "$prompt_lower" | grep -qE '\bworktree|branches?.?paralel|parallel.?branch|multiple.?features|trabalhar.?em.?paralelo'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: using-git-worktrees\nREAD: .claude/skills/using-git-worktrees/SKILL.md\nFOLLOW: Manage git worktrees for parallel development\nOUTPUT: ⚡ SKILL_ACTIVATED: #GWTK-3G6V\n</skill-instruction>"
      }
    }'
    exit 0
fi

# FINISHING-A-DEVELOPMENT-BRANCH
if echo "$prompt_lower" | grep -qE '\bmerge\b|finalizar.?branch|terminar.?feature|ready.?to.?merge|fechar.?pr|completar.?branch'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: finishing-a-development-branch\nREAD: .claude/skills/finishing-a-development-branch/SKILL.md\nFOLLOW: Pre-merge checks, create PR, merge, cleanup\nOUTPUT: ⚡ SKILL_ACTIVATED: #FDBR-8H2W\n</skill-instruction>"
      }
    }'
    exit 0
fi

# VERIFICATION-BEFORE-COMPLETION
if echo "$prompt_lower" | grep -qE '\bverify|verificar|est[aá].?pronto|funcionando|testar.?final|confirmar.?que|done\?|complete\?'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: verification-before-completion\nREAD: .claude/skills/verification-before-completion/SKILL.md\nFOLLOW: Complete verification checklist before marking done\nOUTPUT: ⚡ SKILL_ACTIVATED: #VRFY-5J9X\n</skill-instruction>"
      }
    }'
    exit 0
fi

# =============================================================================
# TIER 4 - AGENTIC GRAPH-BASED SWITCH
# =============================================================================

# BRAINSTORMING-AGENTS (WebSearch specialist for agent research - chains to graph-agent)
if echo "$prompt_lower" | grep -qE 'pesquisar.?agent|agent.?patterns|qual.?framework.?agent|comparar.?agents|research.?agent'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: brainstorming-agents\nREAD: .claude/skills/brainstorming-agents/SKILL.md\nFOLLOW: You are a WebSearch EXPERT. Use WebSearch aggressively to research agent patterns, frameworks, best practices.\nCHAIN: After research → graph-agent\nOUTPUT: ⚡ SKILL_ACTIVATED: #BRAG-5K2M\n</skill-instruction>"
      }
    }'
    exit 0
fi

# GRAPH-AGENT (Primary - chains to audit)
if echo "$prompt_lower" | grep -qE '\bagent\b|pydantic.?ai|graph.?agent|criar.?agent|build.?agent|novo.?agente|state.?machine'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: graph-agent\nREAD: .claude/skills/graph-agent/SKILL.md\nFOLLOW: Build production-ready agent with Pydantic AI Graph\nCHAIN: After changes → agent-audit-graph\nOUTPUT: ⚡ SKILL_ACTIVATED: #GRPH-4A7X\n</skill-instruction>"
      }
    }'
    exit 0
fi

# AGENT-AUDIT-GRAPH (Auditor with context7)
if echo "$prompt_lower" | grep -qE 'audit.?agent|revisar.?agent|validar.?agent|checar.?agent|agent.?review'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: agent-audit-graph\nREAD: .claude/skills/agent-audit-graph/SKILL.md\nFOLLOW: Heavy audit with context7, create /.debts/ if fails\nCHAIN: If pass → agent-tester | If fail → /.debts/graph-agent/\nOUTPUT: ⚡ SKILL_ACTIVATED: #AUDT-8K3M\n</skill-instruction>"
      }
    }'
    exit 0
fi

# AGENT-TESTER (TDD for agents)
if echo "$prompt_lower" | grep -qE 'testar.?agent|test.?agent|agent.?test|mock.?llm|agent.?coverage'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: agent-tester\nREAD: .claude/skills/agent-tester/SKILL.md\nFOLLOW: Build and run agent tests with mocked LLM\nOUTPUT: ⚡ SKILL_ACTIVATED: #TSTR-6B2N\n</skill-instruction>"
      }
    }'
    exit 0
fi

# TOOL-SPECIALIST
if echo "$prompt_lower" | grep -qE '\btool\b|ferramenta|function.?call|criar.?tool|tool.?agent|nova.?tool'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: tool-specialist\nREAD: .claude/skills/tool-specialist/SKILL.md\nFOLLOW: Create tools with proper schemas and error handling\nOUTPUT: ⚡ SKILL_ACTIVATED: #TOOL-3C9P\n</skill-instruction>"
      }
    }'
    exit 0
fi

# AGENT-STATE-MACHINE
if echo "$prompt_lower" | grep -qE '\bstate\b|persistence|checkpoint|durability|recovery|snapshot|resumable'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: agent-state-machine\nREAD: .claude/skills/agent-state-machine/SKILL.md\nFOLLOW: Implement durable state persistence and checkpointing\nOUTPUT: ⚡ SKILL_ACTIVATED: #STMC-7D4Q\n</skill-instruction>"
      }
    }'
    exit 0
fi

# AGENT-PROMPT-ENGINEER
if echo "$prompt_lower" | grep -qE '\bprompt\b|system.?message|schema.?output|instru[çc][õo]es.?agent|structured.?output'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: agent-prompt-engineer\nREAD: .claude/skills/agent-prompt-engineer/SKILL.md\nFOLLOW: Craft effective prompts and structured output schemas\nOUTPUT: ⚡ SKILL_ACTIVATED: #PRMT-2E8R\n</skill-instruction>"
      }
    }'
    exit 0
fi

# AGENT-OBSERVABILITY
if echo "$prompt_lower" | grep -qE 'observability|tracing|monitoring|\blogs\b|metrics|\beval\b|langfuse|logfire'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: agent-observability\nREAD: .claude/skills/agent-observability/SKILL.md\nFOLLOW: Implement 5 pillars: traces, evals, human review, alerts, data engine\nOUTPUT: ⚡ SKILL_ACTIVATED: #OBSV-5F1K\n</skill-instruction>"
      }
    }'
    exit 0
fi

# AGENT-RESILIENCE
if echo "$prompt_lower" | grep -qE 'resilience|\bretry\b|fallback|circuit.?breaker|error.?handling|backoff|rate.?limit'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: agent-resilience\nREAD: .claude/skills/agent-resilience/SKILL.md\nFOLLOW: Implement retry, fallback, circuit breaker patterns\nOUTPUT: ⚡ SKILL_ACTIVATED: #RSLN-9G3L\n</skill-instruction>"
      }
    }'
    exit 0
fi

# AGENT-MULTI-PATTERN
if echo "$prompt_lower" | grep -qE 'multi.?agent|supervisor|swarm|routing|orchestrator|agents?.?coordination|hierarchy'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: agent-multi-pattern\nREAD: .claude/skills/agent-multi-pattern/SKILL.md\nFOLLOW: Design multi-agent system with appropriate pattern\nOUTPUT: ⚡ SKILL_ACTIVATED: #MLTI-4H7N\n</skill-instruction>"
      }
    }'
    exit 0
fi

# =============================================================================
# TIER 5 - DEVELOPMENT & DEVOPS
# =============================================================================

# BRAINSTORMING-DEV (WebSearch specialist for tech research)
if echo "$prompt_lower" | grep -qE 'pesquisar.?tech|qual.?framework|comparar.?tecnolog|stack.?decision|tech.?research|qual.?usar'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: brainstorming-dev\nREAD: .claude/skills/brainstorming-dev/SKILL.md\nFOLLOW: You are a WebSearch EXPERT. Use WebSearch aggressively to research frameworks, libraries, best practices 2025.\nOUTPUT: ⚡ SKILL_ACTIVATED: #BRDV-8L4N\n</skill-instruction>"
      }
    }'
    exit 0
fi

# CLEAN-CODE (chains to code-reviewer)
if echo "$prompt_lower" | grep -qE 'clean.?code|refactor|\\bsolid\\b|code.?smell|technical.?debt|refatora'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: clean-code\nREAD: .claude/skills/clean-code/SKILL.md\nFOLLOW: Apply SOLID principles and refactoring patterns\nCHAIN: After refactoring → code-reviewer\nOUTPUT: ⚡ SKILL_ACTIVATED: #CLEN-7A3X\n</skill-instruction>"
      }
    }'
    exit 0
fi

# CODE-REVIEWER
if echo "$prompt_lower" | grep -qE 'review.?this.?code|check.?quality|analyze.?code|\\blint\\b|code.?analysis|revisar.?codigo'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: code-reviewer\nREAD: .claude/skills/code-reviewer/SKILL.md\nFOLLOW: Automated code review for quality and security\nOUTPUT: ⚡ SKILL_ACTIVATED: #RVWR-4B8K\n</skill-instruction>"
      }
    }'
    exit 0
fi

# TESTING-STRATEGY
if echo "$prompt_lower" | grep -qE 'testing.?strategy|test.?coverage|test.?pyramid|how.?to.?test|which.?tests|estrategia.?teste'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: testing-strategy\nREAD: .claude/skills/testing-strategy/SKILL.md\nFOLLOW: Design test strategy with proper coverage\nOUTPUT: ⚡ SKILL_ACTIVATED: #TEST-9C2M\n</skill-instruction>"
      }
    }'
    exit 0
fi

# CI-CD-PIPELINE
if echo "$prompt_lower" | grep -qE '\\bci.?cd\\b|github.?actions|pipeline|workflow.?yaml|deploy.?automation|automat.*deploy'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: ci-cd-pipeline\nREAD: .claude/skills/ci-cd-pipeline/SKILL.md\nFOLLOW: Setup CI/CD with GitHub Actions\nOUTPUT: ⚡ SKILL_ACTIVATED: #CICD-6D4P\n</skill-instruction>"
      }
    }'
    exit 0
fi

# DEPLOY-RAILWAY
if echo "$prompt_lower" | grep -qE '\\brailway\\b|railway.?up|deploy.?railway|railway.?deploy'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: deploy-railway\nREAD: .claude/skills/deploy-railway/SKILL.md\nFOLLOW: Deploy to Railway with best practices\nOUTPUT: ⚡ SKILL_ACTIVATED: #RAIL-5E7Q\n</skill-instruction>"
      }
    }'
    exit 0
fi

# DEPLOY-GCP
if echo "$prompt_lower" | grep -qE '\\bgcp\\b|cloud.?run|\\bgcloud\\b|google.?cloud|deploy.?gcp'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: deploy-gcp\nREAD: .claude/skills/deploy-gcp/SKILL.md\nFOLLOW: Deploy to GCP Cloud Run\nOUTPUT: ⚡ SKILL_ACTIVATED: #GCP-8F3R\n</skill-instruction>"
      }
    }'
    exit 0
fi

# DOCKER-OPTIMIZER
if echo "$prompt_lower" | grep -qE '\\bdocker\\b|dockerfile|container|image.?size|docker.?build|otimizar.?docker'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: docker-optimizer\nREAD: .claude/skills/docker-optimizer/SKILL.md\nFOLLOW: Optimize Dockerfile and reduce image size\nOUTPUT: ⚡ SKILL_ACTIVATED: #DOCK-2G5S\n</skill-instruction>"
      }
    }'
    exit 0
fi

# DATABASE-MIGRATIONS
if echo "$prompt_lower" | grep -qE 'migra[çc][aã]o|schema.?change|database.?migration|alter.?table|prisma.?migrate|drizzle'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: database-migrations\nREAD: .claude/skills/database-migrations/SKILL.md\nFOLLOW: Safe database migration patterns\nOUTPUT: ⚡ SKILL_ACTIVATED: #MIGR-4H6T\n</skill-instruction>"
      }
    }'
    exit 0
fi

# API-DESIGN
if echo "$prompt_lower" | grep -qE 'api.?design|\\brest\\b|\\bgraphql\\b|endpoint|schema.?design|api.?contract'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: api-design\nREAD: .claude/skills/api-design/SKILL.md\nFOLLOW: Design RESTful or GraphQL APIs\nOUTPUT: ⚡ SKILL_ACTIVATED: #API-7J2K\n</skill-instruction>"
      }
    }'
    exit 0
fi

# SECURITY-HARDENING
if echo "$prompt_lower" | grep -qE '\\bsecurity\\b|\\bowasp\\b|vulnerabilit|authenticat|authorizat|\\bxss\\b|sql.?injection|seguran[çc]a'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: security-hardening\nREAD: .claude/skills/security-hardening/SKILL.md\nFOLLOW: Apply security best practices (OWASP)\nOUTPUT: ⚡ SKILL_ACTIVATED: #SEC-3K8L\n</skill-instruction>"
      }
    }'
    exit 0
fi

# =============================================================================
# TIER 6 - BUSINESS & CLIENT SUCCESS
# =============================================================================

# BRAINSTORMING-BUSINESS (WebSearch specialist for market research)
if echo "$prompt_lower" | grep -qE 'pesquisar.?mercado|concorrentes|pricing.?research|estrat[eé]gia.?neg[oó]cio|business.?model|market.?research'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: brainstorming-business\nREAD: .claude/skills/brainstorming-business/SKILL.md\nFOLLOW: You are a WebSearch EXPERT. Use WebSearch aggressively to research market, competitors, pricing, trends.\nOUTPUT: ⚡ SKILL_ACTIVATED: #BRBS-2M7P\n</skill-instruction>"
      }
    }'
    exit 0
fi

# PRICING-STRATEGY (chains to proposal-builder)
if echo "$prompt_lower" | grep -qE 'precifi|pricing|quanto.?cobrar|modelo.?pre[çc]o|price.?point|tabela.?pre[çc]o'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: pricing-strategy\nREAD: .claude/skills/pricing-strategy/SKILL.md\nFOLLOW: Define value-based pricing for AI/software products\nCHAIN: After pricing → proposal-builder\nOUTPUT: ⚡ SKILL_ACTIVATED: #PRIC-4N8Q\n</skill-instruction>"
      }
    }'
    exit 0
fi

# CLIENT-DISCOVERY (chains to proposal-builder)
if echo "$prompt_lower" | grep -qE 'discovery|entender.?cliente|requisitos|first.?meeting|kickoff.?cliente|levantar.?requisitos'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: client-discovery\nREAD: .claude/skills/client-discovery/SKILL.md\nFOLLOW: Guide discovery process, gather requirements\nCHAIN: After discovery → proposal-builder\nOUTPUT: ⚡ SKILL_ACTIVATED: #DISC-7Q3R\n</skill-instruction>"
      }
    }'
    exit 0
fi

# PROPOSAL-BUILDER (chains to project-kickoff)
if echo "$prompt_lower" | grep -qE 'proposta|or[çc]amento|quote|\\bsow\\b|escopo.?projeto|fazer.?proposta'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: proposal-builder\nREAD: .claude/skills/proposal-builder/SKILL.md\nFOLLOW: Create compelling proposal with scope and pricing\nCHAIN: After accepted → project-kickoff\nOUTPUT: ⚡ SKILL_ACTIVATED: #PROP-9R5S\n</skill-instruction>"
      }
    }'
    exit 0
fi

# PROJECT-KICKOFF (chains to delivery-tracker)
if echo "$prompt_lower" | grep -qE 'kickoff|in[ií]cio.?projeto|start.?project|onboarding.?cliente|come[çc]ar.?projeto'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: project-kickoff\nREAD: .claude/skills/project-kickoff/SKILL.md\nFOLLOW: Execute kickoff checklist, set expectations\nCHAIN: After kickoff → delivery-tracker\nOUTPUT: ⚡ SKILL_ACTIVATED: #KICK-3T6U\n</skill-instruction>"
      }
    }'
    exit 0
fi

# DELIVERY-TRACKER (chains to client-communication)
if echo "$prompt_lower" | grep -qE 'entrega|milestone|status.?projeto|acompanhar|tracking|rastrear.?projeto'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: delivery-tracker\nREAD: .claude/skills/delivery-tracker/SKILL.md\nFOLLOW: Track milestones, manage deliveries\nCHAIN: For updates → client-communication\nOUTPUT: ⚡ SKILL_ACTIVATED: #DELV-5U8V\n</skill-instruction>"
      }
    }'
    exit 0
fi

# CLIENT-COMMUNICATION
if echo "$prompt_lower" | grep -qE 'update.?cliente|weekly.?update|comunicar.?cliente|status.?report|email.?cliente'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: client-communication\nREAD: .claude/skills/client-communication/SKILL.md\nFOLLOW: Create professional client communication\nOUTPUT: ⚡ SKILL_ACTIVATED: #COMM-6W9X\n</skill-instruction>"
      }
    }'
    exit 0
fi

# SCOPE-GUARDIAN
if echo "$prompt_lower" | grep -qE 'escopo|scope.?creep|change.?request|fora.?do.?escopo|mudan[çc]a.?requisito|scope.?change'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: scope-guardian\nREAD: .claude/skills/scope-guardian/SKILL.md\nFOLLOW: Evaluate scope changes, prevent scope creep\nOUTPUT: ⚡ SKILL_ACTIVATED: #SCPE-7X2Y\n</skill-instruction>"
      }
    }'
    exit 0
fi

# RETROSPECTIVE
if echo "$prompt_lower" | grep -qE '\\bretro\\b|lessons.?learned|retrospectiva|post.?mortem|fechamento.?projeto|o.?que.?aprendemos'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: retrospective\nREAD: .claude/skills/retrospective/SKILL.md\nFOLLOW: Facilitate retrospective, capture learnings\nOUTPUT: ⚡ SKILL_ACTIVATED: #RETR-8Y4Z\n</skill-instruction>"
      }
    }'
    exit 0
fi

# BUSINESS-METRICS
if echo "$prompt_lower" | grep -qE 'm[eé]tricas|receita|revenue|\\bchurn\\b|\\bltv\\b|health.?score|kpis?.?neg[oó]cio|mrr|arr'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: business-metrics\nREAD: .claude/skills/business-metrics/SKILL.md\nFOLLOW: Track and analyze business metrics\nOUTPUT: ⚡ SKILL_ACTIVATED: #METR-9Z5A\n</skill-instruction>"
      }
    }'
    exit 0
fi

# AI-PRODUCT-STRATEGY (chains to pricing-strategy)
if echo "$prompt_lower" | grep -qE 'estrat[eé]gia.?ai|produto.?ai|mvp.?ai|roadmap.?produto|ai.?use.?case|produto.?intelig[eê]ncia'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: ai-product-strategy\nREAD: .claude/skills/ai-product-strategy/SKILL.md\nFOLLOW: Define AI product strategy, MVP, roadmap\nCHAIN: After product defined → pricing-strategy\nOUTPUT: ⚡ SKILL_ACTIVATED: #AIST-2B6C\n</skill-instruction>"
      }
    }'
    exit 0
fi

# =============================================================================
# No match - continue normally
# =============================================================================
exit 0
