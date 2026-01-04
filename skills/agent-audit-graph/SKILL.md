---
name: agent-audit-graph
description: Use to audit AI agent implementations. AUTOMATICALLY triggered after graph-agent changes. Uses context7 for latest docs. Creates debt in /.debts/ if fails.
---

# Agent Audit Graph

Heavy-duty auditor for AI agent implementations. Uses context7 for up-to-date documentation.

## When to Use

- AUTOMATICALLY after graph-agent makes changes
- Manually when reviewing agent code
- Before deploying agents to production
- User says: audit agent, revisar agent, validar agent
- NOT when: writing new code (use graph-agent)

## Audit Process

```
┌─────────────────────────────────────────────────────────────────┐
│                      AGENT AUDIT PROCESS                        │
├─────────────────────────────────────────────────────────────────┤
│  1. FETCH DOCS    → context7 latest Pydantic AI docs            │
│  2. SCHEMA AUDIT  → Validate Pydantic models                    │
│  3. GRAPH AUDIT   → Check node/edge structure                   │
│  4. STATE AUDIT   → Verify immutability patterns                │
│  5. PRODUCTION    → Check persistence, error handling           │
│  6. VERDICT       → PASS → agent-tester / FAIL → /.debts/       │
└─────────────────────────────────────────────────────────────────┘
```

## Step 1: Fetch Latest Docs

**ALWAYS use context7 before auditing:**

```
Tool: mcp__context7__query-docs
Library: /pydantic/pydantic-ai
Query: [specific pattern being audited]
```

This ensures audit uses current best practices, not outdated patterns.

## Audit Checklist

### Schema Audit

```markdown
## Schema Audit: [Agent Name]

### State Model
- [ ] Inherits from BaseModel
- [ ] All fields have type hints
- [ ] Default values are immutable (no `list()`, use `[]`)
- [ ] Validators present for complex fields
- [ ] No mutable default arguments

### Output Model
- [ ] All fields required or have defaults
- [ ] Validation for string fields (min/max length)
- [ ] Numeric bounds where applicable
- [ ] Union types properly discriminated
- [ ] Nested models also validated
```

### Graph Audit

```markdown
## Graph Audit: [Agent Name]

### Structure
- [ ] All nodes properly typed
- [ ] Return types match possible transitions
- [ ] No orphan nodes (unreachable)
- [ ] End states properly defined
- [ ] No infinite loops possible

### Edges
- [ ] All transitions have conditions
- [ ] Error paths exist
- [ ] Timeout handling present
```

### State Management Audit

```markdown
## State Audit: [Agent Name]

### Immutability
- [ ] No direct state mutation
- [ ] Uses model_copy() for updates
- [ ] No list.append() on state fields
- [ ] No dict direct assignment

### Persistence
- [ ] FileStatePersistence or custom persistence
- [ ] Snapshot points defined
- [ ] Recovery logic implemented
- [ ] Run ID properly generated
```

### Production Readiness Audit

```markdown
## Production Audit: [Agent Name]

### Error Handling
- [ ] Try/except in LLM calls
- [ ] Retry logic with backoff
- [ ] Fallback for tool failures
- [ ] Graceful degradation path

### Observability
- [ ] Logging at key points
- [ ] Structured log format
- [ ] Trace IDs propagated
- [ ] Metrics for latency/success

### Security
- [ ] No secrets in state
- [ ] Input sanitization
- [ ] Output validation before use
- [ ] Rate limiting considered
```

## Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| 🔴 CRITICAL | Breaks in production | MUST fix, block deploy |
| 🟠 HIGH | Likely to cause issues | Should fix before deploy |
| 🟡 MEDIUM | Best practice violation | Fix soon |
| 🟢 LOW | Suggestion | Nice to have |

## Audit Output Format

### When PASSING

```
⚡ SKILL_ACTIVATED: #AUDT-8K3M

## Audit Report: [Agent Name]

### Summary
✅ AUDIT PASSED

### Scores
| Category | Score | Notes |
|----------|-------|-------|
| Schema | 9/10 | Minor: add validator for email |
| Graph | 10/10 | Excellent structure |
| State | 8/10 | Consider adding more snapshots |
| Production | 9/10 | Good error handling |

### Minor Recommendations
1. [Recommendation 1]
2. [Recommendation 2]

---
→ CHAIN: Triggering agent-tester
```

### When FAILING

```
⚡ SKILL_ACTIVATED: #AUDT-8K3M

## Audit Report: [Agent Name]

### Summary
❌ AUDIT FAILED - 3 critical issues

### Critical Issues

#### 🔴 CRITICAL: State Mutation Detected
**File:** `agents/my_agent/nodes.py:45`
**Issue:** Direct list append on state
**Code:**
```python
state.messages.append(msg)  # WRONG
```
**Fix:**
```python
state.model_copy(update={"messages": [*state.messages, msg]})
```

#### 🔴 CRITICAL: No Error Handling in LLM Call
**File:** `agents/my_agent/nodes.py:67`
**Issue:** Raw await without try/except
**Required:** Wrap in try/except with retry logic

#### 🔴 CRITICAL: Infinite Loop Possible
**File:** `agents/my_agent/graph.py:23`
**Issue:** Node A → Node B → Node A without exit condition

---
→ CREATING DEBT: /.debts/graph-agent/[timestamp]-[issue].md
→ BLOCKED: Fix issues before proceeding
```

## Debt Document Format

When audit fails, create `/.debts/graph-agent/{timestamp}-{slug}.md`:

```markdown
---
created: 2025-01-04T10:30:00
agent: [agent-name]
severity: critical
status: open
---

# Technical Debt: [Issue Title]

## Issue
[Description of the problem]

## Location
- File: `path/to/file.py`
- Line: 45-50

## Current Code
```python
[problematic code]
```

## Required Fix
```python
[correct code]
```

## Why It Matters
[Explanation of production impact]

## References
- [Pydantic AI Docs](https://ai.pydantic.dev/)
- [context7 query result]
```

## Context7 Queries

Use these queries during audit:

```
# For state patterns
Query: "state management immutable update pydantic graph"

# For error handling
Query: "error handling retry LLM calls production"

# For persistence
Query: "state persistence file durability checkpoint"

# For structured output
Query: "structured output validation schema pydantic"
```

## Output Markers

```
✅ AUDIT PASSED → Proceed to agent-tester
❌ AUDIT FAILED → Create debt, block progress
⚠️ AUDIT WARNING → Can proceed, but log issues
```

---

## ⚠️ CHAIN TRIGGER

**If PASSED:**
```
→ NEXT SKILL: agent-tester
→ ACTION: Run tests on the agent
```

**If FAILED:**
```
→ ACTION: Create /.debts/graph-agent/{issue}.md
→ BLOCKED: Return to graph-agent to fix
→ NO CHAIN: Do not trigger agent-tester
```
