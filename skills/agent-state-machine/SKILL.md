---
name: agent-state-machine
description: Use when implementing state management, persistence, checkpointing for agents. Activates for "state", "persistence", "checkpoint", "durability", "recovery".
---

# Agent State Machine

Expert in state management, persistence, and durable execution for AI agents.

## When to Use

- Implementing state persistence
- Adding checkpoints to agents
- Building durable/resumable agents
- User says: state, persistence, checkpoint, durability
- NOT when: simple stateless agents

## State Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    DURABLE EXECUTION                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   [Start] → [Node A] → [Checkpoint] → [Node B] → [End]          │
│                             │                                   │
│                             ↓                                   │
│                      💾 Persistence                              │
│                             │                                   │
│                   ┌─────────┴─────────┐                         │
│                   │                   │                         │
│              FileState           PostgresState                  │
│              (JSON file)         (Database)                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## State Definition Best Practices

```python
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Any

class AgentState(BaseModel):
    """Production-ready state model."""

    # Identification
    run_id: str = Field(..., description="Unique run identifier")
    created_at: datetime = Field(default_factory=datetime.utcnow)

    # Progress tracking
    step: int = Field(default=0, ge=0)
    current_node: str = Field(default="start")

    # Conversation
    messages: list[dict] = Field(default_factory=list)

    # Working memory (within run)
    context: dict[str, Any] = Field(default_factory=dict)

    # Metadata
    metadata: dict[str, Any] = Field(default_factory=dict)

    class Config:
        # Ensure immutability
        frozen = False  # We use model_copy instead
        extra = "forbid"  # No unexpected fields
```

## Immutable State Updates

```python
# ❌ WRONG - Direct mutation
def bad_update(state: AgentState):
    state.messages.append({"role": "user", "content": "hi"})
    state.step += 1
    return state

# ✅ RIGHT - Immutable update
def good_update(state: AgentState) -> AgentState:
    return state.model_copy(update={
        "messages": [*state.messages, {"role": "user", "content": "hi"}],
        "step": state.step + 1,
    })

# ✅ ALSO RIGHT - Deep update
def deep_update(state: AgentState) -> AgentState:
    new_context = {**state.context, "new_key": "new_value"}
    return state.model_copy(update={"context": new_context})
```

## Persistence Implementations

### File Persistence (Development)

```python
from pydantic_graph.persistence import FileStatePersistence
from pathlib import Path
import uuid

def create_file_persistence(run_id: str | None = None) -> FileStatePersistence:
    """Create file-based persistence."""
    run_id = run_id or str(uuid.uuid4())

    runs_dir = Path("./runs")
    runs_dir.mkdir(exist_ok=True)

    return FileStatePersistence(
        json_file=runs_dir / f"{run_id}.json"
    )
```

### PostgreSQL Persistence (Production)

```python
from pydantic_graph.persistence import BaseStatePersistence
from pydantic import BaseModel
from typing import TypeVar
import asyncpg

StateT = TypeVar("StateT", bound=BaseModel)
RunEndT = TypeVar("RunEndT")

class PostgresStatePersistence(BaseStatePersistence[StateT, RunEndT]):
    """Production-grade Postgres persistence."""

    def __init__(self, pool: asyncpg.Pool, run_id: str):
        self.pool = pool
        self.run_id = run_id

    async def snapshot_node(
        self,
        state: StateT,
        next_node: BaseNode
    ) -> None:
        """Save state before node execution."""
        async with self.pool.acquire() as conn:
            await conn.execute("""
                INSERT INTO agent_snapshots
                (run_id, snapshot_id, state, node_type, status, created_at)
                VALUES ($1, $2, $3, $4, 'pending', NOW())
            """,
                self.run_id,
                next_node.snapshot_id,
                state.model_dump_json(),
                type(next_node).__name__
            )

    async def load_next(self) -> NodeSnapshot | None:
        """Load next pending node."""
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow("""
                SELECT * FROM agent_snapshots
                WHERE run_id = $1 AND status = 'pending'
                ORDER BY created_at ASC
                LIMIT 1
            """, self.run_id)

            if row:
                return NodeSnapshot(
                    id=row['snapshot_id'],
                    state=self.state_type.model_validate_json(row['state']),
                    node=self.deserialize_node(row['node_type'])
                )
            return None
```

### Supabase Persistence

