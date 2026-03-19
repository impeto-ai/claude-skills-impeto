---
name: pai-tools
description: Use when creating or editing agent tools for Pydantic AI. Activates for "tool", "ferramenta", "function call", "criar tool", "RunContext", "ModelRetry".
chain: pai-audit
---

# PAI Tools

Expert in developing tools for Pydantic AI agents. Tools are how agents interact with the outside world.

## When to Use

- Creating new tools for agents
- Editing existing tools
- Debugging tool execution
- Implementing ModelRetry patterns
- NOT when: building agent structure (use pai-agent)

## Tool Anatomy

```python
from pydantic_ai import Agent, RunContext, ModelRetry

@dataclass
class MyDeps:
    http_client: httpx.AsyncClient
    db: DatabaseConn

agent = Agent('openai:gpt-4o', deps_type=MyDeps)

@agent.tool(retries=3)
async def search_users(ctx: RunContext[MyDeps], name: str) -> list[dict]:
    """Search users by name.

    Args:
        ctx: Runtime context with dependencies.
        name: Full name to search for.
    """
    users = await ctx.deps.db.search(name=name)
    if not users:
        raise ModelRetry(
            f'No users found for {name!r}. '
            'Try searching by email or partial name.'
        )
    return [u.to_dict() for u in users]
```

## Key Rules

### 1. Docstrings ARE the tool description
The LLM reads the docstring to understand the tool. Be explicit:

```python
# RUIM - LLM nao sabe o que fazer
@agent.tool
async def get_data(ctx: RunContext[Deps], id: str) -> dict:
    """Get data."""

# BOM - LLM sabe exatamente
@agent.tool
async def get_user_profile(ctx: RunContext[Deps], user_id: str) -> dict:
    """Get a user's complete profile including name, email, and preferences.

    Use this when you need user details to personalize responses.
    Returns empty dict if user not found.

    Args:
        ctx: Runtime context.
        user_id: The UUID of the user to look up.
    """
```

### 2. ModelRetry for Self-Correction

```python
@agent.tool(retries=3)
async def fetch_product(ctx: RunContext[Deps], product_id: str) -> dict:
    """Fetch product details by ID."""
    try:
        return await ctx.deps.api.get_product(product_id)
    except NotFoundError:
        raise ModelRetry(
            f'Product {product_id} not found. '
            'Check if the ID format is correct (e.g., PROD-123).'
        )
    except RateLimitError:
        raise ModelRetry('Rate limited. Try a different approach or wait.')
    except AuthError:
        raise  # System error - don't retry
```

### 3. ModelRetry vs Regular Exceptions

| Scenario | Use |
|---|---|
| Wrong input from LLM | `ModelRetry` (guide the model) |
| External API down | `ModelRetry` if transient, `raise` if permanent |
| Auth failure | `raise` (model can't fix auth) |
| Validation error | `ModelRetry` (model can fix input) |
| System error | `raise` (let error propagate) |

### 4. Tool Return Types
Tools should return simple, serializable types:

```python
# BOM - simple types
async def tool(ctx, query: str) -> str: ...
async def tool(ctx, id: int) -> dict: ...
async def tool(ctx, ids: list[str]) -> list[dict]: ...

# EVITAR - complex objects
async def tool(ctx, query: str) -> CustomObject: ...  # LLM can't read this
```

## Tool Patterns

### Database Tool
```python
@agent.tool
async def query_records(ctx: RunContext[Deps], table: str, filters: dict) -> list[dict]:
    """Query database records with filters.

    Args:
        ctx: Runtime context.
        table: Table name (users, orders, products).
        filters: Key-value pairs for filtering.
    """
    allowed_tables = {'users', 'orders', 'products'}
    if table not in allowed_tables:
        raise ModelRetry(f'Invalid table. Choose from: {allowed_tables}')

    return await ctx.deps.db.query(table, filters)
```

### External API Tool
```python
@agent.tool(retries=2)
async def search_web(ctx: RunContext[Deps], query: str, max_results: int = 5) -> list[dict]:
    """Search the web for information.

    Args:
        ctx: Runtime context.
        query: Search query string (be specific).
        max_results: Number of results (1-10, default 5).
    """
    if len(query) < 3:
        raise ModelRetry('Query too short. Be more specific.')

    response = await ctx.deps.http_client.get(
        'https://api.search.com/search',
        params={'q': query, 'limit': min(max_results, 10)},
        headers={'Authorization': f'Bearer {ctx.deps.api_key}'},
        timeout=10.0,
    )
    response.raise_for_status()
    return response.json()['results']
```

### Stateful Tool
```python
@agent.tool
async def remember(ctx: RunContext[Deps], key: str, value: str) -> str:
    """Store information for later retrieval.

    Args:
        ctx: Runtime context.
        key: Short identifier for the information.
        value: The information to remember.
    """
    await ctx.deps.memory.store(key, value)
    return f'Stored: {key}'

@agent.tool
async def recall(ctx: RunContext[Deps], key: str) -> str:
    """Retrieve previously stored information.

    Args:
        ctx: Runtime context.
        key: The identifier used when storing.
    """
    value = await ctx.deps.memory.get(key)
    if not value:
        raise ModelRetry(f'No memory found for key {key!r}. Check the key name.')
    return value
```

## Tool Security Checklist

```
- [ ] No arbitrary code execution
- [ ] Path traversal prevented (validate file paths)
- [ ] SQL injection prevented (parameterized queries)
- [ ] API keys from deps, never hardcoded
- [ ] Timeout on external calls
- [ ] Input validation in tool (not just Pydantic)
- [ ] Rate limiting considered
```

## Testing Tools

```python
import pytest
from unittest.mock import AsyncMock

@pytest.fixture
def mock_ctx():
    ctx = AsyncMock()
    ctx.deps.http_client = AsyncMock()
    ctx.deps.db = AsyncMock()
    return ctx

@pytest.mark.asyncio
async def test_search_returns_results(mock_ctx):
    mock_ctx.deps.http_client.get.return_value = AsyncMock(
        json=lambda: {'results': [{'title': 'Test'}]},
        raise_for_status=lambda: None,
    )
    result = await search_web(mock_ctx, 'test query')
    assert len(result) == 1

@pytest.mark.asyncio
async def test_search_retries_on_short_query(mock_ctx):
    with pytest.raises(ModelRetry):
        await search_web(mock_ctx, 'ab')
```

## Common Mistakes

- Missing docstrings (LLM can't understand the tool)
- No retries parameter (tool fails silently)
- Using regular exceptions instead of ModelRetry
- Hardcoded secrets in tool body
- No timeout on HTTP calls
- Returning complex objects (return dicts/strings)
- Tool does too many things (split into smaller tools)

## Chain Behavior

After creating/modifying tools:
→ AUTOMATICALLY trigger: pai-audit
