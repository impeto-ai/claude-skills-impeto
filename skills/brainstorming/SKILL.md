---
name: brainstorming
description: Use when exploring ideas, user mentions "brainstorm", "ideias", "pensar", "explorar", "alternativas", "como fazer". Socratic refinement through questioning.
---

# Brainstorming

Socratic design refinement - explores ideas through structured questioning before committing to solutions.

## When to Use

- Exploring new feature ideas
- Unclear requirements
- Multiple valid approaches
- User says: brainstorm, ideias, pensar, explorar, alternativas
- Before writing-plans (brainstorm → plan → execute)
- NOT when: requirements are crystal clear

## The Process

```
┌─────────────────────────────────────────────────┐
│  1. UNDERSTAND                                  │
│     What are we trying to solve?                │
├─────────────────────────────────────────────────┤
│  2. EXPAND                                      │
│     Generate multiple options                   │
├─────────────────────────────────────────────────┤
│  3. EVALUATE                                    │
│     Compare tradeoffs                           │
├─────────────────────────────────────────────────┤
│  4. REFINE                                      │
│     Converge on best approach                   │
└─────────────────────────────────────────────────┘
```

## Socratic Questioning

Ask before assuming:

### Understanding Questions
```
- "O que você está tentando alcançar com isso?"
- "Qual problema específico isso resolve?"
- "Quem são os usuários?"
- "Quais são as restrições (tempo, tech, budget)?"
```

### Exploration Questions
```
- "Você já considerou [alternativa]?"
- "E se fizéssemos [opção diferente]?"
- "Quais são os riscos de [abordagem]?"
- "O que acontece se [cenário]?"
```

### Evaluation Questions
```
- "Entre A e B, qual prioriza mais [critério]?"
- "Qual é o MVP mínimo aqui?"
- "O que podemos deixar para v2?"
```

## Brainstorm Template

```markdown
# Brainstorm: [Topic]

## Problem Statement
[1-2 sentences defining the core problem]

## Context
- User: [Who]
- Constraints: [Time, tech, resources]
- Must have: [Non-negotiable requirements]
- Nice to have: [Optional features]

## Options Explored

### Option A: [Name]
**Approach:** [Brief description]
**Pros:**
- Pro 1
- Pro 2
**Cons:**
- Con 1
- Con 2
**Effort:** [S/M/L/XL]

### Option B: [Name]
**Approach:** [Brief description]
**Pros:**
- Pro 1
- Pro 2
**Cons:**
- Con 1
- Con 2
**Effort:** [S/M/L/XL]

### Option C: [Name]
[Same structure]

## Comparison Matrix

| Criteria | Option A | Option B | Option C |
|----------|----------|----------|----------|
| Complexity | ⭐⭐ | ⭐⭐⭐ | ⭐ |
| Scalability | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| Time to build | ⭐⭐ | ⭐ | ⭐⭐⭐ |
| Maintainability | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ |

## Recommendation
**Go with Option [X] because:**
- Reason 1
- Reason 2

## Open Questions
- [ ] Question 1 (needs user input)
- [ ] Question 2 (needs research)

## Next Steps
1. [First action]
2. [Second action]
```

## For AI Agent Architecture

```markdown
### Agent Architecture Options

#### Option A: Single Agent
- One agent handles everything
- Simple but limited
- Good for: prototypes, simple tasks

#### Option B: Multi-Agent (Sequential)
- Agents in pipeline: A → B → C
- Each agent specialized
- Good for: clear workflows

#### Option C: Multi-Agent (Graph)
- Agents as nodes, dynamic routing
- Most flexible, most complex
- Good for: complex reasoning, branching logic

#### Option D: Hybrid
- Orchestrator + specialized sub-agents
- Balance of flexibility and simplicity
- Good for: production systems

### Decision Factors
- Task complexity?
- Need for parallelism?
- Error recovery needs?
- Observability requirements?
```

## For Database Design

```markdown
### Data Model Options

#### Option A: Normalized (3NF)
- Proper normalization
- More joins, less duplication
- Good for: complex queries, data integrity

#### Option B: Denormalized
- Fewer joins, more duplication
- Faster reads, harder updates
- Good for: read-heavy, analytics

#### Option C: Hybrid (JSONB columns)
- Structured + flexible
- Best of both worlds
- Good for: varying schemas, user preferences

### Decision Factors
- Query patterns?
- Update frequency?
- Data consistency needs?
- Scale expectations?
```

## For Tech Stack

```markdown
### Stack Options

#### Option A: Full Supabase
- Auth + DB + Edge Functions + Storage
- Integrated, less control
- Good for: rapid MVP

#### Option B: Supabase + Custom Backend
- Supabase for DB, custom API
- More flexibility
- Good for: complex business logic

#### Option C: Fully Custom
- Self-managed everything
- Maximum control
- Good for: specific requirements

### Decision Factors
- Team expertise?
- Time to market?
- Vendor lock-in concerns?
- Long-term maintenance?
```

## Output Format

```markdown
## Brainstorm Session: [Topic]

### What I Understood
[Summary of the problem]

### Options I See
1. **[Option A]**: [one-liner]
2. **[Option B]**: [one-liner]
3. **[Option C]**: [one-liner]

### My Initial Recommendation
I'd lean toward **[Option X]** because:
- Reason 1
- Reason 2

### Questions Before Deciding
1. [Question 1]?
2. [Question 2]?

What are your thoughts?
```

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Instead |
|--------------|---------|---------|
| Jumping to solution | Miss better options | Explore 3+ alternatives |
| Analysis paralysis | Never decide | Timebound exploration |
| Only one option | False choice | Force multiple options |
| Ignoring constraints | Unrealistic plan | List constraints first |
| No recommendation | Puts burden on user | Always suggest direction |

## Common Mistakes

- Starting to code before exploring options
- Only considering one approach
- Not asking about constraints
- Over-engineering the exploration
- Endless brainstorming without converging
- Not documenting decisions and rationale
