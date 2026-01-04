---
name: agent-observability
description: Use when implementing tracing, monitoring, evaluation for graph-based agents. Activates for "observability", "monitoring", "logs", "metrics", "eval", "instrument".
---

# Agent Observability (Graph-Specialized)

Expert in implementing observability for **Pydantic AI agents and graphs** using native instrumentation, Logfire, and the 5 pillars of AI observability.

## When to Use

- Adding tracing to agents and graphs
- Implementing monitoring/metrics
- Setting up evaluation pipelines
- User says: observability, tracing, logs, metrics, eval, instrument
- NOT when: specific Langfuse implementation (use agent-tracing-langfuse)

## The 5 Pillars

```
┌─────────────────────────────────────────────────────────────────┐
│               5 PILLARS OF AI OBSERVABILITY                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. TRACES      → Agent calls, tool use, node transitions      │
│   2. EVALUATIONS → Quality, accuracy, adherence                 │
│   3. HUMAN REVIEW → Edge cases, high-stakes decisions           │
│   4. ALERTS      → User-impacting failures                      │
│   5. DATA ENGINE → Feedback loop for improvement                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Pydantic AI Native Instrumentation

### Method 1: Per-Agent Instrumentation

```python
from pydantic_ai import Agent

# Single agent with instrumentation
research_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=ResearchOutput,
    instrument=True  # Enable tracing for this agent
)

# All calls to this agent are automatically traced
result = await research_agent.run("Research topic X")
# Traces: LLM request, response, tokens, latency
```

### Method 2: Global Instrumentation

```python
from pydantic_ai import Agent

# Instrument ALL agents at once
Agent.instrument_all()

# Now every Agent instance is traced automatically
agent1 = Agent('anthropic:claude-sonnet-4-20250514', output_type=Output1)
agent2 = Agent('openai:gpt-4o', output_type=Output2)

# Both are traced without explicit instrument=True
await agent1.run("query 1")  # Traced
await agent2.run("query 2")  # Traced
```

### Method 3: Logfire Integration

```python
import logfire
from pydantic_ai import Agent

# Configure Logfire
logfire.configure(service_name="my-agent-service")

# Instrument Pydantic AI
logfire.instrument_pydantic_ai()

# All agents now report to Logfire
agent = Agent('anthropic:claude-sonnet-4-20250514', output_type=Output)
result = await agent.run("query")  # Visible in Logfire dashboard
```

## Graph-Level Observability

### Tracing Node Transitions

```python
from dataclasses import dataclass, field
from pydantic_graph import BaseNode, End, Graph, GraphRunContext
from pydantic_ai import Agent
import logfire

# Global instrumentation
Agent.instrument_all()
logfire.configure()
logfire.instrument_pydantic_ai()

@dataclass
class WorkflowState:
    query: str = ""
    node_history: list[str] = field(default_factory=list)
    agent_calls: int = 0

@dataclass
class ResearchNode(BaseNode[WorkflowState]):
    async def run(self, ctx: GraphRunContext[WorkflowState]) -> 'SynthesisNode | End[str]':
        # Track node entry
        ctx.state.node_history.append("ResearchNode")

        with logfire.span("node.ResearchNode") as span:
            span.set_attribute("query", ctx.state.query)
            span.set_attribute("node_count", len(ctx.state.node_history))

            # Agent call is automatically traced
            result = await research_agent.run(ctx.state.query)
            ctx.state.agent_calls += 1

            span.set_attribute("findings_count", len(result.output.findings))

            if result.output.needs_more:
                return ResearchNode()
            return SynthesisNode()
```

### Graph Execution Tracing

```python
from pydantic_graph import Graph

async def run_traced_graph(query: str) -> str:
    """Run graph with full tracing."""

    with logfire.span("graph.workflow") as span:
        span.set_attribute("query", query)

        state = WorkflowState(query=query)
        graph = Graph(nodes=[ResearchNode, SynthesisNode])

        try:
            result = await graph.run(ResearchNode(), state=state)

            span.set_attribute("status", "success")
            span.set_attribute("nodes_visited", state.node_history)
            span.set_attribute("agent_calls", state.agent_calls)

            return result

        except Exception as e:
            span.set_attribute("status", "error")
            span.set_attribute("error", str(e))
            raise
```

## Pillar 1: Comprehensive Tracing

### Trace Structure for Graphs

```python
from dataclasses import dataclass
from datetime import datetime
from typing import Any

@dataclass
class GraphTrace:
    """Complete trace for graph execution."""
    trace_id: str
    run_id: str
    graph_name: str
    start_time: datetime
    end_time: datetime | None
    status: str  # running, completed, failed

    # Node tracking
    nodes_visited: list[str]
    current_node: str | None

    # Agent tracking
    agent_calls: list[AgentCallTrace]
    total_tokens: int
    total_cost: float

    # State tracking
    initial_state: dict
    final_state: dict | None

