---
name: agent-observability
description: Use when implementing tracing, monitoring, evaluation for agents. Activates for "observability", "tracing", "monitoring", "logs", "metrics", "eval".
---

# Agent Observability

Expert in implementing the 5 pillars of AI agent observability.

## When to Use

- Adding tracing to agents
- Implementing monitoring/metrics
- Setting up evaluation pipelines
- User says: observability, tracing, logs, metrics, eval
- NOT when: building agent logic (use graph-agent)

## The 5 Pillars

```
┌─────────────────────────────────────────────────────────────────┐
│               5 PILLARS OF AI OBSERVABILITY                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. TRACES      → Every step, tool call, decision              │
│   2. EVALUATIONS → Quality, accuracy, adherence                 │
│   3. HUMAN REVIEW → Edge cases, high-stakes decisions           │
│   4. ALERTS      → User-impacting failures                      │
│   5. DATA ENGINE → Feedback loop for improvement                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Pillar 1: Tracing

### Basic Tracing Setup

```python
import logfire
from pydantic_ai import Agent

# Initialize tracing
logfire.configure(service_name="my-agent")

agent = Agent(
    "openai:gpt-4",
    auto_instrument=True,  # Automatic tracing
)

# Manual spans for custom logic
with logfire.span("process_user_input") as span:
    span.set_attribute("user_id", user_id)
    span.set_attribute("input_length", len(user_input))
    result = await process(user_input)
    span.set_attribute("result_status", result.status)
```

### Structured Trace Data

```python
from dataclasses import dataclass
from datetime import datetime
from typing import Any

@dataclass
class AgentTrace:
    """Structured trace for agent execution."""
    trace_id: str
    run_id: str
    timestamp: datetime
    event_type: str  # node_start, node_end, tool_call, llm_request
    node_name: str | None
    input_data: dict[str, Any]
    output_data: dict[str, Any] | None
    duration_ms: int | None
    error: str | None
    metadata: dict[str, Any]

async def log_trace(trace: AgentTrace):
    """Log trace to observability backend."""
    logfire.info(
        f"agent.{trace.event_type}",
        trace_id=trace.trace_id,
        run_id=trace.run_id,
        node=trace.node_name,
        duration_ms=trace.duration_ms,
        **trace.metadata
    )
```

### Tracing Decorator

```python
from functools import wraps
import time

def trace_node(func):
    """Decorator to trace node execution."""
    @wraps(func)
    async def wrapper(self, state, *args, **kwargs):
        trace_id = state.run_id
        node_name = self.__class__.__name__
        start = time.perf_counter()

        with logfire.span(f"node.{node_name}") as span:
            span.set_attribute("trace_id", trace_id)
            span.set_attribute("step", state.step)

            try:
                result = await func(self, state, *args, **kwargs)
                span.set_attribute("status", "success")
                return result

            except Exception as e:
                span.set_attribute("status", "error")
                span.set_attribute("error", str(e))
                raise

            finally:
                duration = (time.perf_counter() - start) * 1000
                span.set_attribute("duration_ms", duration)

    return wrapper
```

## Pillar 2: Evaluations

### Online Evaluation

```python
from pydantic import BaseModel

class EvalResult(BaseModel):
    """Evaluation result for a single response."""
    run_id: str
    eval_type: str
    score: float  # 0-1
    passed: bool
    details: dict

async def evaluate_response(
    query: str,
    response: str,
    expected: str | None = None
) -> list[EvalResult]:
    """Run multiple evaluations on a response."""
    results = []

    # Factuality check
    factuality = await eval_factuality(response)
    results.append(EvalResult(
        eval_type="factuality",
        score=factuality.score,
        passed=factuality.score > 0.8,
        details={"claims_verified": factuality.claims}
    ))

    # Relevance check
    relevance = await eval_relevance(query, response)
    results.append(EvalResult(
        eval_type="relevance",
        score=relevance.score,
        passed=relevance.score > 0.7,
        details={"query_coverage": relevance.coverage}
    ))

    # Safety check
    safety = await eval_safety(response)
    results.append(EvalResult(
        eval_type="safety",
        score=safety.score,
        passed=safety.score > 0.95,
        details={"flags": safety.flags}
    ))

    return results
```

### LLM-as-Judge

```python
JUDGE_PROMPT = """
Evaluate the following response for quality.

Query: {query}
Response: {response}

Rate on a scale of 1-5 for:
1. Accuracy: Is the information correct?
2. Completeness: Does it fully answer the query?
3. Clarity: Is it easy to understand?
4. Relevance: Does it stay on topic?

Output JSON:
{{"accuracy": X, "completeness": X, "clarity": X, "relevance": X, "overall": X}}
"""

async def llm_judge(query: str, response: str) -> dict:
    """Use LLM to evaluate response quality."""
    judge = Agent("openai:gpt-4o", output_type=JudgeOutput)
    result = await judge.run(
        JUDGE_PROMPT.format(query=query, response=response)
    )
    return result.data.model_dump()
```

## Pillar 3: Human Review

```python
from enum import Enum

