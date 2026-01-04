---
name: agent-state-machine
description: Use when implementing state management, persistence, checkpointing for graph-based agents. Activates for "state", "persistence", "checkpoint", "GraphRunContext", "FileStatePersistence".
---

# Agent State Machine (Graph-Specialized)

Expert in **state management with Pydantic Graph**, including GraphRunContext, FileStatePersistence, and dataclass-based state.

## When to Use

- Implementing state persistence in graphs
- Adding checkpoints to multi-node workflows
- Building resumable/durable agent graphs
- User says: state, persistence, checkpoint, GraphRunContext
- NOT when: simple stateless agents

## Graph State Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    PYDANTIC GRAPH STATE                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   [Start] → [NodeA] → [NodeB] → [NodeC] → [End]                │
│       │         │         │         │                           │
│       └─────────┴─────────┴─────────┘                           │
│                     │                                           │
│              GraphRunContext[State]                             │
│                     │                                           │
│            ctx.state.* (read/write)                            │
│                     │                                           │
│              FileStatePersistence                               │
│              (auto-saves after each node)                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## State Definition with Dataclass

Pydantic Graph uses **dataclasses** for state (not BaseModel):

```python
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

@dataclass
class WorkflowState:
    """Graph state - mutable dataclass, shared across all nodes."""

    # Identification
    run_id: str = ""
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())

    # Current task
    query: str = ""
    result: str = ""

    # Progress tracking
    current_step: str = ""
    completed_steps: list[str] = field(default_factory=list)

    # Message history (for agent conversations)
    agent_messages: list = field(default_factory=list)

    # Working memory
    context: dict[str, Any] = field(default_factory=dict)

    # Error tracking
    errors: list[str] = field(default_factory=list)
```

### State vs BaseModel for Agents

```python
# Graph State = dataclass (mutable, shared)
@dataclass
class GraphState:
    messages: list = field(default_factory=list)

# Agent Output = BaseModel (immutable, returned)
class AgentOutput(BaseModel):
    response: str
    confidence: float
```

## GraphRunContext Usage

Every node receives `GraphRunContext[StateT]`:

```python
from dataclasses import dataclass, field
from pydantic_graph import BaseNode, End, GraphRunContext
from pydantic_ai import Agent

@dataclass
class ConversationState:
    user_query: str = ""
    messages: list = field(default_factory=list)
    turn_count: int = 0
    max_turns: int = 10

chat_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=ChatResponse,
    instrument=True
)

@dataclass
class ChatNode(BaseNode[ConversationState]):
    user_input: str = ""

    async def run(self, ctx: GraphRunContext[ConversationState]) -> 'ChatNode | End[str]':
        # READ from state
        history = ctx.state.messages
        turn = ctx.state.turn_count

        # Call agent with state context
        result = await chat_agent.run(
            self.user_input,
            message_history=history
        )

        # WRITE to state (direct mutation is OK with dataclass)
        ctx.state.messages = result.all_messages()
        ctx.state.turn_count += 1

        # Use state to decide next node
        if result.output.should_end or ctx.state.turn_count >= ctx.state.max_turns:
            return End(result.output.summary)

        return ChatNode(user_input=result.output.follow_up)
```

## State Patterns

### Pattern 1: Accumulating Results

```python
@dataclass
class ResearchState:
    topics: list[str] = field(default_factory=list)
    findings: dict[str, list[str]] = field(default_factory=dict)
    current_topic_idx: int = 0

@dataclass
class ResearchNode(BaseNode[ResearchState]):
    async def run(self, ctx: GraphRunContext[ResearchState]) -> 'ResearchNode | SynthesisNode':
        # Get current topic from state
        if ctx.state.current_topic_idx >= len(ctx.state.topics):
            return SynthesisNode()

        topic = ctx.state.topics[ctx.state.current_topic_idx]

        # Research
        result = await research_agent.run(f"Research: {topic}")

        # Accumulate in state
        ctx.state.findings[topic] = result.output.findings
        ctx.state.current_topic_idx += 1

        # Loop or continue
        return ResearchNode()

@dataclass
class SynthesisNode(BaseNode[ResearchState]):
    async def run(self, ctx: GraphRunContext[ResearchState]) -> End[str]:
        # Access accumulated state
        all_findings = ctx.state.findings

        result = await synthesis_agent.run(
            f"Synthesize findings: {all_findings}"
        )

        return End(result.output.summary)
```

### Pattern 2: Multi-Agent Message Passing