@dataclass
class AgentCallTrace:
    """Trace for individual agent call."""
    agent_name: str
    node_name: str
    model: str
    prompt_tokens: int
    completion_tokens: int
    latency_ms: int
    cost: float
    tool_calls: list[str]
```

### Automatic State Logging

```python
@dataclass
class TracedBaseNode(BaseNode[WorkflowState]):
    """Base node with automatic tracing."""

    async def run(self, ctx: GraphRunContext[WorkflowState]) -> BaseNode | End:
        node_name = self.__class__.__name__

        with logfire.span(f"node.{node_name}") as span:
            # Log state before
            span.set_attribute("state_before", str(ctx.state.__dict__))

            # Execute actual node logic
            result = await self._run_impl(ctx)

            # Log state after
            span.set_attribute("state_after", str(ctx.state.__dict__))
            span.set_attribute("next_node", type(result).__name__)

            return result

    async def _run_impl(self, ctx: GraphRunContext[WorkflowState]) -> BaseNode | End:
        """Override this in subclasses."""
        raise NotImplementedError
```

## Pillar 2: Evaluations

### Online Evaluation in Nodes

```python
from pydantic import BaseModel

class EvalResult(BaseModel):
    metric: str
    score: float
    passed: bool
    details: dict

@dataclass
class EvaluatedNode(BaseNode[WorkflowState]):
    async def run(self, ctx: GraphRunContext[WorkflowState]) -> 'NextNode | End[str]':
        # Get agent response
        result = await agent.run(ctx.state.query)

        # Run inline evaluations
        evals = await self.evaluate_response(
            query=ctx.state.query,
            response=result.output.response
        )

        # Log evaluations
        with logfire.span("evaluation") as span:
            for eval_result in evals:
                span.set_attribute(f"eval.{eval_result.metric}", eval_result.score)
                logfire.info(
                    f"eval.{eval_result.metric}",
                    score=eval_result.score,
                    passed=eval_result.passed
                )

        # Route based on evaluation
        if all(e.passed for e in evals):
            return NextNode()
        else:
            ctx.state.eval_failures = [e for e in evals if not e.passed]
            return ReviewNode()

    async def evaluate_response(self, query: str, response: str) -> list[EvalResult]:
        """Run multiple evaluations."""
        return [
            await self.eval_relevance(query, response),
            await self.eval_safety(response),
            await self.eval_factuality(response)
        ]
```

### LLM-as-Judge with Pydantic AI

```python
class JudgeOutput(BaseModel):
    accuracy: int  # 1-5
    completeness: int  # 1-5
    clarity: int  # 1-5
    relevance: int  # 1-5
    overall: float
    reasoning: str

judge_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=JudgeOutput,
    system_prompt="""
    You are a quality judge for AI responses.
    Rate each dimension 1-5.
    Overall = average of all scores / 5.
    """,
    instrument=True
)

async def llm_judge(query: str, response: str) -> JudgeOutput:
    """Use LLM to evaluate response quality."""
    result = await judge_agent.run(
        f"Query: {query}\n\nResponse: {response}\n\nEvaluate this response."
    )
    return result.output
```

## Pillar 3: Human Review Nodes

```python
from enum import Enum

