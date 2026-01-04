---
name: agent-tracing-langfuse
description: Use when implementing observability, tracing, or monitoring for AI agents. Activates for "tracing", "langfuse", "observability", "monitoring agent", "trace spans".
chain: agent-audit-graph
---

# Agent Tracing with Langfuse

Expert in implementing production-grade observability for Pydantic AI agents using Langfuse. Covers traces, spans, sessions, evaluations, and cost tracking.

## When to Use

- Adding observability to agents
- Debugging agent behavior in production
- Tracking costs and latency
- User says: tracing, langfuse, observability, monitoring
- CHAIN: → agent-audit-graph (after tracing implemented)
- NOT when: general logging (use standard logging)

## Langfuse Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    LANGFUSE OBSERVABILITY                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   SESSION    → Groups multi-turn conversations                  │
│      │                                                          │
│      ▼                                                          │
│   TRACE      → Single invocation/request                        │
│      │                                                          │
│      ├── SPAN        → Logical operation (function, step)       │
│      │     │                                                    │
│      │     ├── GENERATION → LLM call with tokens/cost           │
│      │     └── EVENT      → Point-in-time occurrence            │
│      │                                                          │
│      └── SCORE       → Quality metric (human/LLM evaluation)    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Environment Setup

### Required Environment Variables
```python
import os

# Langfuse Configuration
os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
os.environ["LANGFUSE_BASE_URL"] = "https://cloud.langfuse.com"  # or self-hosted

# Optional: Disable in development
os.environ["LANGFUSE_ENABLED"] = "true"  # set "false" to disable
```

### Production Configuration (.env)
```bash
# .env.production
LANGFUSE_PUBLIC_KEY=pk-lf-xxxxxxxxxxxx
LANGFUSE_SECRET_KEY=sk-lf-xxxxxxxxxxxx
LANGFUSE_BASE_URL=https://cloud.langfuse.com

# Optional settings
LANGFUSE_RELEASE=v1.2.3
LANGFUSE_DEBUG=false
LANGFUSE_SAMPLE_RATE=1.0
```

### Configuration Loader Pattern
```python
from pydantic_settings import BaseSettings
from typing import Optional

class LangfuseSettings(BaseSettings):
    """Langfuse configuration with validation."""

    public_key: str
    secret_key: str
    base_url: str = "https://cloud.langfuse.com"
    enabled: bool = True
    release: Optional[str] = None
    sample_rate: float = 1.0

    class Config:
        env_prefix = "LANGFUSE_"
        env_file = ".env"

def configure_langfuse() -> None:
    """Configure Langfuse from environment."""
    settings = LangfuseSettings()

    if not settings.enabled:
        print("⚠️ Langfuse disabled")
        return

    os.environ["LANGFUSE_PUBLIC_KEY"] = settings.public_key
    os.environ["LANGFUSE_SECRET_KEY"] = settings.secret_key
    os.environ["LANGFUSE_BASE_URL"] = settings.base_url

    if settings.release:
        os.environ["LANGFUSE_RELEASE"] = settings.release
```

## Pydantic AI Integration

### Method 1: Global Instrumentation (Recommended)
```python
from pydantic_ai.agent import Agent

# Instrument ALL agents automatically
Agent.instrument_all()

# Now all agents are traced
agent = Agent('openai:gpt-4o')
result = agent.run_sync("Hello!")  # Automatically traced
```

### Method 2: Per-Agent Instrumentation
```python
from pydantic_ai import Agent

# Only this agent is traced
traced_agent = Agent(
    'openai:gpt-4o',
    instrument=True  # Enable tracing for this agent
)

# This agent is NOT traced
untraced_agent = Agent('openai:gpt-4o')
```

### Method 3: Custom Instrumentation with @observe
```python
from langfuse.decorators import observe, langfuse_context

@observe()  # Creates a span
def process_user_request(user_input: str) -> str:
    """Process with full tracing."""

    # Add metadata to current trace
    langfuse_context.update_current_observation(
        metadata={"input_length": len(user_input)}
    )

    result = agent.run_sync(user_input)

    # Add output metadata
    langfuse_context.update_current_observation(
        metadata={"output_length": len(result.data)}
    )

    return result.data

@observe(name="my-pipeline")  # Named span
def my_pipeline(query: str) -> str:
    step1 = preprocess(query)
    step2 = process_user_request(step1)
    return postprocess(step2)
```

