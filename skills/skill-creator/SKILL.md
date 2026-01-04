---
name: skill-creator
description: Use when user wants to create a new skill, automate a workflow, or mentions "criar skill", "nova skill", "create skill", "automatizar", "/smith". Creates skill WITH hook trigger and optional chaining.
---

# Skill Creator (Smith)

Creates new skills with hook triggers and intelligent chaining between skills.

## Core Principles

**One hook file, many skills.**
**Skills can chain to other skills automatically.**

All skill triggers live in `.claude/hooks/skill-activator.sh`.
When creating a skill, ADD a new `if` block with optional CHAIN instruction.

---

## Workflow

### STEP 1: Interview (ONE question at a time)

```
Q1: "Nome da skill? (kebab-case, ex: supabase-migrations)"

Q2: "O que essa skill deve fazer? Descreva o comportamento."

Q3: "Quais palavras-chave ativam essa skill?"
    (ex: supabase, migration, database, sql)
    Formato regex: \bsupabase\b|migra[çc][aã]o|database

Q4: "Onde salvar?"
    - projeto (.claude/skills/)
    - pessoal (~/.claude/skills/)

Q5: "Essa skill encadeia para outra skill após execução?"
    - NÃO → skill independente
    - SIM → qual skill? (ex: após criar agent → audit-agent)

    Exemplos de encadeamento:
    - graph-agent → agent-audit-graph (build then audit)
    - agent-audit-graph → agent-tester (if passes)
    - agent-audit-graph → /.debts/{skill}/ (if fails, create debt doc)
```

### STEP 2: Generate SKILL.md

Create `{location}/skills/{skill-name}/SKILL.md`:

```markdown
---
name: {skill-name}
description: Use when {trigger conditions}. Activates for: {keywords}.
chain: {next-skill | none}
---

# {Skill Title}

{Descrição em 1-2 frases}

## When to Use
- {Trigger 1}
- {Trigger 2}
- NOT when: {quando não usar}

## Instructions
{Instruções detalhadas}

## Examples
{Exemplos práticos}

## Chain Behavior
{Se chain != none}
After completing this skill:
→ AUTOMATICALLY trigger: {next-skill}
→ Pass context: {what context to pass}

{Se chain com condição}
- ON SUCCESS → {skill-on-success}
- ON FAILURE → {action-on-failure | create debt doc}

## Common Mistakes
- {Erro 1}
- {Erro 2}
```

### STEP 3: Update skill-activator.sh

**Location:** `.claude/hooks/skill-activator.sh` or `~/.claude/hooks/skill-activator.sh`

#### Without Chain (Independent Skill):

```bash
# {SKILL-NAME-UPPERCASE}
if echo "$prompt_lower" | grep -qE '{regex-pattern}'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: {skill-name}\nREAD: .claude/skills/{skill-name}/SKILL.md\nFOLLOW: {brief-instruction}\nOUTPUT: ⚡ SKILL_ACTIVATED: #{CODE-4CHR}\n</skill-instruction>"
      }
    }'
    exit 0
fi
```

#### With Chain (Linked Skill):

```bash
# {SKILL-NAME-UPPERCASE} (Primary - chains to {next-skill})
if echo "$prompt_lower" | grep -qE '{regex-pattern}'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: {skill-name}\nREAD: .claude/skills/{skill-name}/SKILL.md\nFOLLOW: {brief-instruction}\nCHAIN: After completion → {next-skill}\nOUTPUT: ⚡ SKILL_ACTIVATED: #{CODE-4CHR}\n</skill-instruction>"
      }
    }'
    exit 0
fi
```

#### With Conditional Chain:

```bash
# {SKILL-NAME-UPPERCASE} (Chains conditionally)
if echo "$prompt_lower" | grep -qE '{regex-pattern}'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: {skill-name}\nREAD: .claude/skills/{skill-name}/SKILL.md\nFOLLOW: {brief-instruction}\nCHAIN: If PASS → {skill-on-success} | If FAIL → /.debts/{skill-name}/\nOUTPUT: ⚡ SKILL_ACTIVATED: #{CODE-4CHR}\n</skill-instruction>"
      }
    }'
    exit 0
fi
```

---

## Chain Types

### Type 1: Sequential Chain
```
skill-A → skill-B → skill-C
```
Each skill triggers the next after completion.

**Example:**
```
graph-agent → agent-audit-graph → agent-tester
```

### Type 2: Conditional Chain
```
skill-A
   │
   ├─ PASS → skill-B
   └─ FAIL → action (create debt doc)
```
Next skill depends on outcome.

