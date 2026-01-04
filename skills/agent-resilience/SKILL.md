---
name: agent-resilience
description: Use when implementing error handling, retry logic, fallbacks for graph-based agents. Activates for "resilience", "retry", "fallback", "error handling", "ModelRetry".
---

# Agent Resilience (Graph-Specialized)

Expert in building fault-tolerant **Pydantic AI agents with graph-based error handling**, including ModelRetry, fallback nodes, and state-based error tracking.

## When to Use

- Implementing tool retries with ModelRetry
- Adding error handling nodes in graphs
- Setting up fallback paths in workflows
- User says: resilience, retry, fallback, ModelRetry
- NOT when: building graph structure (use graph-agent)

## Graph Resilience Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                 GRAPH RESILIENCE PATTERNS                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. ModelRetry   → Tool-level retries (Pydantic AI native)    │
│   2. Error Nodes  → Graph-level error handling                 │
│   3. Fallback     → Alternative nodes when primary fails       │
│   4. State Track  → Error history in GraphRunContext           │
│   5. Graceful End → End with error state vs crash              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Pattern 1: ModelRetry for Tool Retries

The **native Pydantic AI way** to handle retries in tools:

```python
from pydantic_ai import Agent, RunContext, ModelRetry

@dataclass
class DatabaseConn:
    conn: Connection

agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    deps_type=DatabaseConn,
    instrument=True
)

@agent.tool(retries=3)  # Allow up to 3 retries
async def get_user_by_name(ctx: RunContext[DatabaseConn], name: str) -> int:
    """Get user ID from name."""
    user = await ctx.deps.conn.fetch_one(
        "SELECT id FROM users WHERE name = $1", name
    )

    if user is None:
        # ModelRetry tells the model to try again with different input
        raise ModelRetry(
            f"No user found with name {name!r}. "
            "Try a different spelling or search by email instead."
        )

    return user["id"]

@agent.tool(retries=2)
async def search_products(ctx: RunContext[DatabaseConn], query: str) -> list[dict]:
    """Search products."""
    if len(query) < 3:
        raise ModelRetry("Query too short. Please provide at least 3 characters.")

    results = await ctx.deps.conn.fetch_all(
        "SELECT * FROM products WHERE name ILIKE $1", f"%{query}%"
    )

    if not results:
        raise ModelRetry(
            f"No products found for '{query}'. "
            "Try broader search terms or check for typos."
        )

    return [dict(r) for r in results]
```

### ModelRetry vs Regular Exceptions

```python
@agent.tool(retries=3)
async def fetch_data(ctx: RunContext[Deps], resource_id: str) -> dict:
    """Fetch data with proper error handling."""

    try:
        data = await ctx.deps.api.get(resource_id)
        return data

    except NotFoundError:
        # ModelRetry: Let the model try with different input
        raise ModelRetry(
            f"Resource {resource_id} not found. "
            "Please verify the ID or try a different one."
        )

    except RateLimitError:
        # ModelRetry: Wait and retry with guidance
        raise ModelRetry(
            "Rate limited. Please wait before trying again. "
            "Consider using cached data if available."
        )

    except AuthenticationError:
        # DON'T use ModelRetry - this is a system error
        # Model can't fix auth issues
        raise  # Let it propagate

    except ValidationError as e:
        # ModelRetry: Guide the model to fix input
        raise ModelRetry(
            f"Invalid input format: {e}. "
            "Please check the expected format and try again."
        )
```

## Pattern 2: Error Nodes in Graph

