---
name: requesting-code-review
description: Use before requesting review, when code is ready, or user mentions "review", "revisar", "PR", "pull request", "pronto para review". Pre-review checklist.
---

# Requesting Code Review

Prepares code for review with a comprehensive pre-submission checklist.

## When to Use

- Code is complete and ready for review
- About to create a PR
- User says: review, revisar, PR, pull request
- Before merging to main
- NOT when: still developing, debugging

## Pre-Review Checklist

Complete before requesting review:

```markdown
## Pre-Review Checklist

### Code Quality
- [ ] Code compiles/runs without errors
- [ ] All tests pass
- [ ] No console.log/print debugging left
- [ ] No commented-out code
- [ ] No TODO comments that should be resolved

### Testing
- [ ] New code has tests
- [ ] Edge cases covered
- [ ] Tests are readable and maintainable
- [ ] Test names describe behavior

### Documentation
- [ ] Public APIs documented
- [ ] Complex logic has comments
- [ ] README updated if needed
- [ ] Breaking changes documented

### Security
- [ ] No secrets/credentials in code
- [ ] Input validation added
- [ ] SQL injection protected
- [ ] XSS prevented
- [ ] Auth/authz checked

### Performance
- [ ] No N+1 queries
- [ ] Large lists paginated
- [ ] Heavy operations async
- [ ] Indexes added if needed

### Git Hygiene
- [ ] Commits are atomic and meaningful
- [ ] Branch is rebased on main
- [ ] No merge conflicts
- [ ] PR description is clear
```

## Self-Review First

Before asking others, review your own code:

### Questions to Ask Yourself

```markdown
1. **Would I understand this in 6 months?**
   - Variable names clear?
   - Flow obvious?

2. **What could break?**
   - Error cases handled?
   - Null checks present?

3. **Is this the simplest solution?**
   - Over-engineered anywhere?
   - Unnecessary abstractions?

4. **Am I following project patterns?**
   - Consistent with existing code?
   - Using established utilities?
```

## PR Description Template

```markdown
## Summary
[2-3 sentences explaining WHAT changed and WHY]

## Changes
- [Change 1]
- [Change 2]
- [Change 3]

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Refactor
- [ ] Documentation

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing done

### Test Instructions
1. [Step 1]
2. [Step 2]
3. Expected: [outcome]

## Screenshots (if UI)
[Before/After screenshots]

## Checklist
- [ ] Self-reviewed the code
- [ ] Tests pass locally
- [ ] Documentation updated
- [ ] No security issues

## Related Issues
Closes #[issue-number]
```

## For AI Agent PRs

```markdown
## AI Agent Changes

### Agent Behavior Changes
- [ ] Agent prompts modified?
- [ ] Tool definitions changed?
- [ ] State management updated?

### Testing Agent Changes
```bash
# Run agent tests
pytest tests/agents/ -v

# Test specific agent behavior
python -m agents.test_runner --agent [name]

# Verify prompt changes don't break output schemas
python -m agents.schema_validator
```

### Prompt Changes
```diff
- Old prompt line
+ New prompt line
```

### Output Format Changes
[Document any changes to expected outputs]
```

## For Database PRs

```markdown
## Database Changes

### Migration Safety
- [ ] Migration is reversible?
- [ ] No data loss?
- [ ] Tested on production-like data?

### RLS Policies
- [ ] Policies cover all CRUD operations?
- [ ] Tested with multiple roles?

### Performance
- [ ] EXPLAIN ANALYZE on new queries?
- [ ] Indexes added for new query patterns?

### Rollback Plan
```sql
-- To rollback this migration:
DROP TABLE IF EXISTS [table];
-- or
ALTER TABLE [table] DROP COLUMN [column];
```
```

## Review Request Message

```markdown
## Review Request: [PR Title]

**Branch:** `feature/[name]` → `main`
**PR Link:** [URL]

### What This Does
[1-2 sentences]

### Key Changes to Review
1. `path/to/file.py` - [what changed]
2. `path/to/other.py` - [what changed]

### Areas of Concern
- [Specific area I'm unsure about]
- [Trade-off I made that might need discussion]

### Testing Done
- [x] All tests pass
- [x] Manual testing on [environment]

### Time Estimate for Review
~[X] minutes

Ready for review when you have time!
```

## Common Issues to Fix Before Review

| Issue | How to Spot | How to Fix |
|-------|-------------|------------|
| Debug code left | `console.log`, `print`, `debugger` | Remove all debug statements |
| Large PR | >500 lines changed | Split into smaller PRs |
| No tests | Coverage decreased | Add tests first |
| Unclear commits | "WIP", "fix", "update" | Squash and rewrite |
| Outdated branch | Conflicts with main | Rebase on main |

## Output Format

When preparing for review:

```markdown
## Pre-Review Report

### Checklist Status
- ✅ Code Quality: 5/5 passed
- ✅ Testing: 4/4 passed
- ✅ Documentation: 3/3 passed
- ✅ Security: 5/5 passed
- ⚠️ Performance: Review needed (see below)

### Items Fixed Before Review
1. Removed 3 console.log statements
2. Added missing test for edge case
3. Updated README with new API endpoint

### Outstanding Concerns
1. **Performance**: New query might be slow with large datasets
   - Added index, but should monitor in prod

### Ready for Review
PR is ready. Key areas to focus:
1. `api/handlers.py:45-80` - New validation logic
2. `tests/test_api.py` - Coverage for edge cases

Create PR now?
```

## Common Mistakes

- Submitting without self-review
- PR too large to review effectively
- Missing PR description
- No test coverage for new code
- Debug code left in
- Not addressing previous review feedback
