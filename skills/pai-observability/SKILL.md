---
name: pai-observability
description: Use when implementing tracing, monitoring for Pydantic AI agents. Activates for "observability", "monitoring", "tracing", "instrument", "metrics", "eval".
chain: none
---

# PAI Observability

Expert in implementing observability for Pydantic AI agents using **native instrumentation** (no vendor lock-in).

## When to Use

- Adding tracing to agents
- Implementing monitoring/metrics
- Setting up evaluation pipelines
- NOT when: building agent logic (use pai-agent)

## Native Instrumentation (No Vendor Lock-in)

### Per-Agent

```python
from pydantic_ai import Agent

agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=MyOutput,
    instrument=True,  # Enable tracing
)
```

### Global (All Agents)

```python
from pydantic_ai import Agent

Agent.instrument_all()  # Every agent is now traced
```

## What Gets Traced

With `instrument=True` or `Agent.instrument_all()`:
- LLM requests (model, prompt, tokens)
- LLM responses (output, latency)
- Tool calls (name, args, result)
- Token usage and costs
- Retries and errors

## Usage Tracking (Built-in)

```python
result = await agent.run('query', deps=deps)
usage = result.usage()

print(f'Input tokens: {usage.input_tokens}')
print(f'Output tokens: {usage.output_tokens}')
print(f'Requests: {usage.requests}')
print(f'Tool calls: {usage.tool_calls}')
```

### Aggregated Usage (Multi-Agent)

```python
@coordinator.tool
async def delegate(ctx: RunContext[Deps], task: str) -> str:
    result = await specialist.run(task, deps=ctx.deps, usage=ctx.usage)
    return result.output

# After run, usage includes ALL agent calls
result = await coordinator.run('task', deps=deps)
print(result.usage())  # Total across coordinator + specialists
```

## OpenTelemetry Integration (Generic)

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor

# Setup OTEL (works with ANY backend: Jaeger, Zipkin, Datadog, etc.)
provider = TracerProvider()
provider.add_span_processor(SimpleSpanProcessor(your_exporter))
trace.set_tracer_provider(provider)

# Pydantic AI auto-integrates with OTEL when instrument=True
Agent.instrument_all()
```

## Custom Metrics

```python
from dataclasses import dataclass, field
from time import time

@dataclass
class MetricsDeps:
    http_client: httpx.AsyncClient
    _start_time: float = field(default_factory=time)
    _tool_calls: int = 0
    _errors: list[str] = field(default_factory=list)

    @property
    def elapsed_ms(self) -> float:
        return (time() - self._start_time) * 1000

@agent.tool
async def tracked_tool(ctx: RunContext[MetricsDeps], query: str) -> str:
    ctx.deps._tool_calls += 1
    try:
        return await do_work(query)
    except Exception as e:
        ctx.deps._errors.append(str(e))
        raise

# After run
result = await agent.run('query', deps=deps)
print(f'Time: {deps.elapsed_ms}ms')
print(f'Tool calls: {deps._tool_calls}')
print(f'Errors: {deps._errors}')
print(f'Tokens: {result.usage().input_tokens + result.usage().output_tokens}')
```

## LLM-as-Judge Evaluation

```python
from pydantic import BaseModel

class EvalResult(BaseModel):
    accuracy: int    # 1-5
    relevance: int   # 1-5
    clarity: int     # 1-5
    overall: float
    reasoning: str

judge = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=EvalResult,
    system_prompt='Rate the response quality 1-5 on each dimension.',
    instrument=True,
)

async def evaluate(query: str, response: str) -> EvalResult:
    result = await judge.run(
        f'Query: {query}\nResponse: {response}\nEvaluate.'
    )
    return result.output
```

## Key Metrics

```
Execution: completion_rate, avg_latency, p95_latency
Cost: tokens_per_run, cost_per_run
Quality: eval_score, retry_rate, error_rate
```

## Common Mistakes

- Not using instrument=True (no visibility)
- Vendor lock-in (use OTEL for portability)
- No usage tracking (surprise bills)
- Not aggregating usage in multi-agent
- Missing error tracking
