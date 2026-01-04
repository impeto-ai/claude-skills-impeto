---
name: agent-tester
description: Use to build and run tests for AI agents. AUTOMATICALLY triggered after agent-audit-graph passes. TDD-inspired testing for agents.
---

# Agent Tester

Specialized in building and running tests for AI agents. TDD-inspired but agent-focused.

## When to Use

- AUTOMATICALLY after agent-audit-graph passes
- Building test suite for new agent
- Validating agent behavior changes
- User says: testar agent, test agent, agent tests
- NOT when: testing non-agent code (use test-driven-development)

## Testing Philosophy

```
┌─────────────────────────────────────────────────────────────────┐
│              AGENT TESTING PYRAMID                              │
├─────────────────────────────────────────────────────────────────┤
│                      /\                                         │
│                     /  \     E2E Tests                          │
│                    /    \    (Full agent run)                   │
│                   /──────\                                      │
│                  /        \   Integration Tests                 │
│                 /          \  (Nodes + LLM mock)                │
│                /────────────\                                   │
│               /              \  Unit Tests                      │
│              /                \ (Schemas, Utils)                │
│             /──────────────────\                                │
└─────────────────────────────────────────────────────────────────┘
```

## Test Categories

### 1. Schema Tests

```python
import pytest
from pydantic import ValidationError
from agents.my_agent.state import AgentState, AgentOutput

class TestAgentSchemas:
    """Test Pydantic model validation."""

    def test_state_valid_creation(self):
        """State creates with valid data."""
        state = AgentState(messages=[], step=0)
        assert state.step == 0

    def test_state_rejects_invalid_step(self):
        """State rejects negative step."""
        with pytest.raises(ValidationError):
            AgentState(messages=[], step=-1)

    def test_output_requires_response(self):
        """Output must have response field."""
        with pytest.raises(ValidationError):
            AgentOutput(confidence=0.9)  # missing response

    def test_output_confidence_bounds(self):
        """Confidence must be 0-1."""
        with pytest.raises(ValidationError):
            AgentOutput(response="test", confidence=1.5)
```

### 2. Node Tests (Mock LLM)

```python
import pytest
from unittest.mock import AsyncMock, patch
from agents.my_agent.nodes import ProcessInput, GenerateResponse
from agents.my_agent.state import AgentState

class TestAgentNodes:
    """Test individual nodes with mocked LLM."""

    @pytest.fixture
    def mock_llm(self):
        """Mock LLM responses."""
        with patch('pydantic_ai.Agent.run') as mock:
            mock.return_value = AsyncMock(
                data={"response": "mocked response"}
            )
            yield mock

    @pytest.mark.asyncio
    async def test_process_input_advances_step(self, mock_llm):
        """ProcessInput increments step counter."""
        state = AgentState(messages=[{"role": "user", "content": "hi"}])
        node = ProcessInput()

        result = await node.run(state)

        assert result.step == 1

    @pytest.mark.asyncio
    async def test_generate_response_returns_end(self, mock_llm):
        """GenerateResponse returns End with output."""
        state = AgentState(messages=[], context={"ready": True})
        node = GenerateResponse()

        result = await node.run(state)

        assert isinstance(result, End)
        assert result.data.response == "mocked response"
```

### 3. Tool Tests

```python
import pytest
from agents.my_agent.tools import search_tool, calculate_tool

class TestAgentTools:
    """Test agent tools in isolation."""

    @pytest.mark.asyncio
    async def test_search_tool_returns_results(self):
        """Search tool returns list of results."""
        result = await search_tool.run(query="test query")

        assert isinstance(result, list)
        assert len(result) > 0

    @pytest.mark.asyncio
    async def test_search_tool_handles_empty_query(self):
        """Search tool handles empty query gracefully."""
        result = await search_tool.run(query="")

        assert result == []

    @pytest.mark.asyncio
    async def test_calculate_tool_math(self):
        """Calculate tool does math correctly."""
        result = await calculate_tool.run(expression="2 + 2")

        assert result == 4
```

### 4. Graph Tests (Integration)

```python
import pytest
from agents.my_agent.graph import agent_graph
from agents.my_agent.state import AgentState

class TestAgentGraph:
    """Test full graph execution with mocked LLM."""

    @pytest.fixture
    def mock_all_llm_calls(self):
        """Mock all LLM calls in graph."""
        with patch('pydantic_ai.Agent.run') as mock:
            mock.side_effect = [
                AsyncMock(data={"intent": "query"}),
                AsyncMock(data={"response": "final answer"}),
            ]
            yield mock

    @pytest.mark.asyncio
    async def test_graph_completes_simple_query(self, mock_all_llm_calls):
        """Graph completes for simple query."""
        state = AgentState(
            messages=[{"role": "user", "content": "What is 2+2?"}]
        )

        result = await agent_graph.run(state)

        assert result.response is not None
        assert result.confidence > 0

    @pytest.mark.asyncio
    async def test_graph_handles_error_path(self):
        """Graph handles errors gracefully."""
        state = AgentState(
            messages=[{"role": "user", "content": ""}]  # empty
        )

        result = await agent_graph.run(state)

        assert "error" in result.response.lower() or result.confidence < 0.5
```

