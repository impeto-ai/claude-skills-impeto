---
name: systematic-debugging
description: Use when fixing bugs, errors, or user mentions "debug", "erro", "não funciona", "bug", "quebrou", "failing". Four-phase root cause analysis.
---

# Systematic Debugging

Four-phase methodology for finding and fixing root causes, not symptoms.

## When to Use

- Error messages or exceptions
- Unexpected behavior
- Tests failing
- User says: debug, erro, bug, não funciona, quebrou, failing
- NOT when: adding features, refactoring working code

## The Four Phases

```
┌─────────────────────────────────────────────────┐
│  PHASE 1: REPRODUCE                             │
│  Can you make it fail consistently?             │
├─────────────────────────────────────────────────┤
│  PHASE 2: ISOLATE                               │
│  Where exactly does it fail?                    │
├─────────────────────────────────────────────────┤
│  PHASE 3: IDENTIFY                              │
│  WHY does it fail? Root cause.                  │
├─────────────────────────────────────────────────┤
│  PHASE 4: FIX & VERIFY                          │
│  Fix it and prove it's fixed.                   │
└─────────────────────────────────────────────────┘
```

## Phase 1: REPRODUCE

**Goal:** Consistent reproduction steps

```markdown
### Reproduction Checklist
- [ ] Can reproduce locally?
- [ ] Minimum steps to reproduce?
- [ ] What's the exact error message?
- [ ] What's the expected vs actual behavior?
- [ ] Environment details (versions, config)?
```

**Document:**
```
REPRODUCTION STEPS:
1. [Step 1]
2. [Step 2]
3. [Step 3]

EXPECTED: [What should happen]
ACTUAL: [What actually happens]
ERROR: [Exact error message]
```

## Phase 2: ISOLATE

**Goal:** Find the exact location

### Techniques

| Technique | When to Use |
|-----------|-------------|
| Binary search | Large codebase, unclear location |
| Stack trace | Exception with traceback |
| Git bisect | "It worked yesterday" |
| Print/logging | Flow unclear |
| Breakpoints | Need to inspect state |

### Binary Search Method

```
1. Find a known good state (test passes, feature works)
2. Find the bad state (current broken)
3. Test the middle point
4. Narrow down: which half has the bug?
5. Repeat until found
```

### For AI Agents

```python
# Add trace logging to agent steps
import logging
logging.basicConfig(level=logging.DEBUG)

# Log each step
logger.debug(f"Input: {input}")
logger.debug(f"Agent state: {agent.state}")
logger.debug(f"Tool called: {tool_name} with {args}")
logger.debug(f"Tool result: {result}")
logger.debug(f"Output: {output}")
```

### For Database

```sql
-- Check query plan
EXPLAIN ANALYZE SELECT ...;

-- Check recent errors
SELECT * FROM pg_stat_activity WHERE state = 'error';

-- Check locks
SELECT * FROM pg_locks WHERE NOT granted;
```

## Phase 3: IDENTIFY (Root Cause)

**Goal:** Understand WHY, not just WHERE

### 5 Whys Technique

```
Problem: User login fails
Why 1: Token validation returns false
Why 2: Token is expired
Why 3: Token expiry was set to 1 second
Why 4: Config loaded wrong environment
Why 5: .env file not in container → ROOT CAUSE
```

### Common Root Causes

| Symptom | Likely Cause |
|---------|--------------|
| Works locally, fails in prod | Environment/config difference |
| Intermittent failure | Race condition, timing |
| Fails after deploy | New code, dependency update |
| Fails at scale | Memory, connection limits |
| Fails randomly | Uninitialized state, random seed |

### For Pydantic AI

```python
# Common issues:
# 1. Schema validation errors
# 2. Token limits exceeded
# 3. Tool not returning expected format
# 4. State not persisting between steps

# Debug with:
from pydantic_ai import debug
debug.enable()
```

## Phase 4: FIX & VERIFY

**Goal:** Fix root cause, prove it's fixed

### Fix Checklist

```markdown
- [ ] Fix addresses ROOT CAUSE (not symptom)
- [ ] Write test that would have caught this
- [ ] Test passes now
- [ ] No regressions (other tests still pass)
- [ ] Document what was wrong and why
```

### Verification

```bash
# Run specific test
pytest tests/test_feature.py::test_that_was_failing -v

# Run related tests
pytest tests/test_feature.py -v

# Run full suite
pytest

# Check for regressions
git diff HEAD~1 | pytest --collect-only
```

## Defense in Depth

After fixing, add layers of protection:

```python
# 1. Input validation
def process_user(user_id: int) -> User:
    if user_id <= 0:
        raise ValueError(f"Invalid user_id: {user_id}")
    ...

# 2. Assertions for invariants
assert len(results) > 0, "Query returned no results"

# 3. Logging for future debugging
logger.info(f"Processed {len(items)} items in {elapsed}s")

# 4. Monitoring/alerting
metrics.increment("process_user.success")
```

## Output Format

When debugging, structure responses as:

```
## PHASE 1: REPRODUCE
- Steps: [numbered list]
- Error: `[exact message]`
- Consistent: YES/NO

## PHASE 2: ISOLATE
- Location: `[file:line]`
- Method used: [binary search/stack trace/etc]

## PHASE 3: IDENTIFY
- Root cause: [explanation]
- 5 Whys: [chain]

## PHASE 4: FIX & VERIFY
- Fix: `[file:line]` - [description]
- Test: `[test name]` - PASSING ✓
- Regression: NONE ✓
```

## Common Mistakes

- Fixing symptoms instead of root cause
- Not reproducing before fixing
- Changing multiple things at once
- Not writing regression test
- Skipping verification phase
- Assuming instead of proving