```python
from dataclasses import dataclass, field
from pydantic_graph import BaseNode, End, GraphRunContext
from pydantic import BaseModel

# State with error tracking
@dataclass
class WorkflowState:
    query: str = ""
    result: str = ""
    errors: list[str] = field(default_factory=list)
    retry_count: int = 0
    max_retries: int = 3

# Error output schema
class ProcessResult(BaseModel):
    success: bool
    data: dict | None = None
    error_message: str | None = None

# Main processing node with error handling
@dataclass
class ProcessNode(BaseNode[WorkflowState]):
    async def run(self, ctx: GraphRunContext[WorkflowState]) -> 'SuccessNode | ErrorNode | End[str]':
        try:
            result = await process_agent.run(
                ctx.state.query,
                deps=ctx.state
            )

            if result.output.success:
                ctx.state.result = str(result.output.data)
                return SuccessNode()
            else:
                ctx.state.errors.append(result.output.error_message)
                return ErrorNode()

        except Exception as e:
            ctx.state.errors.append(str(e))
            return ErrorNode()

# Error handling node
@dataclass
class ErrorNode(BaseNode[WorkflowState]):
    async def run(self, ctx: GraphRunContext[WorkflowState]) -> 'RetryNode | FallbackNode | End[str]':
        ctx.state.retry_count += 1

        # Check if we can retry
        if ctx.state.retry_count < ctx.state.max_retries:
            return RetryNode()

        # Max retries exceeded, try fallback
        return FallbackNode()

# Retry node - attempts same operation again
@dataclass
class RetryNode(BaseNode[WorkflowState]):
    async def run(self, ctx: GraphRunContext[WorkflowState]) -> 'ProcessNode':
        # Optional: Add delay before retry
        await asyncio.sleep(2 ** ctx.state.retry_count)  # Exponential backoff
        return ProcessNode()

# Fallback node - alternative approach
@dataclass
class FallbackNode(BaseNode[WorkflowState]):
    async def run(self, ctx: GraphRunContext[WorkflowState]) -> 'SuccessNode | End[str]':
        # Try simpler/cached/alternative approach
        result = await fallback_agent.run(ctx.state.query)

        if result.output.success:
            ctx.state.result = result.output.data
            return SuccessNode()

        # Graceful end with error information
        return End(f"Failed after {ctx.state.retry_count} retries. Errors: {ctx.state.errors}")

# Success node
@dataclass
class SuccessNode(BaseNode[WorkflowState]):
    async def run(self, ctx: GraphRunContext[WorkflowState]) -> End[str]:
        return End(ctx.state.result)
```

### Graph Visualization

```
                    ┌──────────────┐
                    │  ProcessNode │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
        ┌─────────┐  ┌──────────┐  ┌─────────┐
        │ Success │  │ ErrorNode│  │ End     │
        │  Node   │  └────┬─────┘  │ (crash) │
        └────┬────┘       │        └─────────┘
             │       ┌────┴────┐
             │       │         │
             ▼       ▼         ▼
        ┌─────────┐ ┌─────────┐ ┌──────────┐
        │  End    │ │RetryNode│ │Fallback  │
        │(success)│ └────┬────┘ │  Node    │
        └─────────┘      │      └────┬─────┘
                         │           │
                         ▼           ▼
                   ProcessNode   End/Success
```

## Pattern 3: Multi-Model Fallback in Graph

```python
from dataclasses import dataclass

# Agents with different models
primary_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=TaskResult,
    instrument=True
)

fallback_agent = Agent(
    'openai:gpt-4o-mini',  # Cheaper/faster fallback
    output_type=TaskResult,
    instrument=True
)

simple_agent = Agent(
    'anthropic:claude-haiku',  # Simplest/fastest
    output_type=TaskResult,
    instrument=True
)

@dataclass
class MultiFallbackState:
    query: str = ""
    result: str = ""
    model_used: str = ""
    attempts: list[str] = field(default_factory=list)

@dataclass
class PrimaryModelNode(BaseNode[MultiFallbackState]):
    async def run(self, ctx: GraphRunContext[MultiFallbackState]) -> 'SuccessNode | Fallback1Node':
        try:
            result = await primary_agent.run(ctx.state.query)
            ctx.state.result = result.output.data
            ctx.state.model_used = "claude-sonnet"
            return SuccessNode()
        except Exception as e:
            ctx.state.attempts.append(f"claude-sonnet: {e}")
            return Fallback1Node()

@dataclass
class Fallback1Node(BaseNode[MultiFallbackState]):
    async def run(self, ctx: GraphRunContext[MultiFallbackState]) -> 'SuccessNode | Fallback2Node':
        try:
            result = await fallback_agent.run(ctx.state.query)
            ctx.state.result = result.output.data
            ctx.state.model_used = "gpt-4o-mini"
            return SuccessNode()
        except Exception as e:
            ctx.state.attempts.append(f"gpt-4o-mini: {e}")
            return Fallback2Node()

@dataclass
class Fallback2Node(BaseNode[MultiFallbackState]):
    async def run(self, ctx: GraphRunContext[MultiFallbackState]) -> 'SuccessNode | End[str]':
        try:
            result = await simple_agent.run(ctx.state.query)
            ctx.state.result = result.output.data
            ctx.state.model_used = "claude-haiku"
            return SuccessNode()
        except Exception as e:
            ctx.state.attempts.append(f"claude-haiku: {e}")
            return End(f"All models failed: {ctx.state.attempts}")
```

