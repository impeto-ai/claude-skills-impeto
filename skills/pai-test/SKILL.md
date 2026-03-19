---
name: pai-test
description: Use to build and run tests for Pydantic AI agents. AUTOMATICALLY triggered after pai-audit passes. Activates for "testar agent", "test agent", "agent tests", "mock llm".
chain: none
---

# PAI Test

Specialized in testing Pydantic AI agents with mocked LLM calls.

## When to Use

- AUTOMATICALLY after pai-audit passes
- Building test suite for agents
- Validating agent behavior
- NOT when: testing non-agent code (use test-driven-development)

## Testing Pyramid

```
         /\
        /  \     E2E (real LLM - expensive, optional)
       /----\
      /      \   Integration (agent.run with mock)
     /--------\
    /          \  Unit (schemas, tools, validators)
   /------------\
```

## 1. Schema Tests

```python
import pytest
from pydantic import ValidationError
from my_agent.models import AgentOutput

class TestSchemas:
    def test_output_valid(self):
        output = AgentOutput(response="test", confidence=0.9)
        assert output.confidence == 0.9

    def test_output_rejects_empty_response(self):
        with pytest.raises(ValidationError):
            AgentOutput(response="", confidence=0.9)

    def test_output_confidence_bounds(self):
        with pytest.raises(ValidationError):
            AgentOutput(response="test", confidence=1.5)
```

## 2. Tool Tests (Mock Context)

```python
import pytest
from unittest.mock import AsyncMock
from pydantic_ai import ModelRetry

@pytest.fixture
def mock_ctx():
    ctx = AsyncMock()
    ctx.deps.db = AsyncMock()
    ctx.deps.http_client = AsyncMock()
    return ctx

@pytest.mark.asyncio
async def test_tool_returns_data(mock_ctx):
    mock_ctx.deps.db.find.return_value = [{"id": 1, "name": "Test"}]
    result = await my_tool(mock_ctx, "test query")
    assert len(result) == 1

@pytest.mark.asyncio
async def test_tool_retries_on_not_found(mock_ctx):
    mock_ctx.deps.db.find.return_value = None
    with pytest.raises(ModelRetry, match="not found"):
        await my_tool(mock_ctx, "nonexistent")
```

## 3. Agent Integration Tests

```python
from pydantic_ai import Agent
from pydantic_ai.models.test import TestModel

@pytest.fixture
def test_agent():
    """Agent with test model (no real LLM calls)."""
    return Agent(
        'test',  # Use test model
        output_type=MyOutput,
        deps_type=MyDeps,
    )

@pytest.mark.asyncio
async def test_agent_returns_output(test_agent):
    result = await test_agent.run('test query', deps=mock_deps)
    assert result.output is not None
```

## 4. E2E Tests (Optional, Real LLM)

```python
import os
import pytest

pytestmark = pytest.mark.skipif(
    os.getenv("REAL_LLM_TESTS") != "1",
    reason="Real LLM tests disabled"
)

@pytest.mark.asyncio
async def test_agent_answers_correctly():
    result = await agent.run("What is 2+2?", deps=real_deps)
    assert "4" in result.output.response
```

## Test Fixtures (conftest.py)

```python
import pytest
from unittest.mock import AsyncMock
from dataclasses import dataclass

@pytest.fixture
def mock_deps():
    @dataclass
    class TestDeps:
        http_client: AsyncMock = AsyncMock()
        db: AsyncMock = AsyncMock()
        api_key: str = "test-key"
    return TestDeps()

@pytest.fixture
def agent_output_factory():
    def _create(**kwargs):
        defaults = {"response": "test", "confidence": 0.9, "sources": []}
        return MyOutput(**{**defaults, **kwargs})
    return _create
```

## Running Tests

```bash
# All agent tests
uv run pytest tests/ -v

# With coverage
uv run pytest tests/ --cov=src --cov-report=html

# Only schema tests (fast)
uv run pytest tests/ -k "schema" -v

# Real LLM tests (expensive)
REAL_LLM_TESTS=1 uv run pytest tests/ -k "e2e" -v
```

## Common Mistakes

- Not mocking LLM calls (slow, expensive, flaky)
- Testing implementation instead of behavior
- No ModelRetry test coverage
- Skipping schema validation tests
- No isolation between tests (shared state)
