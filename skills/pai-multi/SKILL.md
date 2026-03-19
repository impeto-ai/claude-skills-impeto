---
name: pai-multi
description: Use when building multi-agent systems with Pydantic AI. Activates for "multi-agent", "delegation", "agent-as-tool", "orchestrator", "agents coordination".
chain: pai-audit
---

# PAI Multi-Agent

Expert in multi-agent architectures using Pydantic AI's **agent-as-tool** delegation pattern.

## When to Use

- Building systems with multiple cooperating agents
- Implementing agent delegation (agent calling agent)
- Designing orchestrator patterns
- NOT when: single agent (use pai-agent)

## Core Pattern: Agent-as-Tool Delegation

In Pydantic AI, multi-agent = one agent calls another **inside a tool**.

```python
from dataclasses import dataclass
import httpx
from pydantic_ai import Agent, RunContext

@dataclass
class SharedDeps:
    http_client: httpx.AsyncClient
    api_key: str

# DELEGATE AGENT (specialist)
researcher = Agent(
    'google-gla:gemini-1.5-flash',
    deps_type=SharedDeps,
    output_type=list[str],
    system_prompt='You are a research specialist. Find relevant information.',
)

# ORCHESTRATOR AGENT (coordinator)
coordinator = Agent(
    'anthropic:claude-sonnet-4-20250514',
    deps_type=SharedDeps,
    system_prompt='You coordinate research and writing. Use tools to delegate.',
)

# Delegation happens inside a tool
@coordinator.tool
async def research(ctx: RunContext[SharedDeps], topic: str) -> list[str]:
    """Delegate research to the specialist agent.

    Args:
        ctx: Runtime context with shared dependencies.
        topic: The topic to research.
    """
    result = await researcher.run(
        f'Research this topic: {topic}',
        deps=ctx.deps,        # Share dependencies
        usage=ctx.usage,       # Aggregate usage/costs
    )
    return result.output

@coordinator.tool
async def write_report(ctx: RunContext[SharedDeps], findings: list[str]) -> str:
    """Write a report based on research findings."""
    result = await writer.run(
        f'Write a report from: {findings}',
        deps=ctx.deps,
        usage=ctx.usage,
    )
    return result.output

# Run
async def main():
    async with httpx.AsyncClient() as client:
        deps = SharedDeps(client, 'key')
        result = await coordinator.run('Analyze crop yields in 2025', deps=deps)
        print(result.output)
        print(result.usage())  # Aggregated across all agents
```

## Key Rules

### 1. Share deps via ctx.deps
```python
# Delegate passing same deps
result = await delegate_agent.run(prompt, deps=ctx.deps)
```

### 2. Aggregate usage via ctx.usage
```python
# Track costs across all agents
result = await delegate_agent.run(prompt, deps=ctx.deps, usage=ctx.usage)
```

### 3. Each agent has its own output_type
```python
researcher = Agent(..., output_type=list[str])      # Returns findings
writer = Agent(..., output_type=str)                  # Returns report
reviewer = Agent(..., output_type=ReviewResult)       # Returns review
```

## Patterns

### Router (Intent Classification)

```python
from typing import Literal
from pydantic import BaseModel

class RouterDecision(BaseModel):
    route: Literal["sql", "code", "chat"]
    confidence: float

router = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=RouterDecision,
    system_prompt='Classify user intent into: sql, code, or chat.',
)

sql_agent = Agent(..., system_prompt='You are a SQL expert.')
code_agent = Agent(..., system_prompt='You are a coding expert.')
chat_agent = Agent(..., system_prompt='You are a helpful assistant.')

async def handle_query(query: str, deps: Deps) -> str:
    decision = await router.run(query, deps=deps)

    match decision.output.route:
        case "sql": result = await sql_agent.run(query, deps=deps)
        case "code": result = await code_agent.run(query, deps=deps)
        case "chat": result = await chat_agent.run(query, deps=deps)

    return result.output
```

### Pipeline (Sequential)

```python
async def pipeline(raw_text: str, deps: Deps) -> str:
    # Step 1: Extract
    extracted = await extractor.run(raw_text, deps=deps)

    # Step 2: Analyze (using previous output)
    analyzed = await analyzer.run(
        f'Analyze: {extracted.output}',
        deps=deps,
    )

    # Step 3: Summarize
    summary = await summarizer.run(
        f'Summarize analysis: {analyzed.output}',
        deps=deps,
    )

    return summary.output
```

### Critic/Reviewer Loop

```python
class ReviewResult(BaseModel):
    approved: bool
    feedback: str

reviewer = Agent(..., output_type=ReviewResult)

async def write_with_review(topic: str, deps: Deps, max_rounds: int = 3) -> str:
    draft = await writer.run(f'Write about: {topic}', deps=deps)
    content = draft.output

    for round in range(max_rounds):
        review = await reviewer.run(
            f'Review this draft:\n{content}',
            deps=deps,
        )
        if review.output.approved:
            return content

        # Revise based on feedback
        revision = await writer.run(
            f'Revise based on feedback:\n'
            f'Draft: {content}\n'
            f'Feedback: {review.output.feedback}',
            deps=deps,
        )
        content = revision.output

    return content  # Return last version
```

## File Organization

```
src/{project}/
├── agents/
│   ├── coordinator.py     # Orchestrator agent + delegation tools
│   ├── researcher.py      # Research specialist
│   ├── writer.py           # Writing specialist
│   └── reviewer.py         # Review specialist
├── deps.py                 # Shared @dataclass deps
└── orchestration.py        # Pipeline/router functions
```

## Common Mistakes

- Not passing ctx.deps to delegate agents (deps isolation)
- Not passing ctx.usage (can't track total costs)
- Too many agents (start with 2-3, add as needed)
- Agents with overlapping responsibilities
- No termination condition in loops (infinite review cycles)
- Tight coupling between agents (communicate via simple types)

## Chain Behavior

After creating multi-agent system:
→ AUTOMATICALLY trigger: pai-audit
