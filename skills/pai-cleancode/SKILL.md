---
name: pai-cleancode
description: Use when reviewing Python AI code for Pydantic AI projects. Activates for "clean code ai", "review ai code", "audit python ai", "anti-pattern python ai".
chain: none
---

# PAI Clean Code

Auditor for Python AI code. Philosophy: **less is more**.

## When to Use

- Reviewing agent code quality
- Identifying anti-patterns
- Enforcing naming conventions
- NOT when: debugging runtime errors (use systematic-debugging)

## Philosophy

```
LESS                              MORE
─────────────────────────────────────────
Less classes                      More functions
Less inheritance                  More composition
Less premature abstractions       More direct code
Less magic                        More explicitness
Less comments                     More clear names
Less try/except generic           More validation at entry
Less Any/dict                     More specific types
Less nested ifs                   More early returns
```

## Naming Rules

```python
# Classes: PascalCase, domain-specific
class UserProfile: ...       # BOM
class Data: ...              # RUIM (generico)
class AIHelper: ...          # RUIM (helper = sem responsabilidade)

# Functions: snake_case, verb + object
def extract_entities(): ...  # BOM
def do_stuff(): ...          # RUIM

# Booleans: is_, has_, can_ prefix
is_authenticated = True      # BOM
flag = True                  # RUIM

# PROIBIDO: data, info, manager, handler, helper, utils, misc, temp
```

## Pydantic Best Practices

```python
# BOM
class AgentConfig(BaseModel):
    model_config = ConfigDict(strict=True, frozen=True)
    model_name: str = Field(min_length=1)
    temperature: float = Field(default=0.7, ge=0.0, le=2.0)
    tools: list[ToolDef] = Field(default_factory=list)

# RUIM
class Config(BaseModel):
    data: dict          # dict generico
    items: list         # list sem tipo
    value: Any          # sem contrato
```

## Dependency Injection

```python
# BOM
@dataclass
class SearchDeps:
    http_client: httpx.AsyncClient
    api_key: str

agent = Agent('openai:gpt-4o', deps_type=SearchDeps)

@agent.tool
async def search(ctx: RunContext[SearchDeps], query: str) -> str:
    resp = await ctx.deps.http_client.get(url)
    return resp.text

# RUIM
@agent.tool
async def search(ctx, query: str) -> str:
    client = httpx.AsyncClient()        # created inside
    api_key = os.environ["API_KEY"]     # env direto
    resp = await client.get(url)
    return resp.text
```

## Function Rules

- Max ~20 lines per function
- Max 3 parameters (group in dataclass)
- Max 2 indentation levels
- Early return always
- Input typed -> Output typed

## Audit Checklist

```
NAMING
[ ] Descriptive names (no data, info, helper)
[ ] Functions: verb + object
[ ] Booleans: is_/has_/can_ prefix

PYDANTIC
[ ] Field() with constraints
[ ] No dict/list/Any generic
[ ] frozen=True where applicable
[ ] @field_validator with @classmethod

SIMPLICITY
[ ] Functions <= 20 lines
[ ] Max 3 parameters
[ ] Early returns
[ ] No over-engineering

DEPS
[ ] @dataclass for deps
[ ] RunContext typed
[ ] No os.environ in tools
[ ] httpx shared

TYPES
[ ] All inputs/outputs typed
[ ] Enums instead of magic strings
[ ] Specific exceptions (no catch-all)
```

## Output Format

```
## PAI Clean Code Audit

### Score: X/10

### Issues Found

#### [CRITICAL] Issue name
- File: path:L42
- Category: NAMING | PYDANTIC | SIMPLICITY | DEPS | TYPES
- Before: `bad code`
- After: `good code`
```

## Common Mistakes

- dict/Any in Pydantic models
- os.environ in tools
- God functions (>20 lines)
- Generic names (data, info, helper)
- Catch-all exceptions
- httpx client created per call
