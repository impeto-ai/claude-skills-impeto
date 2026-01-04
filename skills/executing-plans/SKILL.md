---
name: executing-plans
description: Use when a plan exists and user wants to implement, or mentions "executar", "execute", "implementar", "rodar plano", "seguir plano". Batch execution with checkpoints.
---

# Executing Plans

Systematic execution of plans with progress tracking, checkpoints, and human verification gates.

## When to Use

- Plan already exists (from writing-plans)
- User says: executar, execute, implementar, rodar plano
- Multi-step implementation ready to go
- NOT when: no plan exists (use writing-plans first)

## Execution Flow

```
┌─────────────────────────────────────────────────┐
│  1. LOAD PLAN                                   │
│     Read and understand the plan                │
├─────────────────────────────────────────────────┤
│  2. EXECUTE BATCH                               │
│     Work through tasks until checkpoint         │
├─────────────────────────────────────────────────┤
│  3. CHECKPOINT VERIFICATION                     │
│     Stop and verify with user                   │
├─────────────────────────────────────────────────┤
│  4. CONTINUE OR ADJUST                          │
│     Get approval, then next batch               │
└─────────────────────────────────────────────────┘
```

## Execution Rules

### Rule 1: Batch Size
Execute tasks in small batches (3-5 tasks) before checkpoint.

```
✗ Wrong: Execute 20 tasks, then check
✓ Right: Execute 3-5 tasks, checkpoint, repeat
```

### Rule 2: Stop at Checkpoints
ALWAYS stop at checkpoint markers for human verification.

```markdown
### Completed Tasks
- [x] Task 1.1: Created users table
- [x] Task 1.2: Added RLS policies
- [x] Task 1.3: Created migration

### CHECKPOINT REACHED: Database Schema

**Verification needed:**
- [ ] Tables created correctly?
- [ ] RLS policies working?
- [ ] Migration runs clean?

**Command to verify:**
```bash
supabase db reset && supabase test db
```

Awaiting confirmation to continue...
```

### Rule 3: Track Progress
Update plan with completed tasks as you go.

```markdown
## Progress: Phase 1 (3/5 complete)

- [x] Task 1.1: Done ✓
- [x] Task 1.2: Done ✓
- [x] Task 1.3: Done ✓
- [ ] Task 1.4: In progress...
- [ ] Task 1.5: Pending
```

### Rule 4: Handle Blockers
If blocked, stop and report instead of improvising.

```markdown
## BLOCKER ENCOUNTERED

**Task:** Task 2.3 - Connect to external API
**Issue:** API requires authentication token not in .env
**Need:** User to provide API_TOKEN

Options:
1. User provides token
2. Skip task, continue with mocks
3. Adjust plan

Waiting for direction...
```

## Execution Template

```markdown
# Executing: [Plan Name]

## Current Phase: [N] - [Phase Name]

### Batch [X] Progress

#### Completed
- [x] **Task [N.1]**: [Description]
  - Files: `path/to/file.py`
  - Result: [What was done]

- [x] **Task [N.2]**: [Description]
  - Files: `path/to/file.py`
  - Result: [What was done]

#### In Progress
- [ ] **Task [N.3]**: [Description]
  - Status: Working on...

#### Pending
- [ ] Task [N.4]
- [ ] Task [N.5]

### Checkpoint: [Name]
- [ ] Verification 1
- [ ] Verification 2
- [ ] Run: `command to verify`

---
**Status:** CHECKPOINT REACHED | BLOCKED | IN PROGRESS
**Next:** [What happens after verification]
```

## For AI Agent Execution

When executing AI agent plans:

```markdown
### Batch: Agent Core Implementation

#### Completed
- [x] **Define Pydantic schemas**
  ```python
  # agents/schemas.py
  class AgentInput(BaseModel):
      query: str
      context: Optional[dict]

  class AgentOutput(BaseModel):
      response: str
      confidence: float
  ```

- [x] **Create base agent**
  ```python
  # agents/base.py
  class BaseAgent:
      def __init__(self, model: str):
          self.model = model
          self.tools = []
  ```

#### Checkpoint: Agent Foundation
- [ ] Schemas validate correctly
- [ ] Base agent instantiates
- [ ] Run: `pytest tests/agents/test_base.py -v`

Awaiting verification...
```

## For Database Execution

When executing database plans:

```markdown
### Batch: Schema Implementation

#### Completed
- [x] **Create users migration**
  ```sql
  -- supabase/migrations/001_users.sql
  CREATE TABLE users (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      email TEXT UNIQUE NOT NULL,
      created_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```

- [x] **Add RLS policy**
  ```sql
  ALTER TABLE users ENABLE ROW LEVEL SECURITY;
  CREATE POLICY "Users see own data" ON users
      FOR SELECT USING (auth.uid() = id);
  ```

#### Checkpoint: Database Ready
- [ ] Migration runs: `supabase db reset`
- [ ] RLS works: Test with different users
- [ ] Types generated: `supabase gen types typescript`

Awaiting verification...
```

## Handling Adjustments

When plan needs changes mid-execution:

```markdown
## Plan Adjustment Needed

**Original task:** Implement OAuth with Google
**Issue:** Client wants to use Magic Links instead
**Impact:**
- Skip tasks 2.3-2.5 (OAuth setup)
- Add new tasks for Magic Links

**Proposed adjustment:**
- [ ] NEW: Configure Supabase Magic Links
- [ ] NEW: Create email templates
- [ ] NEW: Implement login flow

Approve adjustment to continue?
```

## Progress Summary Format

After each batch:

```markdown
## Progress Summary

### Overall: ████████░░ 80%

| Phase | Status | Tasks |
|-------|--------|-------|
| 1. Setup | ✅ Complete | 5/5 |
| 2. Core | 🔄 In Progress | 3/6 |
| 3. Polish | ⏳ Pending | 0/4 |

### This Session
- Completed: 3 tasks
- Time: ~45 minutes
- Blockers: None

### Next Batch
1. Task 2.4: [description]
2. Task 2.5: [description]
3. Task 2.6: [description]

Continue to next batch?
```

## Output Markers

Use these markers for clear status:

| Marker | Meaning |
|--------|---------|
| `✅ CHECKPOINT PASSED` | Verification complete, continue |
| `⏸️ CHECKPOINT REACHED` | Waiting for user verification |
| `🚫 BLOCKER` | Cannot continue, need input |
| `🔄 IN PROGRESS` | Currently executing |
| `✓ BATCH COMPLETE` | Batch done, ready for checkpoint |

## Common Mistakes

- Executing past checkpoints without verification
- Not tracking which tasks are complete
- Improvising when blocked instead of asking
- Large batches without intermediate checks
- Not showing verification commands
- Continuing after failed verification
