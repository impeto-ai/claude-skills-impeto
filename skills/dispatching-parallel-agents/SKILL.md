---
name: dispatching-parallel-agents
description: Use when task benefits from parallelization, or user mentions "parallel", "paralelo", "concurrent", "agents", "subagents", "em paralelo". Enables concurrent workflows.
---

# Dispatching Parallel Agents

Orchestrates concurrent subagent workflows for faster task completion.

## When to Use

- Tasks can be done independently
- Need faster completion time
- User says: parallel, paralelo, concurrent, subagents
- Multiple files/components to work on
- NOT when: tasks have dependencies, order matters

## Parallel Patterns

```
┌─────────────────────────────────────────────────┐
│  PATTERN 1: FAN-OUT                             │
│  One task → Multiple parallel tasks             │
├─────────────────────────────────────────────────┤
│  PATTERN 2: MAP-REDUCE                          │
│  Parallel work → Combine results                │
├─────────────────────────────────────────────────┤
│  PATTERN 3: PIPELINE WITH PARALLEL STAGES       │
│  Sequential stages, parallel within stage       │
└─────────────────────────────────────────────────┘
```

## Pattern 1: Fan-Out

```
          ┌──→ [Agent A] ──┐
          │                │
[Task] ───┼──→ [Agent B] ──┼──→ [Results]
          │                │
          └──→ [Agent C] ──┘
```

### Use Case: Multiple Independent Components

```markdown
## Parallel Dispatch: Component Implementation

### Task
Implement 4 independent UI components

### Dispatch
- **Agent 1**: Create `Button` component
- **Agent 2**: Create `Card` component
- **Agent 3**: Create `Modal` component
- **Agent 4**: Create `Input` component

### Instructions per Agent
Each agent receives:
- Component spec
- Design system reference
- Test requirements

### Sync Point
After all complete:
- Verify no conflicts
- Run full test suite
- Update exports/index
```

## Pattern 2: Map-Reduce

```
[Data] ──→ MAP ──→ [A₁, A₂, A₃] ──→ REDUCE ──→ [Result]
```

### Use Case: Code Analysis

```markdown
## Parallel Analysis: Codebase Review

### MAP Phase (Parallel)
- **Agent 1**: Analyze `/api/**/*.py` for security
- **Agent 2**: Analyze `/models/**/*.py` for performance
- **Agent 3**: Analyze `/tests/**/*.py` for coverage gaps
- **Agent 4**: Analyze `/utils/**/*.py` for duplication

### REDUCE Phase (Sequential)
Combine findings into unified report:
- Priority-sorted issues
- Cross-cutting concerns
- Action items
```

## Pattern 3: Pipeline with Parallel Stages

```
[Stage 1] ──→ [Stage 2 Parallel] ──→ [Stage 3]
              ├─ Agent A
              ├─ Agent B
              └─ Agent C
```

### Use Case: Feature Development

```markdown
## Pipeline: Feature Implementation

### Stage 1: Setup (Sequential)
- Create database migration
- Define API schemas

### Stage 2: Implementation (Parallel)
- **Agent A**: Implement backend endpoints
- **Agent B**: Implement frontend components
- **Agent C**: Write tests

### Stage 3: Integration (Sequential)
- Connect frontend to backend
- Run integration tests
- Documentation
```

## Dispatch Template

```markdown
# Parallel Dispatch: [Task Name]

## Overview
- **Total Agents**: [N]
- **Pattern**: [Fan-out / Map-Reduce / Pipeline]
- **Estimated Time**: [X] (sequential) → [Y] (parallel)

## Agent Assignments

### Agent 1: [Name]
**Focus**: [Specific scope]
**Files**:
- `path/to/file1.py`
- `path/to/file2.py`
**Instructions**:
1. [Step 1]
2. [Step 2]
**Output Expected**: [Deliverable]

### Agent 2: [Name]
**Focus**: [Specific scope]
**Files**:
- `path/to/file3.py`
- `path/to/file4.py`
**Instructions**:
1. [Step 1]
2. [Step 2]
**Output Expected**: [Deliverable]

[Repeat for each agent]

## Coordination Rules

### Shared Resources
- **Read-only**: `config.py`, `constants.py`
- **No Touch**: `database.py` (assigned to Agent 1 only)

### Communication
- Log all file modifications
- Flag potential conflicts immediately
- Don't modify files outside assigned scope

## Sync Points

### After All Complete
1. [ ] Review all changes
2. [ ] Resolve any conflicts
3. [ ] Run unified tests
4. [ ] Merge/integrate results

## Success Criteria
- [ ] All agents complete successfully
- [ ] No conflicting changes
- [ ] Tests pass
- [ ] Output matches spec
```