**Example:**
```
agent-audit-graph
   │
   ├─ PASS → agent-tester
   └─ FAIL → /.debts/graph-agent/
```

### Type 3: Fan-Out Chain
```
skill-A
   │
   ├→ skill-B (parallel)
   └→ skill-C (parallel)
```
Trigger multiple skills concurrently.

**Example:**
```
build-feature
   │
   ├→ run-tests
   └→ update-docs
```

---

## Debt Tracking System

When a skill fails audit, create debt documentation:

```
/.debts/
└── {skill-name}/
    └── {timestamp}-{issue}.md
```

**Debt Document Template:**
```markdown
---
created: {ISO timestamp}
skill: {skill-name}
severity: high|medium|low
status: open
---

# Debt: {Issue Title}

## Context
{What was being attempted}

## Failure Reason
{Why the audit failed}

## Required Actions
- [ ] {action-1}
- [ ] {action-2}

## References
- Trace ID: {if available}
- Files affected: {list}
```

---

## Chain Configuration Examples

### Example 1: Agent Development Chain

```
graph-agent
    │ creates/modifies agent code
    ▼
agent-audit-graph
    │ validates with context7
    ├─ PASS ─▶ agent-tester
    │              │ runs agent tests
    │              ▼
    │           DONE ✓
    │
    └─ FAIL ─▶ /.debts/graph-agent/
                   │ creates debt doc
                   ▼
                BLOCKED ✗
```

**skill-activator.sh entries:**

```bash
# GRAPH-AGENT (chains to audit)
if echo "$prompt_lower" | grep -qE '\bagent\b|pydantic.?ai|graph.?agent'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: graph-agent\nREAD: .claude/skills/graph-agent/SKILL.md\nFOLLOW: Build production-ready agent\nCHAIN: After changes → agent-audit-graph\nOUTPUT: ⚡ SKILL_ACTIVATED: #GRPH-4A7X\n</skill-instruction>"
      }
    }'
    exit 0
fi

# AGENT-AUDIT-GRAPH (conditional chain)
if echo "$prompt_lower" | grep -qE 'audit.?agent|validar.?agent'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "<skill-instruction>\nACTIVATE SKILL: agent-audit-graph\nREAD: .claude/skills/agent-audit-graph/SKILL.md\nFOLLOW: Heavy audit with context7\nCHAIN: If PASS → agent-tester | If FAIL → /.debts/graph-agent/\nOUTPUT: ⚡ SKILL_ACTIVATED: #AUDT-8K3M\n</skill-instruction>"
      }
    }'
    exit 0
fi
```

### Example 2: Feature Development Chain

```
writing-plans
    │ creates plan.md
    ▼
executing-plans
    │ implements features
    ▼
verification-before-completion
    │ validates implementation
    ▼
DONE ✓
```

---

## Verification Checklist

```
[ ] SKILL.md created with chain: field in frontmatter
[ ] skill-activator.sh has CHAIN instruction if chained
[ ] Chain target skill exists
[ ] Conditional chains have PASS/FAIL paths defined
[ ] Debt folder path is correct (/.debts/{skill-name}/)
[ ] Regex pattern tested
[ ] Skill code is unique
[ ] chmod +x on skill-activator.sh
```

---

## Regex Pattern Guidelines

| Keywords | Regex Pattern |
|----------|---------------|
| supabase, migration | `\bsupabase\b\|migra[çc][aã]o` |
| kestra, flow | `\bkestra\b\|flow\|workflow` |
| agent, pydantic | `\bagent\b\|pydantic.?ai` |
| audit, validate | `audit.?agent\|validar` |

**Tips:**
- Use `\b` for word boundaries
- Use `[çc][aã]` for Portuguese accents
- Use `.*` or `.?` for flexible matching
- Use `\|` to separate alternatives

---

## Skill Code Format

Generate unique 8-char code: `#{PREFIX}-{4ALPHANUM}`

Examples:
- `#SMTH-8K2X` (smith/skill-creator)
- `#GRPH-4A7X` (graph-agent)
- `#AUDT-8K3M` (agent-audit-graph)
- `#TSTR-6B2N` (agent-tester)

---

## Important Rules

1. **ALWAYS edit existing skill-activator.sh** - never create separate hook files
2. **Add CHAIN instruction** when skill should trigger another
3. **Define PASS/FAIL paths** for audit/validation skills
4. **Create /.debts/ folder** automatically when needed
5. **Test chain flow** end-to-end before finalizing
6. **Unique skill codes** - check existing before generating
7. **chmod +x** after modifying skill-activator.sh