```python
from supabase import AsyncClient

class SupabaseStatePersistence(BaseStatePersistence[StateT, RunEndT]):
    """Supabase-based persistence with RLS."""

    def __init__(self, client: AsyncClient, run_id: str, user_id: str):
        self.client = client
        self.run_id = run_id
        self.user_id = user_id

    async def snapshot_node(self, state: StateT, next_node: BaseNode) -> None:
        await self.client.table("agent_snapshots").insert({
            "run_id": self.run_id,
            "user_id": self.user_id,  # For RLS
            "snapshot_id": next_node.snapshot_id,
            "state": state.model_dump(),
            "node_type": type(next_node).__name__,
            "status": "pending"
        }).execute()
```

## Checkpoint Patterns

### Manual Checkpoints

```python
class ProcessData(Node[AgentState, AgentOutput]):
    """Node with explicit checkpoint."""

    async def run(self, state: AgentState) -> AgentState:
        # Do work
        processed = await self.process(state)

        # Return updated state (will be checkpointed)
        return state.model_copy(update={
            "context": {**state.context, "processed": processed},
            "step": state.step + 1
        })
```

### Conditional Checkpoints

```python
class LongRunningNode(Node[AgentState, AgentOutput]):
    """Checkpoint only on significant progress."""

    checkpoint_every: int = 10

    async def run(self, state: AgentState) -> AgentState:
        for i in range(100):
            await self.process_item(i)

            # Checkpoint every N items
            if i % self.checkpoint_every == 0:
                state = state.model_copy(update={
                    "context": {**state.context, "progress": i}
                })
                await self.persistence.snapshot_node(state, self)

        return state
```

## Recovery Patterns

### Resume from Checkpoint

```python
async def resume_agent(run_id: str):
    """Resume agent from last checkpoint."""
    persistence = PostgresStatePersistence(pool, run_id)

    try:
        async with agent_graph.iter_from_persistence(persistence) as run:
            while True:
                result = await run.next()
                if isinstance(result, End):
                    return result.data

    except GraphRuntimeError as e:
        # No checkpoint found
        logger.warning(f"Cannot resume {run_id}: {e}")
        return None
```

### Retry with Backoff

```python
async def run_with_retry(state: AgentState, max_retries: int = 3):
    """Run agent with automatic retry on failure."""
    persistence = create_file_persistence(state.run_id)

    for attempt in range(max_retries):
        try:
            async with agent_graph.iter_from_persistence(persistence) as run:
                return await run.next()

        except TransientError:
            wait_time = 2 ** attempt  # Exponential backoff
            await asyncio.sleep(wait_time)
            continue

    raise MaxRetriesExceeded(f"Failed after {max_retries} attempts")
```

## Database Schema (Postgres/Supabase)

```sql
-- Migration: Create agent state tables
CREATE TABLE agent_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    agent_type TEXT NOT NULL,
    status TEXT DEFAULT 'running',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'
);

CREATE TABLE agent_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id UUID REFERENCES agent_runs(id) ON DELETE CASCADE,
    snapshot_id TEXT NOT NULL,
    state JSONB NOT NULL,
    node_type TEXT NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, running, success, error
    created_at TIMESTAMPTZ DEFAULT NOW(),
    duration_ms INTEGER,
    error_message TEXT
);

-- Indexes for efficient queries
CREATE INDEX idx_snapshots_run_status ON agent_snapshots(run_id, status);
CREATE INDEX idx_runs_user_status ON agent_runs(user_id, status);

-- RLS Policies
ALTER TABLE agent_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own runs" ON agent_runs
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users see own snapshots" ON agent_snapshots
    FOR ALL USING (
        run_id IN (SELECT id FROM agent_runs WHERE user_id = auth.uid())
    );
```

## Output Format

```
⚡ SKILL_ACTIVATED: #STMC-7D4Q

## State Implementation: [Agent Name]

### State Schema
```python
class [Name]State(BaseModel):
    ...
```

### Persistence Type
- [ ] FileStatePersistence (dev)
- [x] PostgresStatePersistence (prod)
- [ ] SupabaseStatePersistence (prod + RLS)

### Checkpoint Strategy
- Checkpoint after: [every node / every N steps / on significant change]
- Recovery: [auto-resume / manual trigger]

### Migration Created
- `migrations/xxx_agent_state_tables.sql`

### Files
- `agents/[name]/state.py`
- `agents/[name]/persistence.py`
```

## Common Mistakes

- Mutable state (use model_copy)
- No persistence for long-running agents
- Checkpointing too often (performance)
- Checkpointing too rarely (lost progress)
- No cleanup of old runs
- Not handling recovery failures