## Session & User Tracking

### Propagating Attributes
```python
from langfuse.decorators import observe
from langfuse import propagate_attributes

@observe()
def handle_conversation(
    user_id: str,
    session_id: str,
    message: str
) -> str:
    """Track user and session context."""

    with propagate_attributes(
        user_id=user_id,
        session_id=session_id,
        tags=["production", "v1.2"],
        metadata={
            "environment": "production",
            "feature_flag": "new_model"
        }
    ):
        result = agent.run_sync(message)
        return result.data
```

### Session Management Pattern
```python
from dataclasses import dataclass
from typing import Optional
import uuid

@dataclass
class ConversationContext:
    """Manage conversation context for tracing."""

    user_id: str
    session_id: str
    conversation_id: Optional[str] = None

    @classmethod
    def new_session(cls, user_id: str) -> "ConversationContext":
        return cls(
            user_id=user_id,
            session_id=f"session_{uuid.uuid4().hex[:8]}",
            conversation_id=f"conv_{uuid.uuid4().hex[:8]}"
        )

    def get_trace_attributes(self) -> dict:
        return {
            "user_id": self.user_id,
            "session_id": self.session_id,
            "tags": [f"conv:{self.conversation_id}"]
        }

# Usage
ctx = ConversationContext.new_session("user_123")

with propagate_attributes(**ctx.get_trace_attributes()):
    response = agent.run_sync("Hello!")
```

## Complete Tracing Setup

### Full Implementation Pattern
```python
"""
agent_with_tracing.py
Complete Pydantic AI agent with Langfuse observability.
"""

import os
from typing import Any
from dataclasses import dataclass
from pydantic_ai import Agent, RunContext
from langfuse.decorators import observe, langfuse_context
from langfuse import propagate_attributes

# 1. Configure Langfuse
os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
os.environ["LANGFUSE_BASE_URL"] = "https://cloud.langfuse.com"

# 2. Enable global instrumentation
Agent.instrument_all()

# 3. Define dependencies with trace context
@dataclass
class TracedDeps:
    user_id: str
    session_id: str
    trace_metadata: dict

# 4. Create agent
agent = Agent(
    'openai:gpt-4o',
    deps_type=TracedDeps,
    system_prompt="You are a helpful assistant."
)

# 5. Add traced tools
@agent.tool
@observe(name="search_database")
async def search_database(
    ctx: RunContext[TracedDeps],
    query: str
) -> str:
    """Search with tracing."""

    langfuse_context.update_current_observation(
        input={"query": query},
        metadata={"user_id": ctx.deps.user_id}
    )

    # Simulate search
    results = f"Results for: {query}"

    langfuse_context.update_current_observation(
        output={"results": results}
    )

    return results

# 6. Main execution with full context
@observe(name="agent_execution")
async def run_agent(
    user_id: str,
    session_id: str,
    message: str
) -> str:
    """Execute agent with full tracing."""

    deps = TracedDeps(
        user_id=user_id,
        session_id=session_id,
        trace_metadata={"source": "api"}
    )

    with propagate_attributes(
        user_id=user_id,
        session_id=session_id,
        tags=["agent", "production"]
    ):
        result = await agent.run(message, deps=deps)

        # Add final metadata
        langfuse_context.update_current_trace(
            metadata={
                "total_tokens": getattr(result, 'usage', {}).get('total_tokens'),
                "model": "gpt-4o"
            }
        )

        return result.data
```

## Graph Agent Tracing

### Tracing Multi-Step Graphs
```python
from pydantic_ai import Agent
from pydantic_graph import Graph, Node, End
from langfuse.decorators import observe
from langfuse import propagate_attributes

Agent.instrument_all()

# Each node gets its own span
@observe(name="analyze_node")
async def run_analyze_node(state: dict) -> dict:
    """Analyze step with dedicated span."""
    result = await analyze_agent.run(state["input"])
    return {"analysis": result.data}

@observe(name="generate_node")
async def run_generate_node(state: dict) -> dict:
    """Generate step with dedicated span."""
    result = await generate_agent.run(state["analysis"])
    return {"output": result.data}

# Graph execution traced end-to-end
@observe(name="full_graph_execution")
async def execute_graph(
    user_input: str,
    user_id: str,
    session_id: str
) -> str:
    """Execute graph with hierarchical tracing."""

    with propagate_attributes(
        user_id=user_id,
        session_id=session_id,
        tags=["graph", "multi-step"]
    ):
        state = {"input": user_input}

        # Each node creates nested spans
        state = await run_analyze_node(state)
        state = await run_generate_node(state)

        return state["output"]
```