## For Pydantic AI / LangGraph

```markdown
## Multi-Agent System Dispatch

### Orchestrator Pattern
```python
from pydantic_ai import Agent, RunContext

# Define specialized agents
researcher = Agent("researcher", tools=[search, fetch])
analyzer = Agent("analyzer", tools=[parse, summarize])
writer = Agent("writer", tools=[format, save])

# Parallel dispatch
async def parallel_research(topics: list[str]):
    tasks = [researcher.run(topic) for topic in topics]
    results = await asyncio.gather(*tasks)
    return results

# Then reduce
combined = await analyzer.run(results)
output = await writer.run(combined)
```

### Graph Pattern (LangGraph)
```python
from langgraph.graph import Graph

# Parallel nodes
graph.add_node("research_a", researcher_a)
graph.add_node("research_b", researcher_b)
graph.add_node("research_c", researcher_c)

# Fan-out from start
graph.add_edge("start", "research_a")
graph.add_edge("start", "research_b")
graph.add_edge("start", "research_c")

# Fan-in to combine
graph.add_edge("research_a", "combine")
graph.add_edge("research_b", "combine")
graph.add_edge("research_c", "combine")
```
```

## For Database Operations

```markdown
## Parallel Database Tasks

### Safe for Parallel
- Read operations on different tables
- Independent migrations
- Seed data for different tables
- Analytics queries

### NOT Safe (Use Sequential)
- Migrations with dependencies
- Foreign key relationships
- Same table writes
- Transactions that must be atomic

### Example: Parallel Seeding
- **Agent 1**: Seed `users` table
- **Agent 2**: Seed `products` table
- **Agent 3**: Seed `categories` table
- **Then Sequential**: Seed `orders` (depends on users, products)
```

## Conflict Prevention

| Rule | Why |
|------|-----|
| Assign file ownership | No two agents edit same file |
| Lock shared resources | Prevent race conditions |
| Define clear boundaries | Each agent knows their scope |
| Read-only shared config | Config changes = sequential |

## Output Format

When dispatching:

```markdown
## Parallel Dispatch Initiated

### Agents Deployed
| Agent | Task | Status |
|-------|------|--------|
| Agent 1 | Frontend components | 🔄 Running |
| Agent 2 | Backend endpoints | 🔄 Running |
| Agent 3 | Test coverage | 🔄 Running |

### Monitoring
- [ ] Agent 1: [progress]
- [ ] Agent 2: [progress]
- [ ] Agent 3: [progress]

### Estimated Completion
~[X] minutes (vs [Y] minutes sequential)

Will notify when sync point reached.
```

After completion:

```markdown
## Parallel Dispatch Complete

### Results
| Agent | Status | Deliverable |
|-------|--------|-------------|
| Agent 1 | ✅ Done | 3 components created |
| Agent 2 | ✅ Done | 5 endpoints implemented |
| Agent 3 | ✅ Done | 12 tests added |

### Integration Status
- [ ] Conflicts: None detected
- [ ] Tests: All passing
- [ ] Ready to merge

### Files Modified
- `/components/Button.tsx` (Agent 1)
- `/components/Card.tsx` (Agent 1)
- `/api/users.py` (Agent 2)
- `/tests/test_users.py` (Agent 3)
```

## Common Mistakes

- Parallelizing dependent tasks (wrong order)
- Multiple agents editing same file (conflicts)
- No sync point defined (integration chaos)
- Over-parallelizing simple tasks (overhead > benefit)
- Not handling agent failures
- Missing conflict resolution strategy