```python
@dataclass
class DebateState:
    topic: str = ""
    pro_messages: list = field(default_factory=list)
    con_messages: list = field(default_factory=list)
    rounds: int = 0
    max_rounds: int = 3
    final_synthesis: str = ""

@dataclass
class ProArgumentNode(BaseNode[DebateState]):
    async def run(self, ctx: GraphRunContext[DebateState]) -> 'ConArgumentNode':
        # Use dedicated message history
        result = await pro_agent.run(
            f"Argue for: {ctx.state.topic}",
            message_history=ctx.state.pro_messages
        )

        # Update agent's history
        ctx.state.pro_messages = result.all_messages()

        return ConArgumentNode()

@dataclass
class ConArgumentNode(BaseNode[DebateState]):
    async def run(self, ctx: GraphRunContext[DebateState]) -> 'ProArgumentNode | JudgeNode':
        # Use dedicated message history
        result = await con_agent.run(
            f"Argue against: {ctx.state.topic}",
            message_history=ctx.state.con_messages
        )

        ctx.state.con_messages = result.all_messages()
        ctx.state.rounds += 1

        if ctx.state.rounds >= ctx.state.max_rounds:
            return JudgeNode()

        return ProArgumentNode()
```

### Pattern 3: Branching with State

```python
@dataclass
class WorkflowState:
    task_type: str = ""
    input_data: dict = field(default_factory=dict)
    result: str = ""
    path_taken: list[str] = field(default_factory=list)

@dataclass
class RouterNode(BaseNode[WorkflowState]):
    async def run(self, ctx: GraphRunContext[WorkflowState]) -> 'AnalysisNode | GenerationNode | TransformNode':
        # Analyze to determine path
        result = await router_agent.run(
            f"Classify task: {ctx.state.task_type}"
        )

        # Track path in state
        ctx.state.path_taken.append("router")

        match result.output.route:
            case "analysis":
                ctx.state.path_taken.append("analysis")
                return AnalysisNode()
            case "generation":
                ctx.state.path_taken.append("generation")
                return GenerationNode()
            case _:
                ctx.state.path_taken.append("transform")
                return TransformNode()
```

## FileStatePersistence

Built-in persistence that saves state after each node:

```python
from pydantic_graph import Graph
from pydantic_graph.persistence import FileStatePersistence
import uuid

async def run_with_persistence():
    # Create graph
    graph = Graph(nodes=[StartNode, ProcessNode, EndNode])

    # Create state
    run_id = str(uuid.uuid4())
    state = WorkflowState(run_id=run_id, query="user query")

    # Create persistence - saves to JSON file after each node
    persistence = FileStatePersistence(f"./checkpoints/{run_id}.json")

    # Run with persistence
    result = await graph.run(
        StartNode(),
        state=state,
        persistence=persistence
    )

    return result
```

### Resuming from Checkpoint

```python
async def resume_workflow(run_id: str):
    """Resume from last saved checkpoint."""

    persistence = FileStatePersistence(f"./checkpoints/{run_id}.json")
    graph = Graph(nodes=[StartNode, ProcessNode, EndNode])

    # Load and resume
    async with graph.iter_from_persistence(persistence) as run:
        async for node_result in run:
            print(f"Completed: {node_result}")

        return run.result
```

### Checking Persistence Status

```python
from pathlib import Path

def get_pending_runs() -> list[str]:
    """Find runs that can be resumed."""
    checkpoints = Path("./checkpoints")
    pending = []

    for file in checkpoints.glob("*.json"):
        import json
        data = json.loads(file.read_text())

        # Check if not completed
        if data.get("status") != "completed":
            pending.append(file.stem)

    return pending
```

## Database Persistence (Production)

For production, implement `BaseStatePersistence`:

```python
from pydantic_graph.persistence import BaseStatePersistence
from dataclasses import dataclass
from typing import TypeVar, Generic
import asyncpg

StateT = TypeVar("StateT")

class PostgresStatePersistence(BaseStatePersistence[StateT]):
    """Production-grade Postgres persistence."""

    def __init__(self, pool: asyncpg.Pool, run_id: str, state_type: type[StateT]):
        self.pool = pool
        self.run_id = run_id
        self.state_type = state_type

    async def snapshot_node(self, state: StateT, next_node) -> None:
        """Save state before node execution."""
        import json
        from dataclasses import asdict

        async with self.pool.acquire() as conn:
            await conn.execute("""
                INSERT INTO graph_snapshots
                (run_id, snapshot_id, state_json, node_type, created_at)
                VALUES ($1, $2, $3, $4, NOW())
                ON CONFLICT (run_id, snapshot_id) DO UPDATE
                SET state_json = $3, node_type = $4
            """,
                self.run_id,
                next_node.snapshot_id,
                json.dumps(asdict(state)),
                type(next_node).__name__
            )

    async def load_next(self):
        """Load next pending node for resume."""
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow("""
                SELECT * FROM graph_snapshots
                WHERE run_id = $1
                ORDER BY created_at DESC
                LIMIT 1
            """, self.run_id)

            if row:
                import json
                state_dict = json.loads(row['state_json'])
                return self.state_type(**state_dict)

            return None
```