### Trace Hierarchy Visualization
```
TRACE: full_graph_execution
├── SPAN: analyze_node
│   └── GENERATION: openai:gpt-4o (analyze_agent)
│       ├── input_tokens: 150
│       ├── output_tokens: 200
│       └── cost: $0.003
├── SPAN: generate_node
│   └── GENERATION: openai:gpt-4o (generate_agent)
│       ├── input_tokens: 300
│       ├── output_tokens: 500
│       └── cost: $0.008
└── METADATA:
    ├── user_id: user_123
    ├── session_id: session_abc
    └── total_cost: $0.011
```

## Evaluations & Scoring

### LLM-as-Judge Evaluation
```python
from langfuse import Langfuse
from langfuse.decorators import observe, langfuse_context

langfuse = Langfuse()

@observe()
async def run_with_evaluation(query: str) -> str:
    """Run agent and evaluate quality."""

    result = await agent.run(query)

    # Get current trace ID for scoring
    trace_id = langfuse_context.get_current_trace_id()

    # Add LLM-as-Judge evaluation
    langfuse.score(
        trace_id=trace_id,
        name="relevance",
        value=await evaluate_relevance(query, result.data),
        comment="LLM-evaluated relevance score"
    )

    langfuse.score(
        trace_id=trace_id,
        name="helpfulness",
        value=await evaluate_helpfulness(result.data),
        data_type="NUMERIC",  # NUMERIC, BOOLEAN, CATEGORICAL
    )

    return result.data

async def evaluate_relevance(query: str, response: str) -> float:
    """Use LLM to evaluate relevance 0-1."""
    eval_prompt = f"""
    Query: {query}
    Response: {response}

    Rate relevance 0-1. Return only the number.
    """
    eval_result = await eval_agent.run(eval_prompt)
    return float(eval_result.data)
```

### User Feedback Integration
```python
def record_user_feedback(
    trace_id: str,
    feedback: str,  # "positive" or "negative"
    comment: Optional[str] = None
) -> None:
    """Record user feedback as score."""

    langfuse.score(
        trace_id=trace_id,
        name="user_feedback",
        value=1 if feedback == "positive" else 0,
        data_type="BOOLEAN",
        comment=comment
    )

def record_rating(
    trace_id: str,
    rating: int,  # 1-5
    aspect: str = "overall"
) -> None:
    """Record numeric rating."""

    langfuse.score(
        trace_id=trace_id,
        name=f"rating_{aspect}",
        value=rating / 5.0,  # Normalize to 0-1
        data_type="NUMERIC"
    )
```

## Cost & Performance Tracking

### Automatic Cost Tracking
```python
# Langfuse automatically tracks costs for supported models
# Just use instrumented agents

Agent.instrument_all()

agent = Agent('openai:gpt-4o')  # Costs auto-tracked
result = agent.run_sync("Hello!")

# View in Langfuse dashboard:
# - Input tokens
# - Output tokens
# - Total cost per trace
# - Cost aggregations by user/session
```

### Custom Cost Tracking
```python
from langfuse.decorators import observe, langfuse_context

# Token pricing (example)
PRICING = {
    "gpt-4o": {"input": 0.005, "output": 0.015},
    "gpt-4o-mini": {"input": 0.00015, "output": 0.0006},
    "claude-3-opus": {"input": 0.015, "output": 0.075},
}

@observe()
async def tracked_call(model: str, prompt: str) -> str:
    """Call with explicit cost tracking."""

    result = await agent.run(prompt)

    # Calculate cost
    usage = result.usage()
    input_cost = (usage.request_tokens / 1000) * PRICING[model]["input"]
    output_cost = (usage.response_tokens / 1000) * PRICING[model]["output"]
    total_cost = input_cost + output_cost

    # Update observation with cost
    langfuse_context.update_current_observation(
        usage={
            "input": usage.request_tokens,
            "output": usage.response_tokens,
            "total": usage.total_tokens,
            "unit": "TOKENS"
        },
        metadata={
            "cost_input": input_cost,
            "cost_output": output_cost,
            "cost_total": total_cost,
            "model": model
        }
    )

    return result.data
```

