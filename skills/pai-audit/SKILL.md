---
name: pai-audit
description: Use to audit Pydantic AI agent implementations. AUTOMATICALLY triggered after pai-agent/pai-tools/pai-multi changes. Uses context7 for latest docs.
chain: pai-test
---

# PAI Audit

Heavy-duty auditor for Pydantic AI agent implementations. Uses context7 for up-to-date documentation.

## When to Use

- AUTOMATICALLY after pai-agent, pai-tools, pai-multi changes
- Before deploying agents to production
- Manually reviewing agent code
- NOT when: writing new code (use pai-agent)

## Audit Process

```
1. FETCH DOCS    → context7 latest Pydantic AI v1.0.5+ docs
2. AGENT AUDIT   → Validate Agent config, deps, output_type
3. TOOLS AUDIT   → Check tools, ModelRetry, docstrings
4. OUTPUT AUDIT  → Verify Pydantic models, validators
5. SECURITY      → Check deps, secrets, input validation
6. VERDICT       → PASS → pai-test / FAIL → fix issues
```

## Step 1: Always Fetch Latest Docs

```
Tool: mcp__context7__query-docs
Library: /pydantic/pydantic-ai
Query: [specific pattern being audited]
```

## Audit Checklist

### Agent Configuration
```
- [ ] output_type is a Pydantic BaseModel (not dict/str for complex outputs)
- [ ] deps_type is @dataclass (not BaseModel)
- [ ] instrument=True for observability
- [ ] System prompt is composed (not monolithic >20 lines)
- [ ] Model specified explicitly (not default)
```

### Tools
```
- [ ] Every tool has descriptive docstring with Args
- [ ] retries parameter set on tools that can fail
- [ ] ModelRetry used for recoverable errors
- [ ] Regular raise for system errors (auth, config)
- [ ] RunContext[DepsType] properly typed
- [ ] No hardcoded secrets
- [ ] Timeout on external calls
```

### Output Models
```
- [ ] All fields have type hints
- [ ] Field() with constraints (min_length, ge, le)
- [ ] Validators for complex fields
- [ ] Union types properly discriminated
- [ ] @agent.output_validator for critical outputs
```

### Dependencies
```
- [ ] @dataclass (not BaseModel)
- [ ] httpx.AsyncClient shared (not created per call)
- [ ] No os.environ in tools (use deps)
- [ ] Secrets via deps or BaseSettings
```

### Security
```
- [ ] No arbitrary code execution
- [ ] Input validation in tools
- [ ] No SQL injection risk
- [ ] No path traversal
- [ ] API keys from deps only
```

## Severity Levels

| Level | Description | Action |
|---|---|---|
| CRITICAL | Breaks in production | MUST fix |
| HIGH | Likely issues | Fix before deploy |
| MEDIUM | Best practice violation | Fix soon |
| LOW | Suggestion | Nice to have |

## Output Format

### PASSING
```
## PAI Audit: [Agent Name]

### Summary: PASSED

| Category | Score |
|---|---|
| Agent Config | 9/10 |
| Tools | 10/10 |
| Output Models | 8/10 |
| Dependencies | 9/10 |
| Security | 10/10 |

### Minor Recommendations
1. [Recommendation]

→ CHAIN: Triggering pai-test
```

### FAILING
```
## PAI Audit: [Agent Name]

### Summary: FAILED - N critical issues

#### CRITICAL: [Issue]
- File: path/to/file.py:L42
- Problem: [description]
- Fix: [code fix]

→ BLOCKED: Fix issues before proceeding
```

## Chain Behavior

- ON PASS → pai-test (run tests)
- ON FAIL → fix issues, re-audit