## Pattern 4: Retry with State Persistence

```python
from pydantic_graph import Graph
from pydantic_graph.persistence import FileStatePersistence

# State tracks retry progress
@dataclass
class PersistentRetryState:
    task_id: str = ""
    current_step: str = ""
    completed_steps: list[str] = field(default_factory=list)
    failed_steps: dict[str, int] = field(default_factory=dict)  # step -> retry count
    max_step_retries: int = 3

@dataclass
class StepNode(BaseNode[PersistentRetryState]):
    step_name: str

    async def run(self, ctx: GraphRunContext[PersistentRetryState]) -> 'StepNode | NextStepNode | End[str]':
        ctx.state.current_step = self.step_name

        try:
            result = await step_agent.run(
                f"Execute step: {self.step_name}",
                deps=ctx.state
            )

            if result.output.success:
                ctx.state.completed_steps.append(self.step_name)
                return NextStepNode()
            else:
                # Track failure
                ctx.state.failed_steps[self.step_name] = \
                    ctx.state.failed_steps.get(self.step_name, 0) + 1

                if ctx.state.failed_steps[self.step_name] < ctx.state.max_step_retries:
                    return StepNode(step_name=self.step_name)  # Retry same step

                return End(f"Step {self.step_name} failed after max retries")

        except Exception as e:
            ctx.state.failed_steps[self.step_name] = \
                ctx.state.failed_steps.get(self.step_name, 0) + 1
            return StepNode(step_name=self.step_name)

# Run with persistence - can resume after crash
async def run_with_persistence():
    graph = Graph(nodes=[StepNode, NextStepNode])

    persistence = FileStatePersistence(f"./checkpoints/task_{task_id}.json")
    state = PersistentRetryState(task_id=task_id)

    result = await graph.run(
        StepNode(step_name="step1"),
        state=state,
        persistence=persistence  # Auto-saves after each node
    )

    return result
```

## Pattern 5: Graceful Degradation Nodes

```python
@dataclass
class GracefulState:
    query: str = ""
    full_result: str | None = None
    partial_result: str | None = None
    degradation_level: int = 0  # 0=full, 1=partial, 2=minimal

class FullResponseOutput(BaseModel):
    detailed_analysis: str
    recommendations: list[str]
    confidence: float

class PartialResponseOutput(BaseModel):
    summary: str
    confidence: float

class MinimalResponseOutput(BaseModel):
    answer: str

# Full capability agent
full_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=FullResponseOutput
)

# Degraded capability agent
partial_agent = Agent(
    'anthropic:claude-haiku',
    output_type=PartialResponseOutput
)

@dataclass
class FullProcessNode(BaseNode[GracefulState]):
    async def run(self, ctx: GraphRunContext[GracefulState]) -> 'DeliverNode | PartialProcessNode':
        try:
            result = await asyncio.wait_for(
                full_agent.run(ctx.state.query),
                timeout=30.0
            )
            ctx.state.full_result = result.output.detailed_analysis
            ctx.state.degradation_level = 0
            return DeliverNode()
        except (asyncio.TimeoutError, Exception):
            return PartialProcessNode()

@dataclass
class PartialProcessNode(BaseNode[GracefulState]):
    async def run(self, ctx: GraphRunContext[GracefulState]) -> 'DeliverNode | MinimalResponseNode':
        try:
            result = await asyncio.wait_for(
                partial_agent.run(ctx.state.query),
                timeout=15.0
            )
            ctx.state.partial_result = result.output.summary
            ctx.state.degradation_level = 1
            return DeliverNode()
        except (asyncio.TimeoutError, Exception):
            return MinimalResponseNode()

@dataclass
class MinimalResponseNode(BaseNode[GracefulState]):
    async def run(self, ctx: GraphRunContext[GracefulState]) -> 'DeliverNode':
        # Always succeeds with canned response
        ctx.state.partial_result = "I'm currently experiencing high load. Please try again later."
        ctx.state.degradation_level = 2
        return DeliverNode()

@dataclass
class DeliverNode(BaseNode[GracefulState]):
    async def run(self, ctx: GraphRunContext[GracefulState]) -> End[str]:
        if ctx.state.degradation_level == 0:
            return End(ctx.state.full_result)
        return End(f"[Degraded Response] {ctx.state.partial_result}")
```

