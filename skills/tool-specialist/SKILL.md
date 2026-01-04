---
name: tool-specialist
description: Use when creating or editing agent tools. Activates for "tool", "ferramenta", "function call", "criar tool", "tool agent". Specialized in Pydantic AI tools.
---

# Tool Specialist

Expert in developing tools for AI agents using Pydantic AI patterns.

## When to Use

- Creating new tools for agents
- Editing existing tools
- Debugging tool execution
- User says: tool, ferramenta, function call, criar tool
- NOT when: building agent logic (use graph-agent)

## Tool Anatomy

```python
from pydantic_ai import Agent, RunContext, Tool
from pydantic import BaseModel, Field

# 1. DEFINE INPUT SCHEMA
class SearchInput(BaseModel):
    """Input schema for search tool."""
    query: str = Field(..., description="Search query", min_length=1)
    max_results: int = Field(default=10, ge=1, le=100)

# 2. DEFINE OUTPUT SCHEMA
class SearchResult(BaseModel):
    """Single search result."""
    title: str
    url: str
    snippet: str

class SearchOutput(BaseModel):
    """Tool output schema."""
    results: list[SearchResult]
    total_found: int

# 3. IMPLEMENT TOOL FUNCTION
async def search_web(
    ctx: RunContext[AgentDeps],
    input: SearchInput
) -> SearchOutput:
    """Search the web for information.

    Args:
        ctx: Runtime context with dependencies
        input: Validated search input

    Returns:
        SearchOutput with results
    """
    # Access dependencies
    http_client = ctx.deps.http_client

    # Execute search
    raw_results = await http_client.get(
        "https://api.search.com/search",
        params={"q": input.query, "limit": input.max_results}
    )

    # Parse and validate output
    results = [
        SearchResult(
            title=r["title"],
            url=r["url"],
            snippet=r["snippet"]
        )
        for r in raw_results["items"]
    ]

    return SearchOutput(results=results, total_found=len(results))

# 4. REGISTER WITH AGENT
agent = Agent(
    "openai:gpt-4",
    tools=[search_web],
)
```

## Tool Patterns

### Pattern 1: Database Tool

```python
from pydantic_ai import RunContext
from pydantic import BaseModel

class QueryInput(BaseModel):
    table: str
    filters: dict = {}
    limit: int = 100

class QueryOutput(BaseModel):
    rows: list[dict]
    count: int

async def query_database(
    ctx: RunContext[AgentDeps],
    input: QueryInput
) -> QueryOutput:
    """Query the database safely."""
    db = ctx.deps.database

    # Build safe query (no SQL injection)
    query = db.table(input.table).select("*")

    for field, value in input.filters.items():
        query = query.eq(field, value)

    result = await query.limit(input.limit).execute()

    return QueryOutput(rows=result.data, count=len(result.data))
```

### Pattern 2: External API Tool

```python
class WeatherInput(BaseModel):
    city: str
    country_code: str = "US"

class WeatherOutput(BaseModel):
    temperature: float
    conditions: str
    humidity: int

async def get_weather(
    ctx: RunContext[AgentDeps],
    input: WeatherInput
) -> WeatherOutput:
    """Get current weather for a city."""
    api_key = ctx.deps.config.weather_api_key

    async with ctx.deps.http_client as client:
        response = await client.get(
            f"https://api.weather.com/v1/current",
            params={"city": input.city, "country": input.country_code},
            headers={"Authorization": f"Bearer {api_key}"}
        )
        data = response.json()

    return WeatherOutput(
        temperature=data["temp"],
        conditions=data["conditions"],
        humidity=data["humidity"]
    )
```

### Pattern 3: File System Tool

```python
from pathlib import Path

class ReadFileInput(BaseModel):
    path: str
    encoding: str = "utf-8"

class ReadFileOutput(BaseModel):
    content: str
    size_bytes: int
    exists: bool

async def read_file(
    ctx: RunContext[AgentDeps],
    input: ReadFileInput
) -> ReadFileOutput:
    """Read a file from allowed directories."""
    # Security: validate path
    allowed_dirs = ctx.deps.config.allowed_directories
    file_path = Path(input.path).resolve()

    if not any(file_path.is_relative_to(d) for d in allowed_dirs):
        raise ValueError(f"Access denied: {input.path}")

    if not file_path.exists():
        return ReadFileOutput(content="", size_bytes=0, exists=False)

    content = file_path.read_text(encoding=input.encoding)

    return ReadFileOutput(
        content=content,
        size_bytes=len(content.encode()),
        exists=True
    )
```

