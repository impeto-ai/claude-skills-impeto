---
name: pai-prompts
description: Use when crafting system prompts for Pydantic AI agents. Activates for "prompt", "system prompt", "system message", "instruções agent".
chain: none
---

# PAI Prompts

Expert in crafting effective system prompts for Pydantic AI agents using composition patterns.

## When to Use

- Designing agent system prompts
- Composing dynamic prompts with context
- Optimizing prompt effectiveness
- NOT when: building agent structure (use pai-agent)
- NOT when: creating tools (use pai-tools)

## Prompt Composition (Not Monolithic)

### Static Base

```python
agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    deps_type=MyDeps,
    output_type=MyOutput,
    system_prompt='You are a financial analyst specializing in agricultural commodities.',
)
```

### Adding Dynamic Context

```python
@agent.system_prompt
def output_rules() -> str:
    return """
    Rules:
    - Always cite data sources
    - Use ISO date format (YYYY-MM-DD)
    - Confidence must reflect source quality
    """

@agent.system_prompt
async def user_context(ctx: RunContext[MyDeps]) -> str:
    user = await ctx.deps.get_current_user()
    return f"""
    Current user: {user.name}
    Role: {user.role}
    Timezone: {user.timezone}
    Preferred language: {user.language}
    """

@agent.system_prompt
async def available_data(ctx: RunContext[MyDeps]) -> str:
    tables = await ctx.deps.db.list_tables()
    return f"""
    Available data tables: {', '.join(tables)}
    Use these table names when generating queries.
    """
```

## Prompt Design Principles

### 1. Role + Context + Constraints + Output Format

```python
agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=AnalysisOutput,
    system_prompt="""
    # Role
    You are a senior data analyst for agricultural operations.

    # Context
    You analyze crop data, weather patterns, and market prices
    to provide actionable insights for farm managers.

    # Constraints
    - Only use data from the provided tools
    - Never fabricate statistics
    - Flag uncertainty when confidence < 0.7

    # Output Format
    Your response must include:
    - summary: 1-2 sentence overview
    - findings: list of key insights
    - confidence: 0.0-1.0 based on data quality
    """,
)
```

### 2. Tool Guidance in Prompts

```python
@agent.system_prompt
def tool_guidance() -> str:
    return """
    # Available Tools
    - search_products: Use for product lookups by name or category
    - get_price_history: Use for historical pricing data
    - check_inventory: Use to verify stock levels

    # Tool Usage Strategy
    1. First search for the product to get its ID
    2. Then use the ID to fetch price history or inventory
    3. Never guess product IDs - always search first
    """
```

### 3. Output Schema Guidance

```python
@agent.system_prompt
def schema_guidance() -> str:
    return """
    # Output Requirements
    - response: Your main answer (required, non-empty)
    - confidence: How sure you are (0.0-1.0)
      - 0.9+: Multiple reliable sources confirm
      - 0.7-0.9: Good evidence but some uncertainty
      - 0.5-0.7: Limited data, moderate confidence
      - <0.5: Insufficient data, flag for review
    - sources: List every data source used
    """
```

## Anti-Patterns

### God Prompt (500 lines)
```python
# RUIM
system_prompt = """You are X that does A, B, C, handles D, E, F,
formats as G, H, I, considers J, K, L..."""  # 500 lines

# BOM - compose
agent = Agent(..., system_prompt='You are X.')

@agent.system_prompt
def constraints() -> str: ...

@agent.system_prompt
async def context(ctx: RunContext[Deps]) -> str: ...
```

### Hardcoded Context
```python
# RUIM - stale context
system_prompt = "Today is 2025-01-01. User is John."

# BOM - dynamic
@agent.system_prompt
async def context(ctx: RunContext[Deps]) -> str:
    return f"Today is {date.today()}. User is {ctx.deps.user.name}."
```

### Vague Instructions
```python
# RUIM
"Be helpful and accurate."

# BOM
"When answering questions about crop yields, cite the specific data source and date range. If data is older than 30 days, flag it as potentially outdated."
```

## Testing Prompts

```python
@pytest.mark.asyncio
async def test_prompt_includes_user_context():
    """System prompt includes user info."""
    result = await agent.run('test', deps=test_deps)
    # Verify through agent behavior, not prompt inspection
    assert result.output.response is not None

@pytest.mark.asyncio
async def test_low_confidence_flagged():
    """Agent flags low confidence correctly."""
    result = await agent.run('obscure topic with no data', deps=deps)
    assert result.output.confidence < 0.7
```

## Common Mistakes

- Monolithic prompts (compose instead)
- Hardcoded dates/users (use dynamic prompts)
- No tool usage guidance (LLM doesn't know strategy)
- Vague instructions (be specific and measurable)
- Missing output schema explanation
- Not testing prompt effectiveness
