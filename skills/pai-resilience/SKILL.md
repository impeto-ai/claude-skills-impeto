---
name: pai-resilience
description: Use when implementing error handling, retry logic, fallbacks for Pydantic AI agents. Activates for "resilience", "retry", "fallback", "error handling", "ModelRetry".
chain: none
---

# PAI Resilience

Expert in building fault-tolerant Pydantic AI agents with ModelRetry, fallback strategies, and graceful degradation.

## When to Use

- Implementing tool retries with ModelRetry
- Adding fallback strategies
- Error handling for production agents
- NOT when: building agent structure (use pai-agent)

## ModelRetry: The Core Mechanism

ModelRetry tells the LLM to try again with different input. It's NOT a system retry.

```python
from pydantic_ai import Agent, RunContext, ModelRetry

@agent.tool(retries=3)
async def get_user(ctx: RunContext[Deps], name: str) -> int:
    """Get user ID by name."""
    user = await ctx.deps.db.find_user(name=name)
    if user is None:
        raise ModelRetry(
            f'No user found with name {name!r}. '
            'Remember to provide their full name (first + last).'
        )
    return user.id
```

### When to Use ModelRetry vs raise

```python
@agent.tool(retries=3)
async def fetch_data(ctx: RunContext[Deps], resource_id: str) -> dict:
    try:
        return await ctx.deps.api.get(resource_id)

    except NotFoundError:
        # ModelRetry: LLM gave wrong ID, guide it
        raise ModelRetry(
            f'Resource {resource_id} not found. '
            'Check the ID format (e.g., RES-123).'
        )

    except RateLimitError:
        # ModelRetry: transient, suggest alternative
        raise ModelRetry(
            'Rate limited. Try using cached data or a different endpoint.'
        )

    except AuthenticationError:
        # DON'T ModelRetry: system error, LLM can't fix
        raise

    except ValidationError as e:
        # ModelRetry: LLM can fix its input
        raise ModelRetry(f'Invalid input: {e}. Fix the format and retry.')
```

## Output Validator as Safety Net

```python
@agent.output_validator
async def validate_output(ctx: RunContext[Deps], output: Output) -> Output:
    if isinstance(output, ErrorOutput):
        return output

    try:
        await ctx.deps.db.execute(f'EXPLAIN {output.sql_query}')
    except QueryError as e:
        raise ModelRetry(f'Invalid SQL: {e}') from e

    return output
```

## Multi-Model Fallback

```python
MODELS = [
    'anthropic:claude-sonnet-4-20250514',
    'openai:gpt-4o',
    'google-gla:gemini-1.5-flash',
]

async def resilient_run(prompt: str, deps: Deps) -> str:
    for model in MODELS:
        try:
            agent = Agent(model, output_type=MyOutput, deps_type=type(deps))
            result = await agent.run(prompt, deps=deps)
            return result.output
        except Exception as e:
            logger.warning(f'{model} failed: {e}')
            continue

    raise RuntimeError('All models failed')
```

## Timeout Strategy

```python
import asyncio

async def run_with_timeout(prompt: str, deps: Deps, timeout: float = 30.0) -> str:
    try:
        result = await asyncio.wait_for(
            agent.run(prompt, deps=deps),
            timeout=timeout,
        )
        return result.output
    except asyncio.TimeoutError:
        # Fallback to simpler/faster model
        fast_agent = Agent('google-gla:gemini-2.0-flash', output_type=str)
        result = await fast_agent.run(prompt, deps=deps)
        return result.output
```

## Graceful Degradation

```python
async def answer_with_degradation(query: str, deps: Deps) -> str:
    # Level 1: Full analysis
    try:
        result = await full_agent.run(query, deps=deps)
        return result.output.detailed_analysis
    except Exception:
        pass

    # Level 2: Simple answer
    try:
        result = await simple_agent.run(query, deps=deps)
        return f'[Simplified] {result.output}'
    except Exception:
        pass

    # Level 3: Canned response
    return 'I am currently unable to process your request. Please try again later.'
```

## Error Tracking Pattern

```python
from dataclasses import dataclass, field

@dataclass
class ResilientDeps:
    http_client: httpx.AsyncClient
    errors: list[str] = field(default_factory=list)
    retry_count: int = 0
    max_retries: int = 3

@agent.tool(retries=3)
async def safe_fetch(ctx: RunContext[ResilientDeps], url: str) -> str:
    try:
        response = await ctx.deps.http_client.get(url, timeout=10.0)
        response.raise_for_status()
        return response.text
    except httpx.HTTPError as e:
        ctx.deps.errors.append(str(e))
        ctx.deps.retry_count += 1
        raise ModelRetry(f'HTTP error: {e}. Try a different URL or approach.')
```

## Testing Resilience

```python
@pytest.mark.asyncio
async def test_model_retry_on_not_found():
    with pytest.raises(ModelRetry, match='No user found'):
        await get_user(mock_ctx, 'nonexistent')

@pytest.mark.asyncio
async def test_fallback_tries_all_models():
    result = await resilient_run('test', deps)
    assert result is not None

@pytest.mark.asyncio
async def test_timeout_uses_fallback():
    result = await run_with_timeout('test', deps, timeout=0.001)
    assert result is not None
```

## Common Mistakes

- Using regular exceptions instead of ModelRetry in tools
- No retries parameter on @agent.tool
- Infinite retry without max_retries
- Same timeout for all models
- Not logging errors before fallback
- Not testing error paths
- ModelRetry for system errors (auth, config)
