---
name: code-reviewer
description: Use when performing automated code review, checking code quality. Activates for "review this code", "check quality", "analyze code", "lint", "code analysis".
chain: none
---

# Code Reviewer

Automated code review enforcing quality standards, security, and best practices.

## When to Use

- After writing or refactoring code
- Before creating a PR
- Checking code quality
- User says: review this code, check quality, analyze
- NOT when: requesting external review (use requesting-code-review)

## Review Dimensions

```
┌─────────────────────────────────────────────────────────────────┐
│                    CODE REVIEW DIMENSIONS                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. CORRECTNESS   → Does it work? Edge cases?                 │
│   2. SECURITY      → Vulnerabilities? Input validation?        │
│   3. PERFORMANCE   → O(n)? Memory? Caching?                    │
│   4. MAINTAINABILITY → Readable? SOLID? DRY?                   │
│   5. TESTING       → Coverage? Edge cases? Mocks?              │
│   6. DOCUMENTATION → Comments? Types? API docs?                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Review Checklist

### 1. Correctness
```
[ ] Logic is correct
[ ] Edge cases handled (null, empty, boundary)
[ ] Error handling is appropriate
[ ] Return values are correct
[ ] No off-by-one errors
[ ] Async/await used correctly
[ ] Race conditions avoided
```

### 2. Security (OWASP Top 10)
```
[ ] Input validation (no injection)
[ ] Output encoding (no XSS)
[ ] Authentication checks
[ ] Authorization checks
[ ] No sensitive data in logs
[ ] Secrets not hardcoded
[ ] HTTPS enforced
[ ] CORS configured correctly
[ ] Rate limiting in place
[ ] SQL parameterized queries
```

### 3. Performance
```
[ ] No N+1 queries
[ ] Appropriate indexes used
[ ] Pagination for large datasets
[ ] Caching where appropriate
[ ] No blocking operations in async code
[ ] Memory leaks avoided
[ ] Efficient algorithms (O(n) vs O(n²))
```

### 4. Maintainability
```
[ ] Single Responsibility Principle
[ ] Functions are small (<20 lines)
[ ] Clear naming conventions
[ ] No magic numbers/strings
[ ] DRY (Don't Repeat Yourself)
[ ] Low coupling, high cohesion
[ ] No dead code
```

### 5. Testing
```
[ ] Unit tests for business logic
[ ] Integration tests for APIs
[ ] Edge cases covered
[ ] Mocks used appropriately
[ ] Tests are deterministic
[ ] Good test names (should_X_when_Y)
```

### 6. Documentation
```
[ ] Public APIs documented
[ ] Complex logic has comments
[ ] README updated if needed
[ ] CHANGELOG entry added
[ ] Types/interfaces defined
```

## Automated Checks

### ESLint/TypeScript
```json
{
  "extends": [
    "eslint:recommended",
    "@typescript-eslint/recommended",
    "plugin:security/recommended"
  ],
  "rules": {
    "no-console": "error",
    "no-unused-vars": "error",
    "@typescript-eslint/no-explicit-any": "error",
    "complexity": ["error", 10]
  }
}
```

### Python (Ruff/Pylint)
```toml
[tool.ruff]
select = ["E", "F", "B", "S", "I", "N", "UP", "PL"]
line-length = 100

[tool.ruff.per-file-ignores]
"tests/*" = ["S101"]  # Allow assert in tests
```

## Review Output Format

```markdown
## Code Review: [File/Component]

### Summary
- Files reviewed: X
- Issues found: Y (X critical, Y warnings)
- Overall: PASS/NEEDS_WORK/FAIL

### Critical Issues
1. **[SECURITY]** SQL Injection in `user_service.py:45`
   ```python
   # BAD
   query = f"SELECT * FROM users WHERE id = {user_id}"

   # GOOD
   query = "SELECT * FROM users WHERE id = %s"
   cursor.execute(query, (user_id,))
   ```

2. **[BUG]** Null pointer in `order_handler.ts:23`
   ```typescript
   // BAD
   const total = order.items.reduce(...)

   // GOOD
   const total = order.items?.reduce(...) ?? 0
   ```

### Warnings
1. **[PERF]** N+1 query in `get_orders()` - Consider eager loading
2. **[MAINT]** Function `processData()` is 45 lines - Extract methods

### Suggestions
1. Consider using a repository pattern for data access
2. Add retry logic for external API calls

### Passed Checks
✓ No hardcoded secrets
✓ Input validation present
✓ Error handling implemented
✓ Tests included
```

## Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| CRITICAL | Security vulnerability, data loss risk | Must fix before merge |
| ERROR | Bug, logic error | Must fix |
| WARNING | Code smell, potential issue | Should fix |
| INFO | Style, suggestion | Optional |

## Integration Points

### Pre-commit Hook
```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: code-review
        name: AI Code Review
        entry: claude code "review staged changes"
        language: system
        pass_filenames: false
```

### GitHub Action
```yaml
name: Code Review
on: [pull_request]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: AI Review
        run: |
          gh pr diff | claude code "review this diff"
```

## Output Format

```
⚡ SKILL_ACTIVATED: #RVWR-4B8K

## Code Review Report

### Files Reviewed
- [file1.ts] - 3 issues
- [file2.py] - 1 issue

### Critical (Must Fix)
[List critical issues]

### Warnings (Should Fix)
[List warnings]

### Passed
[List what passed]

### Verdict: [PASS/NEEDS_WORK/FAIL]
```

## Common Mistakes

- Nitpicking style (use linters)
- Missing security checks
- Not checking for N+1 queries
- Ignoring error handling
- Not verifying test coverage
