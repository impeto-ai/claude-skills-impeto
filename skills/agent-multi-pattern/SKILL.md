---
name: agent-multi-pattern
description: Use when building multi-agent systems. Activates for "multi-agent", "supervisor", "swarm", "routing", "orchestrator", "agents coordination".
---

# Agent Multi-Pattern

Expert in multi-agent architectures: supervisor, swarm, routing, and orchestration patterns.

## When to Use

- Building systems with multiple agents
- Implementing agent coordination
- Designing agent hierarchies
- User says: multi-agent, supervisor, swarm, routing
- NOT when: single agent (use graph-agent)

## Multi-Agent Patterns

```
┌─────────────────────────────────────────────────────────────────┐
│                    MULTI-AGENT PATTERNS                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. SUPERVISOR  → One boss, many workers                       │
│   2. SWARM       → Peer-to-peer collaboration                   │
│   3. ROUTER      → Dynamic dispatch                             │
│   4. PIPELINE    → Sequential processing                        │
│   5. HIERARCHY   → Nested supervisors                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Pattern 1: Supervisor

```
         ┌─────────────┐
         │ SUPERVISOR  │
         │   (GPT-4)   │
         └──────┬──────┘
                │
    ┌───────────┼───────────┐
    ▼           ▼           ▼
┌───────┐  ┌───────┐  ┌───────┐
│ Agent │  │ Agent │  │ Agent │
│   A   │  │   B   │  │   C   │
└───────┘  └───────┘  └───────┘
```

### Pydantic AI Implementation

```python
from pydantic_ai import Agent
from pydantic import BaseModel

class TaskAssignment(BaseModel):
    """Supervisor's decision on task assignment."""
    agent: str  # "research", "code", "review"
    task: str
    context: dict

class SupervisorResult(BaseModel):
    """Final aggregated result."""
    summary: str
    agent_outputs: dict[str, str]
    confidence: float

# Specialized agents
research_agent = Agent(
    "openai:gpt-4o",
    system_prompt="You are a research specialist...",
    tools=[search_web, fetch_url]
)

code_agent = Agent(
    "openai:gpt-4o",
    system_prompt="You are a coding specialist...",
    tools=[read_file, write_file, run_code]
)

review_agent = Agent(
    "openai:gpt-4o",
    system_prompt="You are a code review specialist...",
    tools=[read_file, analyze_code]
)

# Supervisor agent
supervisor = Agent(
    "openai:gpt-4o",
    system_prompt="""
    You are a supervisor managing a team:
    - research_agent: Web research and information gathering
    - code_agent: Writing and modifying code
    - review_agent: Code review and quality checks

    Analyze the user's request and delegate to the appropriate agent(s).
    Coordinate their work and synthesize the final result.
    """,
    output_type=TaskAssignment
)

async def run_supervisor(query: str) -> SupervisorResult:
    """Run supervisor-coordinated multi-agent system."""
    outputs = {}

    # Supervisor decides initial task
    assignment = await supervisor.run(query)

    # Execute with appropriate agent
    agents = {
        "research": research_agent,
        "code": code_agent,
        "review": review_agent
    }

    agent = agents[assignment.data.agent]
    result = await agent.run(assignment.data.task)
    outputs[assignment.data.agent] = result.data

    # Supervisor synthesizes
    synthesis = await supervisor.run(
        f"Synthesize results: {outputs}",
        output_type=SupervisorResult
    )

    return synthesis.data
```

## Pattern 2: Swarm

```
    ┌───────┐     ┌───────┐
    │ Agent │◄───►│ Agent │
    │   A   │     │   B   │
    └───┬───┘     └───┬───┘
        │             │
        └──────┬──────┘
               │
           ┌───▼───┐
           │ Agent │
           │   C   │
           └───────┘
```

### LangGraph Swarm Implementation

```python
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import InMemorySaver

class SwarmState(BaseModel):
    """Shared state for swarm agents."""
    messages: list[dict]
    current_agent: str
    completed_agents: set[str]
    shared_context: dict

def create_swarm_agent(name: str, system_prompt: str):
    """Create an agent that can hand off to others."""

    async def agent_node(state: SwarmState) -> SwarmState:
        agent = Agent("openai:gpt-4o", system_prompt=system_prompt)

        # Run agent
        result = await agent.run(state.messages[-1]["content"])

        # Decide next agent
        next_agent = decide_handoff(result, state)

        return state.model_copy(update={
            "messages": [*state.messages, {"role": "assistant", "content": result.data}],
            "current_agent": next_agent,
            "completed_agents": state.completed_agents | {name}
        })

    return agent_node

# Build swarm graph
builder = StateGraph(SwarmState)

builder.add_node("alice", create_swarm_agent("alice", "You are Alice, expert in..."))
builder.add_node("bob", create_swarm_agent("bob", "You are Bob, expert in..."))
builder.add_node("charlie", create_swarm_agent("charlie", "You are Charlie, expert in..."))

# Dynamic routing
def route_to_agent(state: SwarmState) -> str:
    if state.current_agent == "done":
        return END
    return state.current_agent

builder.add_conditional_edges(START, route_to_agent)
builder.add_conditional_edges("alice", route_to_agent)
builder.add_conditional_edges("bob", route_to_agent)
builder.add_conditional_edges("charlie", route_to_agent)

swarm = builder.compile(checkpointer=InMemorySaver())
```

## Pattern 3: Router

```
              ┌──────────┐
              │  ROUTER  │
              └────┬─────┘
                   │
     ┌─────────────┼─────────────┐
     ▼             ▼             ▼
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Handler │  │ Handler │  │ Handler │
│   SQL   │  │  Code   │  │  Chat   │
└─────────┘  └─────────┘  └─────────┘
```

### Router Implementation

```python
from pydantic import BaseModel
from typing import Literal

