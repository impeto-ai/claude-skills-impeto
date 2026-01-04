---
name: writing-plans
description: Use when starting a project, feature, or user mentions "plan", "plano", "planejar", "roadmap", "arquitetura", "design". Creates detailed implementation plans.
---

# Writing Plans

Creates detailed, actionable implementation plans with clear tasks and checkpoints.

## When to Use

- Starting new project or feature
- Complex multi-step implementation
- User says: plan, plano, planejar, roadmap, arquitetura
- Before executing (write plan → execute plan)
- NOT when: simple one-liner fixes, exploration

## Plan Structure

```
┌─────────────────────────────────────────────────┐
│  1. CONTEXT                                     │
│     What problem are we solving?                │
├─────────────────────────────────────────────────┤
│  2. GOALS                                       │
│     What does success look like?                │
├─────────────────────────────────────────────────┤
│  3. APPROACH                                    │
│     How will we solve it?                       │
├─────────────────────────────────────────────────┤
│  4. TASKS                                       │
│     Step-by-step actions                        │
├─────────────────────────────────────────────────┤
│  5. CHECKPOINTS                                 │
│     Verification points                         │
└─────────────────────────────────────────────────┘
```

## Plan Template

```markdown
# Plan: [Feature/Project Name]

## Context
[1-2 paragraphs explaining the problem and why we're solving it]

## Goals
- [ ] Primary: [main objective]
- [ ] Secondary: [nice-to-have]
- [ ] Non-goal: [explicitly out of scope]

## Approach
[High-level strategy, architecture decisions, key tradeoffs]

## Tasks

### Phase 1: [Foundation]
- [ ] Task 1.1: [specific action]
- [ ] Task 1.2: [specific action]
- [ ] **CHECKPOINT**: [what to verify]

### Phase 2: [Core Implementation]
- [ ] Task 2.1: [specific action]
- [ ] Task 2.2: [specific action]
- [ ] **CHECKPOINT**: [what to verify]

### Phase 3: [Polish/Integration]
- [ ] Task 3.1: [specific action]
- [ ] Task 3.2: [specific action]
- [ ] **CHECKPOINT**: [what to verify]

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| [Risk 1] | [How to handle] |

## Success Criteria
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
```

## Writing Good Tasks

### Bad Tasks (Too Vague)
```
- [ ] Implement authentication
- [ ] Set up database
- [ ] Build the API
```

### Good Tasks (Specific & Actionable)
```
- [ ] Create `users` table with id, email, password_hash, created_at
- [ ] Implement POST /auth/register endpoint
- [ ] Add password hashing using bcrypt
- [ ] Write test for successful registration
- [ ] Write test for duplicate email rejection
```

## Task Sizing

| Size | Description | Example |
|------|-------------|---------|
| S | < 30 min, single file | Add validation to field |
| M | 30min-2hr, few files | New API endpoint |
| L | 2-4hr, multiple files | New feature module |
| XL | > 4hr | Break it down! |

**Rule:** If a task feels like XL, break it into smaller tasks.

## For AI Agent Projects (Pydantic AI)

```markdown
### Phase 1: Agent Foundation
- [ ] Define agent input/output schemas (Pydantic models)
- [ ] Create base agent class with logging
- [ ] Set up test fixtures for agent testing
- [ ] **CHECKPOINT**: Agent runs with mock LLM

### Phase 2: Core Logic
- [ ] Implement tool definitions
- [ ] Add state management
- [ ] Implement main agent loop
- [ ] **CHECKPOINT**: Agent completes simple task

### Phase 3: Integration
- [ ] Connect to real LLM provider
- [ ] Add error handling and retries
- [ ] Implement conversation memory
- [ ] **CHECKPOINT**: End-to-end test passes
```

## For Database Projects (Postgres/Supabase)

```markdown
### Phase 1: Schema Design
- [ ] Create ERD diagram
- [ ] Define tables with proper types
- [ ] Add indexes for query patterns
- [ ] **CHECKPOINT**: Schema passes review

### Phase 2: Migrations
- [ ] Create migration for tables
- [ ] Add RLS policies
- [ ] Create necessary functions
- [ ] **CHECKPOINT**: Migrations run cleanly

### Phase 3: API Layer
- [ ] Generate TypeScript types
- [ ] Implement CRUD operations
- [ ] Add Edge Functions if needed
- [ ] **CHECKPOINT**: API tests pass
```

## For Web/Mobile Projects

```markdown
### Phase 1: Setup
- [ ] Initialize project (Next.js/React Native)
- [ ] Configure Tailwind/styling
- [ ] Set up routing structure
- [ ] **CHECKPOINT**: App renders hello world

### Phase 2: Core Features
- [ ] Build component library
- [ ] Implement main screens
- [ ] Connect to backend/API
- [ ] **CHECKPOINT**: Core flow works

### Phase 3: Polish
- [ ] Add loading states
- [ ] Implement error handling
- [ ] Optimize performance
- [ ] **CHECKPOINT**: Ready for review
```

## Checkpoints

Checkpoints are verification gates:

```markdown
### CHECKPOINT: API Layer Complete
Verify:
- [ ] All endpoints return correct status codes
- [ ] Error responses follow standard format
- [ ] Authentication works on protected routes
- [ ] Tests pass: `pytest tests/api/ -v`

If any fail, do not proceed to next phase.
```

## Output Format

When creating a plan, output:

```
## Plan Created: [Name]

### Summary
[2-3 sentence overview]

### Phases
1. [Phase 1]: [X tasks]
2. [Phase 2]: [Y tasks]
3. [Phase 3]: [Z tasks]

### First Actions
Start with:
1. [Task 1.1]
2. [Task 1.2]

Ready to execute? Use `/execute-plan` or say "executar plano"
```

## Common Mistakes

- Tasks too vague ("implement feature")
- No checkpoints (can't verify progress)
- Plan too detailed (analysis paralysis)
- No scope boundaries (scope creep)
- Ignoring dependencies between tasks
- Not considering rollback plan
