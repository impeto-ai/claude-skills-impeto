---
name: pai-agent
description: Use when building AI agents with Pydantic AI. Activates for "agent", "pydantic ai", "criar agent", "build agent", "output_type", "deps_type". CHAINS TO pai-audit after changes.
chain: pai-audit
---

# PAI Agent Builder

Production-ready AI agent development using **Pydantic AI** with structured outputs, dependency injection, and type safety.

## When to Use

- Building new AI agents
- Defining agent output schemas
- Setting up dependency injection
- Configuring agent system prompts
- NOT when: creating tools (use pai-tools)
- NOT when: multi-agent systems (use pai-multi)

## Project Structure (Clean Architecture)

```
src/{project}/
├── domain/
│   ├── prompts/              # System prompt templates
│   ├── tools/                # Tool definitions
│   ├── memory/               # Memory abstractions
│   └── exceptions.py         # Custom exceptions
├── application/
│   ├── chat_service/         # Chat orchestration
│   ├── evaluation_service/   # Quality evaluation
│   └── ingest_service/       # Document ingestion
└── infrastructure/
    ├── api/                  # FastAPI endpoints
    ├── db/                   # Database implementations
    ├── llm_providers/        # LLM connectors
    └── monitoring/           # Observability
```

## Core Pattern: Agent Definition

```python
from dataclasses import dataclass
from pydantic import BaseModel, Field
from pydantic_ai import Agent, RunContext

# 1. DEPENDENCIES (dataclass, not BaseModel)
@dataclass
class AgentDeps:
    http_client: httpx.AsyncClient
    api_key: str
    db: DatabaseConn

# 2. OUTPUT SCHEMA (BaseModel with validation)
class AgentOutput(BaseModel):
    response: str = Field(min_length=1)
    confidence: float = Field(ge=0.0, le=1.0)
    sources: list[str] = Field(default_factory=list)

# 3. AGENT
agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    deps_type=AgentDeps,
    output_type=AgentOutput,
    system_prompt='You are a helpful assistant.',
    instrument=True,  # Enable tracing
)
```

## Structured Output Patterns

### Union Types for Branching

```python
from pydantic import BaseModel
from typing import Literal

class Success(BaseModel):
    status: Literal["success"] = "success"
    data: dict

class InvalidRequest(BaseModel):
    status: Literal["error"] = "error"
    error_message: str

Output = Success | InvalidRequest

agent = Agent[DatabaseConn, Output](
    'openai:gpt-4o',
    output_type=Output,  # type: ignore
    deps_type=DatabaseConn,
)
```

### Multiple ToolOutput Types

```python
from pydantic_ai import Agent, ToolOutput

class Fruit(BaseModel):
    name: str
    color: str

class Vehicle(BaseModel):
    name: str
    wheels: int

agent = Agent(
    'openai:gpt-4o',
    output_type=[
        ToolOutput(Fruit, name='return_fruit'),
        ToolOutput(Vehicle, name='return_vehicle'),
    ],
)
```

### Output Validator

```python
from pydantic_ai import Agent, RunContext, ModelRetry

@agent.output_validator
async def validate_output(ctx: RunContext[Deps], output: Output) -> Output:
    if isinstance(output, InvalidRequest):
        return output
    try:
        await ctx.deps.db.execute(f'EXPLAIN {output.sql_query}')
    except QueryError as e:
        raise ModelRetry(f'Invalid query: {e}') from e
    return output
```

## System Prompt Patterns

### Static + Dynamic Composition

```python
agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    deps_type=AgentDeps,
    output_type=AgentOutput,
    system_prompt='You are a financial analyst.',  # Static base
)

@agent.system_prompt
def output_format() -> str:
    return 'Always respond with structured JSON.'

@agent.system_prompt
async def user_context(ctx: RunContext[AgentDeps]) -> str:
    user = await ctx.deps.get_user()
    return f'Current user: {user.name}, role: {user.role}'
```

## Dependency Injection

```python
from dataclasses import dataclass
import httpx

@dataclass
class MyDeps:
    http_client: httpx.AsyncClient
    api_key: str
    db: DatabaseConn

agent = Agent('openai:gpt-4o', deps_type=MyDeps)

# Running with deps
async def main():
    async with httpx.AsyncClient() as client:
        deps = MyDeps(
            http_client=client,
            api_key='secret',
            db=DatabaseConn()
        )
        result = await agent.run('Hello', deps=deps)
        print(result.output)
        print(result.usage())
```

## MCP Integration

```python
from pydantic_ai import Agent
from pydantic_ai.mcp import MCPServerStdio

server = MCPServerStdio('python', args=['my_server.py'])
agent = Agent('openai:gpt-4o', toolsets=[server])

async def main():
    async with agent:
        result = await agent.run('Use the tools to help me.')
    print(result.output)
```

## Message History (Conversations)

```python
from pydantic_ai import Agent

agent = Agent('openai:gpt-4o')

# First turn
result1 = await agent.run('What is Python?')

# Continue conversation
result2 = await agent.run(
    'Tell me more about its type system.',
    message_history=result1.all_messages(),
)
```

## Usage Tracking

```python
result = await agent.run('query', deps=deps, usage=parent_usage)
print(result.usage())
# RunUsage(input_tokens=309, output_tokens=32, requests=4, tool_calls=2)
```

## Agent File Organization

```
src/{project}/
├── agents/
│   ├── __init__.py
│   ├── researcher.py        # 1 agent per file
│   ├── writer.py             # agent + private tools + prompts
│   └── reviewer.py
├── models/                   # Shared Pydantic models
│   ├── __init__.py
│   └── outputs.py
├── deps.py                   # Shared dependency dataclasses
├── types.py                  # Annotated types
└── config.py                 # BaseSettings
```

## Production Checklist

```
- [ ] output_type with proper Pydantic validation
- [ ] deps_type as @dataclass (not BaseModel)
- [ ] instrument=True for tracing
- [ ] System prompts composed (not monolithic)
- [ ] ModelRetry in tools for self-correction
- [ ] Output validator for critical outputs
- [ ] Usage tracking configured
- [ ] httpx.AsyncClient shared via deps
- [ ] No secrets hardcoded (use deps or BaseSettings)
```

## Common Mistakes

- Using BaseModel for deps (use @dataclass)
- Hardcoding API keys (use deps injection)
- Monolithic system prompts (compose with @agent.system_prompt)
- No output validation (use @agent.output_validator)
- Missing instrument=True (no observability)
- Creating httpx clients inside tools (share via deps)

## Chain Behavior

After ANY code change:
→ AUTOMATICALLY trigger: pai-audit
→ Validate implementation quality