class RouterDecision(BaseModel):
    """Router's classification decision."""
    route: Literal["sql", "code", "chat", "unknown"]
    confidence: float
    reasoning: str

router_agent = Agent(
    "openai:gpt-4o",
    system_prompt="""
    Classify the user's intent and route to the appropriate handler:

    - sql: Database queries, data analysis, SQL questions
    - code: Code writing, debugging, refactoring
    - chat: General conversation, questions, explanations

    Return the most appropriate route with confidence.
    """,
    output_type=RouterDecision
)

handlers = {
    "sql": sql_agent,
    "code": code_agent,
    "chat": chat_agent,
}

async def routed_request(query: str) -> str:
    """Route request to appropriate handler."""
    # Classify
    decision = await router_agent.run(query)

    if decision.data.confidence < 0.7:
        # Low confidence - use general chat
        handler = handlers["chat"]
    else:
        handler = handlers.get(decision.data.route, handlers["chat"])

    # Execute
    result = await handler.run(query)
    return result.data
```

## Pattern 4: Pipeline

```
┌───────┐    ┌───────┐    ┌───────┐    ┌───────┐
│ Parse │ → │ Enrich │ → │Process│ → │ Format│
└───────┘    └───────┘    └───────┘    └───────┘
```

### Pipeline Implementation

```python
class PipelineState(BaseModel):
    """State flowing through pipeline."""
    raw_input: str
    parsed: dict | None = None
    enriched: dict | None = None
    processed: dict | None = None
    formatted: str | None = None

async def run_pipeline(input: str) -> str:
    """Sequential multi-agent pipeline."""
    state = PipelineState(raw_input=input)

    # Stage 1: Parse
    parse_result = await parse_agent.run(state.raw_input)
    state = state.model_copy(update={"parsed": parse_result.data})

    # Stage 2: Enrich
    enrich_result = await enrich_agent.run(str(state.parsed))
    state = state.model_copy(update={"enriched": enrich_result.data})

    # Stage 3: Process
    process_result = await process_agent.run(str(state.enriched))
    state = state.model_copy(update={"processed": process_result.data})

    # Stage 4: Format
    format_result = await format_agent.run(str(state.processed))
    state = state.model_copy(update={"formatted": format_result.data})

    return state.formatted
```

## Pattern 5: Hierarchy

```
              ┌───────────────┐
              │   CEO Agent   │
              └───────┬───────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   ┌─────────┐  ┌─────────┐  ┌─────────┐
   │   CTO   │  │   CFO   │  │   CMO   │
   └────┬────┘  └────┬────┘  └────┬────┘
        │            │            │
    ┌───┴───┐    ┌───┴───┐    ┌───┴───┐
    ▼       ▼    ▼       ▼    ▼       ▼
 Dev     Ops   Acct   Fin   Mkt   Sales
```

### Hierarchical Implementation

```python
class TeamResult(BaseModel):
    """Result from a team."""
    team: str
    findings: list[str]
    recommendations: list[str]

class LeaderSynthesis(BaseModel):
    """Leader's synthesis of team results."""
    summary: str
    decision: str
    delegations: list[dict]

def create_team_lead(name: str, team_agents: list[Agent]):
    """Create a team lead that coordinates team agents."""

    async def lead_node(state: HierarchyState) -> TeamResult:
        # Delegate to team members
        team_results = await asyncio.gather(*[
            agent.run(state.task) for agent in team_agents
        ])

        # Synthesize team results
        synthesis = await synthesis_agent.run(
            f"Synthesize results from {name} team: {team_results}"
        )

        return TeamResult(
            team=name,
            findings=extract_findings(team_results),
            recommendations=synthesis.data.recommendations
        )

    return lead_node
```

## Coordination Patterns

### Shared Memory

```python
from langgraph.store.memory import InMemoryStore

# Shared memory across agents
store = InMemoryStore()

async def agent_with_shared_memory(state, store):
    # Read from shared memory
    shared = await store.get(("shared", "context"))

    # Do work...

    # Write to shared memory
    await store.put(("shared", "context"), {"key": "value"})
```

### Message Passing

```python
class AgentMessage(BaseModel):
    """Message between agents."""
    from_agent: str
    to_agent: str
    message_type: str
    content: dict
    timestamp: datetime

message_queue: asyncio.Queue[AgentMessage] = asyncio.Queue()

async def send_to_agent(target: str, content: dict):
    await message_queue.put(AgentMessage(
        from_agent="current",
        to_agent=target,
        message_type="request",
        content=content,
        timestamp=datetime.utcnow()
    ))
```

## Output Format

```
⚡ SKILL_ACTIVATED: #MLTI-4H7N

## Multi-Agent Design: [System Name]

### Pattern
[Supervisor / Swarm / Router / Pipeline / Hierarchy]

### Agents
| Agent | Role | Model | Tools |
|-------|------|-------|-------|
| [name] | [role] | [model] | [tools] |

### Coordination
- Type: [shared memory / message passing / direct calls]
- State: [state schema]

### Flow Diagram
```mermaid
[diagram]
```

### Files
- `agents/[system]/orchestrator.py`
- `agents/[system]/agents/[name].py`
```

## Common Mistakes

- Too many agents (overhead)
- No clear ownership (confusion)
- Tight coupling (brittle)
- No error propagation
- Circular dependencies
- Missing termination condition