### Performance Monitoring
```python
import time
from langfuse.decorators import observe, langfuse_context

@observe()
async def monitored_pipeline(input: str) -> str:
    """Pipeline with performance metrics."""

    start = time.time()

    # Step 1
    step1_start = time.time()
    result1 = await step1(input)
    step1_duration = time.time() - step1_start

    # Step 2
    step2_start = time.time()
    result2 = await step2(result1)
    step2_duration = time.time() - step2_start

    total_duration = time.time() - start

    # Record performance metrics
    langfuse_context.update_current_trace(
        metadata={
            "duration_total_ms": total_duration * 1000,
            "duration_step1_ms": step1_duration * 1000,
            "duration_step2_ms": step2_duration * 1000,
            "p50_target_ms": 1000,
            "p99_target_ms": 5000
        }
    )

    return result2
```

## Production Patterns

### Sampling for High-Volume
```python
import random
from langfuse.decorators import observe

SAMPLE_RATE = 0.1  # Trace 10% of requests

def should_trace() -> bool:
    return random.random() < SAMPLE_RATE

@observe(enabled=should_trace)
async def high_volume_endpoint(request: str) -> str:
    """Only traces 10% of requests."""
    return await agent.run(request)
```

### Error Tracking
```python
from langfuse.decorators import observe, langfuse_context

@observe()
async def safe_agent_call(prompt: str) -> str:
    """Agent call with error tracking."""

    try:
        result = await agent.run(prompt)

        langfuse_context.update_current_observation(
            level="DEFAULT",
            status_message="Success"
        )

        return result.data

    except Exception as e:
        # Log error to Langfuse
        langfuse_context.update_current_observation(
            level="ERROR",
            status_message=str(e),
            metadata={
                "error_type": type(e).__name__,
                "error_message": str(e)
            }
        )
        raise
```

### Async Flush for Serverless
```python
from langfuse import Langfuse

langfuse = Langfuse()

async def serverless_handler(event: dict) -> dict:
    """Lambda/Cloud Function handler."""

    try:
        result = await run_agent(event["input"])
        return {"statusCode": 200, "body": result}
    finally:
        # CRITICAL: Flush before function ends
        langfuse.flush()
```

## Checklist

### Setup Checklist
- [ ] Environment variables configured
- [ ] `Agent.instrument_all()` called at startup
- [ ] User ID tracking implemented
- [ ] Session ID for conversations
- [ ] Error handling with Langfuse logging

### Production Checklist
- [ ] Sampling configured for high volume
- [ ] Async flush for serverless
- [ ] Cost tracking verified
- [ ] Evaluations pipeline setup
- [ ] Alerts configured in dashboard
- [ ] Data retention policy set

### Debug Checklist
- [ ] `LANGFUSE_DEBUG=true` for verbose logs
- [ ] Check trace appears in dashboard
- [ ] Verify spans are nested correctly
- [ ] Confirm costs are calculated
- [ ] Test evaluation scores

## Output Format

```
⚡ SKILL_ACTIVATED: #TRAC-7K4M

## Tracing Implementation: [Component]

### Configuration
| Setting | Value |
|---------|-------|
| Base URL | [URL] |
| Sample Rate | [X]% |
| Instrumentation | [global/per-agent] |

### Trace Structure
[Hierarchy diagram]

### Implementation
[Code with @observe decorators]

### Evaluations
| Type | Metric | Target |
|------|--------|--------|
| [Type] | [Name] | [Value] |

### Cost Tracking
| Metric | Formula |
|--------|---------|
| Input Cost | tokens/1000 × $[X] |
| Output Cost | tokens/1000 × $[X] |

→ CHAIN: Ready for agent-audit-graph
```

## Common Mistakes

- Forgetting to call `flush()` in serverless
- Not propagating user_id/session_id
- Tracing 100% in high-volume production
- Not handling trace errors gracefully
- Missing cost tracking configuration
- Ignoring evaluation setup
- Not testing trace hierarchy