### 5. State Persistence Tests

```python
import pytest
import tempfile
from pathlib import Path
from pydantic_graph.persistence import FileStatePersistence
from agents.my_agent.graph import agent_graph
from agents.my_agent.state import AgentState

class TestAgentPersistence:
    """Test state persistence and recovery."""

    @pytest.fixture
    def temp_persistence(self):
        """Create temporary persistence file."""
        with tempfile.NamedTemporaryFile(suffix='.json', delete=False) as f:
            yield FileStatePersistence(Path(f.name))

    @pytest.mark.asyncio
    async def test_state_persists_between_runs(self, temp_persistence):
        """State is saved and can be restored."""
        state = AgentState(messages=[], step=5)

        await agent_graph.initialize(
            start_node=ProcessInput(),
            state=state,
            persistence=temp_persistence
        )

        # Simulate restart - load from persistence
        async with agent_graph.iter_from_persistence(temp_persistence) as run:
            restored = run.state

        assert restored.step == 5
```

### 6. E2E Tests (Real LLM - Optional)

```python
import pytest
import os

# Only run if REAL_LLM_TESTS=1
pytestmark = pytest.mark.skipif(
    os.getenv("REAL_LLM_TESTS") != "1",
    reason="Real LLM tests disabled"
)

class TestAgentE2E:
    """End-to-end tests with real LLM (expensive)."""

    @pytest.mark.asyncio
    async def test_agent_answers_factual_question(self):
        """Agent answers simple factual question."""
        result = await agent.run("What is the capital of France?")

        assert "paris" in result.response.lower()
        assert result.confidence > 0.8
```

## Test Fixtures for Agents

```python
# conftest.py
import pytest
from unittest.mock import AsyncMock, patch

@pytest.fixture
def mock_openai():
    """Mock OpenAI API calls."""
    with patch('openai.AsyncOpenAI') as mock:
        client = AsyncMock()
        client.chat.completions.create.return_value = AsyncMock(
            choices=[AsyncMock(message=AsyncMock(content="mocked"))]
        )
        mock.return_value = client
        yield client

@pytest.fixture
def agent_state_factory():
    """Factory for creating test states."""
    def _create(**kwargs):
        defaults = {"messages": [], "step": 0, "context": {}}
        return AgentState(**{**defaults, **kwargs})
    return _create

@pytest.fixture
def mock_tool_results():
    """Predefined tool results for testing."""
    return {
        "search": [{"title": "Result 1", "url": "http://example.com"}],
        "calculate": 42,
        "fetch": {"data": "test data"},
    }
```

## Running Tests

```bash
# Run all agent tests
pytest tests/agents/ -v

# Run with coverage
pytest tests/agents/ --cov=agents --cov-report=html

# Run only schema tests (fast)
pytest tests/agents/ -k "schema" -v

# Run integration tests
pytest tests/agents/ -k "graph" -v

# Run real LLM tests (expensive)
REAL_LLM_TESTS=1 pytest tests/agents/ -k "e2e" -v
```

## Output Format

```
⚡ SKILL_ACTIVATED: #TSTR-6B2N

## Agent Test Report: [Agent Name]

### Test Summary
| Category | Passed | Failed | Skipped |
|----------|--------|--------|---------|
| Schema | 8 | 0 | 0 |
| Nodes | 12 | 0 | 2 |
| Tools | 5 | 1 | 0 |
| Graph | 4 | 0 | 0 |
| Persistence | 3 | 0 | 0 |
| **Total** | **32** | **1** | **2** |

### Failed Tests
```
FAILED tests/agents/test_tools.py::test_search_empty_query
  AssertionError: Expected [], got None
```

### Coverage
- Lines: 87%
- Branches: 72%
- Missing: `nodes.py:45-50` (error path)

### Verdict
⚠️ 1 FAILURE - Fix required before deploy
```

## Common Mistakes

- Not mocking LLM calls (slow, expensive, flaky)
- Testing implementation instead of behavior
- No edge case coverage (empty input, errors)
- Skipping persistence tests
- No isolation between tests (shared state)

---

## ⚠️ CHAIN STATUS

**After Testing:**
```
→ IF ALL PASS: Agent ready for deployment ✅
→ IF FAILURES: Return to graph-agent to fix
→ NO FORWARD CHAIN: End of pipeline
```
