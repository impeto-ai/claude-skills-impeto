---
name: graph-agent
description: Use when building AI agents with Pydantic AI Graph, structured output, state machines. Activates for "agent", "pydantic", "graph", "criar agent", "build agent". CHAINS TO agent-audit-graph after changes.
---

# Graph Agent Builder

Production-ready AI agent development using Pydantic AI Graph with structured outputs and state management.

## When to Use

- Building new AI agents
- Implementing graph-based workflows
- Creating agents with structured output
- State machine design for agents
- User says: agent, pydantic, graph, criar agent, build agent
- NOT when: simple scripts, non-agent code

## Core Principles

```
┌─────────────────────────────────────────────────────────────────┐
│  PYDANTIC AI GRAPH = Type-safe + State Machine + Structured    │
├─────────────────────────────────────────────────────────────────┤
│  1. Define State (Pydantic model)                               │
│  2. Define Nodes (graph steps)                                  │
│  3. Define Edges (transitions)                                  │
│  4. Define Output Schema (structured)                           │
│  5. Implement Persistence (production-ready)                    │
└─────────────────────────────────────────────────────────────────┘
```

## Agent Structure

```python
from pydantic import BaseModel
from pydantic_ai import Agent
from pydantic_graph import Graph, Node, End

# 1. STATE DEFINITION
class AgentState(BaseModel):
    """Immutable state passed between nodes."""
    messages: list[dict] = []
    context: dict = {}
    step: int = 0

# 2. OUTPUT SCHEMA (Structured Output)
class AgentOutput(BaseModel):
    """Strongly typed output - no hallucination."""
    response: str
    confidence: float
    sources: list[str] = []
    next_action: str | None = None

# 3. NODE DEFINITION
class ProcessInput(Node[AgentState, AgentOutput]):
    """First node - process user input."""

    async def run(self, state: AgentState) -> AgentState | End[AgentOutput]:
        # Process logic here
        if should_end:
            return End(AgentOutput(response="done", confidence=0.95))
        return state.model_copy(update={"step": state.step + 1})

# 4. GRAPH DEFINITION
agent_graph = Graph(
    nodes=[ProcessInput, AnalyzeContext, GenerateResponse],
    state_type=AgentState,
    output_type=AgentOutput,
)
```

## Structured Output Patterns

### Pattern 1: Validation-First

```python
from pydantic import BaseModel, field_validator

class ExtractedEntities(BaseModel):
    """Output schema with validation."""
    people: list[str]
    organizations: list[str]
    locations: list[str]

    @field_validator('people', 'organizations', 'locations')
    @classmethod
    def no_empty_strings(cls, v: list[str]) -> list[str]:
        return [item for item in v if item.strip()]
```

### Pattern 2: Union Types for Branching

```python
from typing import Literal

class SuccessOutput(BaseModel):
    status: Literal["success"] = "success"
    data: dict

class ErrorOutput(BaseModel):
    status: Literal["error"] = "error"
    error_code: str
    message: str

AgentResult = SuccessOutput | ErrorOutput
```

### Pattern 3: Nested Schemas

```python
class ToolCall(BaseModel):
    name: str
    arguments: dict

class ReasoningStep(BaseModel):
    thought: str
    action: ToolCall | None
    observation: str | None

class AgentTrace(BaseModel):
    steps: list[ReasoningStep]
    final_answer: str
```

## State Management

### Immutable State Updates

```python
# WRONG - mutating state
state.messages.append(new_message)

# RIGHT - immutable update
new_state = state.model_copy(update={
    "messages": [*state.messages, new_message],
    "step": state.step + 1
})
```

### State Persistence

```python
from pydantic_graph.persistence import FileStatePersistence
from pathlib import Path

# Create persistence
persistence = FileStatePersistence(
    json_file=Path(f"runs/{run_id}.json")
)

# Initialize graph with persistence
await agent_graph.initialize(
    start_node=ProcessInput(),
    state=AgentState(),
    persistence=persistence
)

# Resume from persistence
async with agent_graph.iter_from_persistence(persistence) as run:
    result = await run.next()
```

## Production Checklist

```markdown
### Before Deployment
- [ ] All Pydantic models have proper validation
- [ ] State is immutable (use model_copy)
- [ ] Persistence configured for durability
- [ ] Structured output matches downstream needs
- [ ] Error states handled in graph
- [ ] Timeouts configured for LLM calls
- [ ] Logging/tracing instrumented
```

## Node Design Patterns

### Decision Node

```python
class RouterNode(Node[AgentState, AgentOutput]):
    """Routes to different paths based on input."""

    async def run(self, state: AgentState) -> ProcessA | ProcessB | End[AgentOutput]:
        intent = await self.classify_intent(state)

        match intent:
            case "query": return ProcessA()
            case "action": return ProcessB()
            case "done": return End(AgentOutput(...))
```

### Tool Node

```python
class ToolExecutor(Node[AgentState, AgentOutput]):
    """Executes a tool and updates state."""

    tool_name: str
    tool_args: dict

    async def run(self, state: AgentState) -> AgentState:
        result = await execute_tool(self.tool_name, self.tool_args)
        return state.model_copy(update={
            "context": {**state.context, "tool_result": result}
        })
```

### Aggregator Node

```python
class AggregateResults(Node[AgentState, AgentOutput]):
    """Combines results from parallel branches."""

    async def run(self, state: AgentState) -> End[AgentOutput]:
        combined = aggregate(state.context["branch_results"])
        return End(AgentOutput(
            response=combined,
            confidence=calculate_confidence(state)
        ))
```

## Common Mistakes

- Mutating state directly (use `model_copy`)
- Not validating LLM outputs against schema
- Missing error handling nodes in graph
- No persistence for long-running agents
- Unbounded loops without exit conditions
- Not typing node return values properly

## Output Format

```
⚡ SKILL_ACTIVATED: #GRPH-4A7X

## Agent Implementation: [Name]

### State Schema
```python
class [Name]State(BaseModel):
    ...
```

### Output Schema
```python
class [Name]Output(BaseModel):
    ...
```

### Graph Definition
[Mermaid diagram]

### Nodes
1. [Node 1]: [purpose]
2. [Node 2]: [purpose]

### Files Created/Modified
- `agents/[name]/state.py`
- `agents/[name]/nodes.py`
- `agents/[name]/graph.py`
```

---

## ⚠️ CHAIN TRIGGER

**After ANY code change, AUTOMATICALLY trigger:**

```
→ NEXT SKILL: agent-audit-graph
→ ACTION: Audit the implementation
→ WAIT: Do not mark complete until audit passes
```

If audit fails, issues go to `/.debts/graph-agent/`