### Pattern 4: Stateful Tool (Updates Context)

```python
class AddMemoryInput(BaseModel):
    key: str
    value: str
    importance: float = 0.5

class AddMemoryOutput(BaseModel):
    stored: bool
    memory_count: int

async def add_to_memory(
    ctx: RunContext[AgentDeps],
    input: AddMemoryInput
) -> AddMemoryOutput:
    """Add information to agent's memory."""
    memory_store = ctx.deps.memory

    await memory_store.add(
        key=input.key,
        value=input.value,
        metadata={"importance": input.importance}
    )

    count = await memory_store.count()

    return AddMemoryOutput(stored=True, memory_count=count)
```

### Pattern 5: Computational Tool

```python
import ast
import operator

class CalculateInput(BaseModel):
    expression: str = Field(..., pattern=r'^[\d\s\+\-\*\/\(\)\.]+$')

class CalculateOutput(BaseModel):
    result: float
    expression: str

SAFE_OPERATORS = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
}

def safe_eval(node):
    """Safely evaluate math expression."""
    if isinstance(node, ast.Num):
        return node.n
    elif isinstance(node, ast.BinOp):
        left = safe_eval(node.left)
        right = safe_eval(node.right)
        return SAFE_OPERATORS[type(node.op)](left, right)
    raise ValueError("Unsafe expression")

async def calculate(
    ctx: RunContext[AgentDeps],
    input: CalculateInput
) -> CalculateOutput:
    """Safely calculate mathematical expression."""
    tree = ast.parse(input.expression, mode='eval')
    result = safe_eval(tree.body)

    return CalculateOutput(
        result=result,
        expression=input.expression
    )
```

## Tool Best Practices

```markdown
## Tool Checklist

### Input Validation
- [ ] All fields have type hints
- [ ] Required fields marked with ...
- [ ] Optional fields have defaults
- [ ] Constraints (min, max, pattern) added
- [ ] Description for each field (LLM uses this!)

### Output Validation
- [ ] Output schema defined
- [ ] All possible outputs covered
- [ ] Error cases return proper schema

### Security
- [ ] No arbitrary code execution
- [ ] Path traversal prevented
- [ ] SQL injection prevented
- [ ] API keys from deps, not hardcoded
- [ ] Rate limiting considered

### Reliability
- [ ] Timeout on external calls
- [ ] Retry logic for transient failures
- [ ] Graceful error handling
- [ ] Logging for debugging
```

## Error Handling in Tools

```python
from pydantic_ai import ModelRetry

async def risky_tool(
    ctx: RunContext[AgentDeps],
    input: ToolInput
) -> ToolOutput:
    """Tool with proper error handling."""
    try:
        result = await external_api_call(input)
        return ToolOutput(data=result)

    except RateLimitError:
        # Tell agent to retry later
        raise ModelRetry("Rate limited, try again in 60s")

    except ValidationError as e:
        # Return error in schema
        return ToolOutput(error=str(e), data=None)

    except Exception as e:
        # Log and re-raise for agent to handle
        ctx.deps.logger.error(f"Tool failed: {e}")
        raise
```

## Testing Tools

```python
import pytest
from unittest.mock import AsyncMock

@pytest.fixture
def mock_context():
    """Create mock RunContext."""
    ctx = AsyncMock()
    ctx.deps.http_client = AsyncMock()
    ctx.deps.database = AsyncMock()
    return ctx

@pytest.mark.asyncio
async def test_search_tool_returns_results(mock_context):
    """Search tool returns valid output."""
    mock_context.deps.http_client.get.return_value = {
        "items": [{"title": "Test", "url": "http://test.com", "snippet": "..."}]
    }

    result = await search_web(mock_context, SearchInput(query="test"))

    assert len(result.results) == 1
    assert result.results[0].title == "Test"
```

## Output Format

```
⚡ SKILL_ACTIVATED: #TOOL-3C9P

## Tool Created: [tool_name]

### Input Schema
```python
class [Name]Input(BaseModel):
    ...
```

### Output Schema
```python
class [Name]Output(BaseModel):
    ...
```

### Implementation
- File: `agents/[agent]/tools/[tool_name].py`
- Dependencies: [list]

### Tests Added
- `test_[tool_name]_happy_path`
- `test_[tool_name]_error_handling`
- `test_[tool_name]_validation`
```

## Common Mistakes

- Missing field descriptions (LLM can't use tool properly)
- No input validation (garbage in, garbage out)
- Hardcoded secrets (use deps)
- No timeout on external calls (hangs forever)
- Overly complex tools (split into smaller ones)
- Not testing error paths