## Testing Graph Resilience

```python
import pytest
from unittest.mock import patch, AsyncMock

class TestGraphResilience:
    """Test resilience patterns in graph."""

    @pytest.mark.asyncio
    async def test_model_retry_triggers_on_not_found(self):
        """ModelRetry guides model to different input."""
        with pytest.raises(ModelRetry) as exc_info:
            await get_user_by_name(mock_ctx, "nonexistent_user")

        assert "No user found" in str(exc_info.value)
        assert "Try a different" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_error_node_triggers_retry(self):
        """ErrorNode transitions to RetryNode when under max."""
        state = WorkflowState(retry_count=0, max_retries=3)
        state.errors.append("Test error")

        error_node = ErrorNode()
        result = await error_node.run(MockContext(state))

        assert isinstance(result, RetryNode)

    @pytest.mark.asyncio
    async def test_error_node_triggers_fallback_after_max(self):
        """ErrorNode transitions to FallbackNode after max retries."""
        state = WorkflowState(retry_count=3, max_retries=3)

        error_node = ErrorNode()
        result = await error_node.run(MockContext(state))

        assert isinstance(result, FallbackNode)

    @pytest.mark.asyncio
    async def test_fallback_chain_tries_all_models(self):
        """Fallback chain tries all models before failing."""
        state = MultiFallbackState(query="test")

        # Mock all agents to fail
        with patch.object(primary_agent, 'run', side_effect=Exception("fail")):
            with patch.object(fallback_agent, 'run', side_effect=Exception("fail")):
                with patch.object(simple_agent, 'run', side_effect=Exception("fail")):
                    graph = Graph(nodes=[PrimaryModelNode, Fallback1Node, Fallback2Node, SuccessNode])
                    result = await graph.run(PrimaryModelNode(), state=state)

        assert "All models failed" in result
        assert len(state.attempts) == 3
```

## Output Format

```
⚡ SKILL_ACTIVATED: #RSLN-9G3L

## Graph Resilience: [Workflow Name]

### ModelRetry Configuration
```python
@agent.tool(retries=3)
async def tool_name(ctx, param):
    # Raises ModelRetry on recoverable errors
```

### Error Node Flow
```
[MainNode] → [ErrorNode] → [RetryNode] → [MainNode]
                       └→ [FallbackNode] → [End]
```

### State Error Tracking
```python
@dataclass
class State:
    errors: list[str]
    retry_count: int
    max_retries: int = 3
```

### Fallback Chain
1. Primary: claude-sonnet (30s timeout)
2. Fallback 1: gpt-4o-mini (15s timeout)
3. Fallback 2: claude-haiku (10s timeout)
4. Graceful: Canned response

### Files
- `agents/[name]/nodes/error_node.py`
- `agents/[name]/nodes/retry_node.py`
- `agents/[name]/nodes/fallback_node.py`
```

## Common Mistakes

- Using regular exceptions instead of ModelRetry in tools
- Not tracking errors in state (lose context)
- Infinite retry loops (no max_retries)
- No fallback path in graph (single point of failure)
- Not persisting state (lose progress on crash)
- Same timeout for all models (fallback too slow)
- Not testing error paths
