---
name: verification-before-completion
description: Use before marking task complete, or user mentions "verify", "verificar", "está pronto", "funcionando", "testar final". Validates work is actually done.
---

# Verification Before Completion

Validates that work is truly complete before marking done. Prevents premature completion.

## When to Use

- About to mark task as complete
- Think you're done with a feature
- User asks: verify, verificar, está pronto?
- Before saying "done" or "complete"
- NOT when: still in progress

## Core Principle

```
"It's not done until it's verified."

Untested = Unknown = Not Done
```

## Verification Levels

```
┌─────────────────────────────────────────────────┐
│  LEVEL 1: IT RUNS                               │
│  Code executes without errors                   │
├─────────────────────────────────────────────────┤
│  LEVEL 2: IT WORKS                              │
│  Produces expected output                       │
├─────────────────────────────────────────────────┤
│  LEVEL 3: IT'S ROBUST                           │
│  Handles edge cases                             │
├─────────────────────────────────────────────────┤
│  LEVEL 4: IT'S COMPLETE                         │
│  All requirements met                           │
└─────────────────────────────────────────────────┘
```

## Universal Verification Checklist

```markdown
## Verification Checklist: [Task Name]

### Level 1: It Runs
- [ ] Code compiles/interprets without errors
- [ ] No runtime exceptions on happy path
- [ ] Dependencies installed and working

### Level 2: It Works
- [ ] Main functionality works as expected
- [ ] Output matches specification
- [ ] Tested with real-ish data

### Level 3: It's Robust
- [ ] Edge cases handled
- [ ] Error cases handled gracefully
- [ ] Invalid input rejected properly
- [ ] Empty/null cases work

### Level 4: It's Complete
- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Documentation updated
- [ ] No TODO/FIXME left unaddressed
```

## Verification by Type

### For API Endpoints

```markdown
## API Verification: [Endpoint]

### Happy Path
- [ ] Returns correct status code
- [ ] Response body matches schema
- [ ] Headers are correct

### Error Cases
- [ ] 400 for bad request
- [ ] 401 for unauthenticated
- [ ] 403 for unauthorized
- [ ] 404 for not found
- [ ] 500 handled gracefully

### Edge Cases
- [ ] Empty response body handled
- [ ] Large payload handled
- [ ] Concurrent requests work
- [ ] Rate limiting works (if applicable)

### Test Commands
```bash
# Happy path
curl -X POST /api/endpoint -d '{"valid": "data"}'

# Bad request
curl -X POST /api/endpoint -d '{"invalid": "data"}'

# Unauthorized
curl -X POST /api/endpoint -H "Authorization: invalid"
```
```

### For UI Components

```markdown
## UI Verification: [Component]

### Visual
- [ ] Matches design spec
- [ ] Responsive (mobile, tablet, desktop)
- [ ] Dark mode (if applicable)

### Interaction
- [ ] Click handlers work
- [ ] Keyboard navigation works
- [ ] Focus states visible

### States
- [ ] Loading state
- [ ] Empty state
- [ ] Error state
- [ ] Success state

### Accessibility
- [ ] Semantic HTML
- [ ] ARIA labels
- [ ] Screen reader tested
```

### For Database Migrations

```markdown
## Migration Verification: [Migration Name]

### Forward Migration
- [ ] Runs without error
- [ ] Creates expected tables/columns
- [ ] Indexes created
- [ ] RLS policies work

### Rollback
- [ ] Rollback script exists
- [ ] Rollback runs clean
- [ ] No data loss on rollback

### Data Integrity
- [ ] Existing data preserved
- [ ] Constraints enforced
- [ ] Foreign keys valid

### Performance
- [ ] Migration runs in reasonable time
- [ ] New queries use indexes
- [ ] No table locks during migration

### Test Commands
```bash
# Apply migration
supabase db reset

# Test queries
psql -c "SELECT * FROM new_table LIMIT 1;"

# Check RLS
psql -c "SET ROLE authenticated; SELECT * FROM new_table;"
```
```

### For AI Agents

```markdown
## Agent Verification: [Agent Name]

### Core Behavior
- [ ] Agent completes main task
- [ ] Output matches expected schema
- [ ] Reasoning is sound

### Edge Cases
- [ ] Handles ambiguous input
- [ ] Handles empty input
- [ ] Handles very long input
- [ ] Graceful when tool fails

### Integration
- [ ] All tools work
- [ ] State persists correctly
- [ ] Memory works (if applicable)

### Quality
- [ ] Responses are coherent
- [ ] No hallucinations on factual tasks
- [ ] Stays on topic

### Test Commands
```python
# Happy path
result = agent.run("normal input")
assert result.valid()

# Edge case
result = agent.run("")
assert result.error_handled()

# Tool failure
with mock_tool_failure():
    result = agent.run("input")
    assert result.graceful_degradation()
```
```

## Verification Process

```markdown
## Verification Report: [Task]

### Test Execution
| Test | Status | Notes |
|------|--------|-------|
| Unit tests | ✅ Pass | 45/45 |
| Integration tests | ✅ Pass | 12/12 |
| Manual test | ✅ Pass | Verified in staging |

### Requirements Check
| Requirement | Met? | Evidence |
|-------------|------|----------|
| User can login | ✅ | Test: test_user_login |
| Passwords hashed | ✅ | Uses bcrypt |
| Session expires | ✅ | 24h TTL configured |

### Edge Cases
| Case | Handled? | How |
|------|----------|-----|
| Empty email | ✅ | Validation error |
| SQL injection | ✅ | Parameterized queries |
| Long password | ✅ | Truncated at 128 chars |

### Outstanding Issues
None found during verification.

### Verdict
✅ **VERIFIED - Ready for completion**
```

## Verification Commands Template

```bash
# Run all tests
npm test           # JavaScript
pytest             # Python
go test ./...      # Go

# Run specific test file
npm test -- path/to/test.spec.ts
pytest path/to/test.py

# Run with coverage
npm test -- --coverage
pytest --cov=src

# Lint check
npm run lint
ruff check .

# Type check
npm run typecheck
mypy src/
```

## Output Format

When verifying:

```markdown
## Verification: [Task Name]

### Quick Check
- [x] Runs: Yes
- [x] Works: Yes
- [x] Robust: Yes
- [x] Complete: Yes

### Tests Run
```bash
$ pytest tests/ -v
=================== 23 passed in 1.45s ===================
```

### Manual Verification
- [x] Tested: [scenario 1]
- [x] Tested: [scenario 2]
- [x] Tested: [edge case]

### Issues Found
None.

### Verdict
✅ **VERIFIED** - Task is complete.

OR

❌ **NOT VERIFIED** - Issues found:
1. [Issue 1]
2. [Issue 2]

Action needed before completion.
```

## Red Flags (Don't Mark Complete If...)

```markdown
❌ Don't mark complete if:
- Any test fails
- "Works on my machine" but not verified elsewhere
- TODO/FIXME comments remain
- Known edge cases unhandled
- Error handling says "// handle this later"
- Manual testing not done
- Only tested happy path
```

## Common Mistakes

- Assuming it works because it compiles
- Testing only the happy path
- Skipping manual verification
- Not testing after "final" changes
- Marking done before tests finish running
- Ignoring flaky test failures