class ReviewStatus(Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"

@dataclass
class ReviewState:
    # ... other fields
    pending_review: bool = False
    review_id: str | None = None
    review_status: ReviewStatus | None = None

@dataclass
class HumanReviewNode(BaseNode[ReviewState]):
    """Node that requests human review."""

    async def run(self, ctx: GraphRunContext[ReviewState]) -> 'ApprovedNode | RejectedNode | End[str]':
        # Check if already reviewed
        if ctx.state.review_status == ReviewStatus.APPROVED:
            return ApprovedNode()
        elif ctx.state.review_status == ReviewStatus.REJECTED:
            return RejectedNode()

        # Create review request
        review_id = await self.create_review_request(ctx.state)
        ctx.state.review_id = review_id
        ctx.state.pending_review = True

        logfire.info(
            "human_review.requested",
            review_id=review_id,
            reason="low_confidence"
        )

        # Return End to pause graph (resume when reviewed)
        return End(f"Awaiting human review: {review_id}")

    async def create_review_request(self, state: ReviewState) -> str:
        """Create review request in database."""
        # Insert into review queue
        ...
```

## Pillar 4: Alerts

```python
from dataclasses import dataclass
from typing import Callable

@dataclass
class AlertRule:
    name: str
    condition: Callable[[dict], bool]
    severity: str
    channels: list[str]

GRAPH_ALERT_RULES = [
    AlertRule(
        name="high_error_rate",
        condition=lambda m: m.get("graph_error_rate", 0) > 0.1,
        severity="critical",
        channels=["pagerduty", "slack"]
    ),
    AlertRule(
        name="excessive_retries",
        condition=lambda m: m.get("avg_node_retries", 0) > 3,
        severity="warning",
        channels=["slack"]
    ),
    AlertRule(
        name="cost_spike",
        condition=lambda m: m.get("hourly_cost", 0) > 100,
        severity="warning",
        channels=["slack", "email"]
    ),
]

async def check_graph_alerts(metrics: dict):
    """Check alerts for graph execution."""
    for rule in GRAPH_ALERT_RULES:
        if rule.condition(metrics):
            await send_alert(rule, metrics)
            logfire.warning(
                f"alert.{rule.name}",
                severity=rule.severity,
                metrics=metrics
            )
```

## Pillar 5: Data Engine

```python
class GraphDataEngine:
    """Feedback loop for graph improvement."""

    async def collect_graph_feedback(
        self,
        run_id: str,
        rating: int,
        feedback: str | None
    ):
        """Collect feedback on graph execution."""
        logfire.info(
            "feedback.collected",
            run_id=run_id,
            rating=rating
        )

        await db.table("graph_feedback").insert({
            "run_id": run_id,
            "rating": rating,
            "feedback": feedback,
            "created_at": datetime.utcnow()
        }).execute()

    async def analyze_node_performance(self) -> dict:
        """Analyze which nodes are bottlenecks."""
        return await db.rpc("analyze_node_performance").execute()

    async def identify_failure_patterns(self) -> list[dict]:
        """Find patterns in graph failures."""
        return await db.rpc("graph_failure_patterns").execute()
```

## Key Metrics for Graphs

```python
GRAPH_METRICS = {
    # Execution metrics
    "graph_completion_rate": "% of graphs that complete successfully",
    "avg_nodes_per_run": "Average nodes visited per execution",
    "avg_agent_calls": "Average agent calls per execution",

    # Performance metrics
    "avg_graph_latency_ms": "Average total execution time",
    "avg_node_latency_ms": "Average time per node",
    "p95_graph_latency_ms": "95th percentile execution time",

    # Cost metrics
    "total_tokens_per_run": "Total tokens used per execution",
    "cost_per_run": "Average cost per graph execution",

    # Quality metrics
    "avg_eval_score": "Average evaluation score",
    "human_review_rate": "% of runs requiring human review",

    # Reliability metrics
    "retry_rate": "% of nodes that required retry",
    "fallback_rate": "% of runs using fallback paths",
}
```

## Testing Observability

```python
import pytest
from unittest.mock import patch, MagicMock

class TestGraphObservability:
    """Test observability setup."""

    @pytest.mark.asyncio
    async def test_agent_instrumentation_enabled(self):
        """Verify agents are instrumented."""
        agent = Agent(
            'anthropic:claude-sonnet-4-20250514',
            output_type=str,
            instrument=True
        )

        # Agent should have instrumentation flag
        assert agent._instrument is True

    @pytest.mark.asyncio
    async def test_logfire_span_created(self):
        """Verify Logfire spans are created."""
        with patch('logfire.span') as mock_span:
            await run_traced_graph("test query")

            # Should have created spans
            mock_span.assert_called()

    @pytest.mark.asyncio
    async def test_state_changes_logged(self):
        """Verify state changes are captured."""
        state = WorkflowState(query="test")

        # Run graph
        await graph.run(StartNode(), state=state)

        # State should have history
        assert len(state.node_history) > 0
```

## Output Format

```
⚡ SKILL_ACTIVATED: #OBSV-5F1K

## Graph Observability: [Workflow Name]

### Instrumentation
```python
# Global
Agent.instrument_all()
logfire.configure()
logfire.instrument_pydantic_ai()

# Or per-agent
agent = Agent(..., instrument=True)
```

### Traces Captured
- Graph execution (start, end, status)
- Node transitions (from, to, duration)
- Agent calls (tokens, latency, cost)
- State changes (before, after each node)

### Evaluations
- Online: [factuality, relevance, safety]
- LLM-as-Judge: Configured

### Alerts
| Alert | Condition | Channels |
|-------|-----------|----------|
| error_rate | > 10% | pagerduty |
| cost_spike | > $100/hr | slack |

### Dashboard
- Logfire: [project-url]

### Files
- `agents/[name]/observability.py`
- `agents/[name]/evals.py`
```

## Common Mistakes

- Not using `instrument=True` or `Agent.instrument_all()`
- Forgetting `logfire.instrument_pydantic_ai()`
- Not tracing node transitions (only agent calls)
- Missing state change logging
- No cost tracking (surprise bills)
- Alert thresholds too sensitive
- Not testing observability setup