class ReviewStatus(Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    MODIFIED = "modified"

@dataclass
class HumanReviewRequest:
    """Request for human review."""
    id: str
    run_id: str
    reason: str  # why review needed
    agent_response: str
    confidence: float
    auto_approve_threshold: float
    status: ReviewStatus = ReviewStatus.PENDING
    reviewer_notes: str | None = None

async def request_human_review(
    run_id: str,
    response: str,
    reason: str,
    confidence: float
) -> HumanReviewRequest:
    """Create human review request."""
    review = HumanReviewRequest(
        id=str(uuid.uuid4()),
        run_id=run_id,
        reason=reason,
        agent_response=response,
        confidence=confidence,
        auto_approve_threshold=0.9
    )

    # Store for review queue
    await db.table("human_reviews").insert(review.__dict__).execute()

    # Notify reviewers
    await notify_slack(f"New review request: {reason}")

    return review
```

## Pillar 4: Alerts

```python
from dataclasses import dataclass
from typing import Callable

@dataclass
class AlertRule:
    """Rule for triggering alerts."""
    name: str
    condition: Callable[[dict], bool]
    severity: str  # critical, warning, info
    channels: list[str]  # slack, email, pagerduty

ALERT_RULES = [
    AlertRule(
        name="high_error_rate",
        condition=lambda m: m["error_rate_5m"] > 0.1,
        severity="critical",
        channels=["pagerduty", "slack"]
    ),
    AlertRule(
        name="low_confidence_spike",
        condition=lambda m: m["low_confidence_rate_1h"] > 0.3,
        severity="warning",
        channels=["slack"]
    ),
    AlertRule(
        name="latency_degradation",
        condition=lambda m: m["p95_latency_ms"] > 5000,
        severity="warning",
        channels=["slack"]
    ),
]

async def check_alerts(metrics: dict):
    """Check all alert rules against current metrics."""
    for rule in ALERT_RULES:
        if rule.condition(metrics):
            await send_alert(
                title=f"[{rule.severity.upper()}] {rule.name}",
                message=f"Alert triggered. Metrics: {metrics}",
                channels=rule.channels
            )
```

## Pillar 5: Data Engine

```python
class DataEngine:
    """Feedback loop for continuous improvement."""

    async def collect_feedback(self, run_id: str, feedback: dict):
        """Collect user feedback on agent response."""
        await db.table("agent_feedback").insert({
            "run_id": run_id,
            "rating": feedback.get("rating"),
            "comment": feedback.get("comment"),
            "corrections": feedback.get("corrections"),
            "created_at": datetime.utcnow()
        }).execute()

    async def identify_failure_patterns(self) -> list[dict]:
        """Analyze failures to find patterns."""
        result = await db.rpc(
            "analyze_agent_failures",
            {"time_window": "7 days"}
        ).execute()
        return result.data

    async def generate_training_data(self) -> list[dict]:
        """Generate training data from feedback."""
        # Get corrected responses
        corrections = await db.table("agent_feedback") \
            .select("run_id, corrections") \
            .not_.is_("corrections", "null") \
            .execute()

        return [
            {
                "input": await self.get_input(c["run_id"]),
                "output": c["corrections"],
                "source": "human_correction"
            }
            for c in corrections.data
        ]
```

## Metrics Dashboard

```python
# Key metrics to track
AGENT_METRICS = {
    # Success metrics
    "task_completion_rate": "% of tasks completed successfully",
    "user_satisfaction": "Average rating (1-5)",
    "first_contact_resolution": "% resolved without escalation",

    # Quality metrics
    "factuality_score": "Average factuality eval score",
    "relevance_score": "Average relevance eval score",
    "safety_violations": "Count of safety flag triggers",

    # Performance metrics
    "avg_latency_ms": "Average response time",
    "p95_latency_ms": "95th percentile latency",
    "tokens_per_response": "Average tokens used",
    "cost_per_response": "Average cost in $",

    # Reliability metrics
    "error_rate": "% of failed runs",
    "retry_rate": "% of runs requiring retry",
    "fallback_rate": "% of runs using fallback model",
}
```

## Output Format

```
⚡ SKILL_ACTIVATED: #OBSV-5F1K

## Observability Setup: [Agent Name]

### Tracing
- Provider: [Logfire/Langfuse/Arize]
- Auto-instrumentation: Enabled
- Custom spans: [list]

### Evaluations
- Online: [factuality, relevance, safety]
- Offline: [weekly regression tests]
- LLM-as-Judge: Configured

### Alerts
| Alert | Severity | Channels |
|-------|----------|----------|
| [alert] | [level] | [channels] |

### Dashboard
- URL: [link]
- Key metrics tracked

### Files
- `agents/[name]/observability.py`
- `agents/[name]/evals.py`
```

## Common Mistakes

- No tracing (can't debug production issues)
- Tracing too verbose (cost explosion)
- No offline evaluation (quality regression)
- Alerts too sensitive (alert fatigue)
- No feedback collection (can't improve)
- Ignoring low-confidence responses