### Database Schema

```sql
-- Graph state persistence
CREATE TABLE graph_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    graph_name TEXT NOT NULL,
    status TEXT DEFAULT 'running',  -- running, completed, failed, paused
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE graph_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id UUID REFERENCES graph_runs(id) ON DELETE CASCADE,
    snapshot_id TEXT NOT NULL,
    state_json JSONB NOT NULL,
    node_type TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(run_id, snapshot_id)
);

-- Efficient queries
CREATE INDEX idx_snapshots_run ON graph_snapshots(run_id);
CREATE INDEX idx_runs_user_status ON graph_runs(user_id, status);

-- RLS
ALTER TABLE graph_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE graph_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own runs" ON graph_runs
    FOR ALL USING (auth.uid() = user_id);
```

## State Initialization Patterns

### From User Input

```python
@dataclass
class TaskState:
    user_input: str = ""
    parsed_task: dict = field(default_factory=dict)
    results: list = field(default_factory=list)

async def start_task(user_input: str) -> str:
    state = TaskState(user_input=user_input)

    graph = Graph(nodes=[ParseNode, ExecuteNode, ResultNode])
    return await graph.run(ParseNode(), state=state)
```

### From API Request

```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class TaskRequest(BaseModel):
    query: str
    options: dict = {}

@app.post("/task")
async def create_task(request: TaskRequest):
    run_id = str(uuid.uuid4())

    state = WorkflowState(
        run_id=run_id,
        query=request.query,
        context={"options": request.options}
    )

    persistence = FileStatePersistence(f"./runs/{run_id}.json")

    # Start async
    result = await graph.run(StartNode(), state=state, persistence=persistence)

    return {"run_id": run_id, "result": result}

@app.get("/task/{run_id}")
async def get_task(run_id: str):
    persistence = FileStatePersistence(f"./runs/{run_id}.json")

    # Check status or resume
    ...
```

## Testing State

```python
import pytest
from dataclasses import dataclass, field

class TestGraphState:
    """Test state management in graphs."""

    @pytest.mark.asyncio
    async def test_state_accumulates_across_nodes(self):
        """State persists across node transitions."""
        @dataclass
        class CounterState:
            count: int = 0
            history: list[str] = field(default_factory=list)

        @dataclass
        class IncrementNode(BaseNode[CounterState]):
            async def run(self, ctx: GraphRunContext[CounterState]) -> 'IncrementNode | End[int]':
                ctx.state.count += 1
                ctx.state.history.append(f"count={ctx.state.count}")

                if ctx.state.count >= 3:
                    return End(ctx.state.count)
                return IncrementNode()

        state = CounterState()
        graph = Graph(nodes=[IncrementNode])

        result = await graph.run(IncrementNode(), state=state)

        assert result == 3
        assert state.count == 3
        assert len(state.history) == 3

    @pytest.mark.asyncio
    async def test_persistence_saves_state(self, tmp_path):
        """FileStatePersistence saves after each node."""
        state = WorkflowState(run_id="test-123")
        persistence = FileStatePersistence(tmp_path / "test.json")

        await graph.run(StartNode(), state=state, persistence=persistence)

        # File should exist
        assert (tmp_path / "test.json").exists()
```

## Output Format

```
⚡ SKILL_ACTIVATED: #STMC-7D4Q

## Graph State: [Workflow Name]

### State Definition
```python
@dataclass
class [Name]State:
    run_id: str = ""
    query: str = ""
    messages: list = field(default_factory=list)
    results: dict = field(default_factory=dict)
```

### State Usage
- Read: `ctx.state.query`
- Write: `ctx.state.results["key"] = value`
- Messages: `ctx.state.messages = result.all_messages()`

### Persistence
- [x] FileStatePersistence (development)
- [ ] PostgresStatePersistence (production)

### Checkpoint Strategy
- Auto-save after each node transition
- Resume with: `graph.iter_from_persistence(persistence)`

### Files
- `agents/[name]/state.py`
- `agents/[name]/persistence.py`
```

## Common Mistakes

- Using BaseModel instead of @dataclass for graph state
- Forgetting to pass `state=state` to graph.run()
- Not updating message_history in state
- Creating new state objects instead of mutating ctx.state
- No persistence for long-running graphs
- Not handling resume failures gracefully
