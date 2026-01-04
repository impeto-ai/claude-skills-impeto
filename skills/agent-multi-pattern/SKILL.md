---
name: agent-multi-pattern
description: Use when building multi-agent systems with pydantic-graph. Activates for "multi-agent", "supervisor", "swarm", "routing", "orchestrator", "agents coordination".
---

# Agent Multi-Pattern (Graph-Specialized)

Expert in multi-agent architectures using **Pydantic Graph**: supervisor, swarm, routing, and orchestration patterns with graph nodes.

## When to Use

- Building systems with multiple agents as graph nodes
- Implementing agent coordination through state
- Designing agent hierarchies with node transitions
- User says: multi-agent, supervisor, swarm, routing
- NOT when: single agent workflow (use graph-agent)

## Multi-Agent Patterns in Pydantic Graph

```
┌─────────────────────────────────────────────────────────────────┐
│              MULTI-AGENT GRAPH PATTERNS                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. SUPERVISOR  → One orchestrator node, worker nodes          │
│   2. SWARM       → Agents as nodes, state-based handoff         │
│   3. ROUTER      → Classification node → specialized nodes      │
│   4. PIPELINE    → Sequential agent nodes                       │
│   5. DEBATE      → Pro/Con nodes with judge node                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Pattern 1: Supervisor Graph

```
         ┌───────────────┐
         │SupervisorNode │
         │  (decides)    │
         └───────┬───────┘
                 │
    ┌────────────┼────────────┐
    ▼            ▼            ▼
┌────────┐  ┌────────┐  ┌────────┐
│Research│  │ Coder  │  │Reviewer│
│  Node  │  │  Node  │  │  Node  │
└────┬───┘  └────┬───┘  └────┬───┘
     └───────────┴───────────┘
                 │
         ┌───────▼───────┐
         │SynthesisNode  │
         │  (combines)   │
         └───────────────┘
```

### Pydantic Graph Implementation

```python
from dataclasses import dataclass, field
from pydantic import BaseModel
from pydantic_ai import Agent
from pydantic_graph import BaseNode, End, Graph, GraphRunContext

# Shared state for all agents
@dataclass
class SupervisorState:
    query: str = ""
    assignments: list[str] = field(default_factory=list)
    agent_outputs: dict[str, str] = field(default_factory=dict)
    final_result: str = ""

# Output schema for supervisor decisions
class SupervisorDecision(BaseModel):
    next_agent: str  # "research", "coder", "reviewer", "synthesize"
    task: str
    reasoning: str

# Specialized agents
research_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=str,
    system_prompt="You are a research specialist. Gather information.",
    instrument=True
)

coder_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=str,
    system_prompt="You are a coding specialist. Write clean code.",
    instrument=True
)

reviewer_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=str,
    system_prompt="You are a code reviewer. Find issues and suggest fixes.",
    instrument=True
)

supervisor_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=SupervisorDecision,
    system_prompt="""
    You are a supervisor managing: research, coder, reviewer.
    Decide which agent should work next based on the task and what's been done.
    When all work is complete, respond with next_agent="synthesize".
    """,
    instrument=True
)

# Supervisor node - orchestrates the workflow
@dataclass
class SupervisorNode(BaseNode[SupervisorState]):
    async def run(self, ctx: GraphRunContext[SupervisorState]) -> 'ResearchNode | CoderNode | ReviewerNode | SynthesisNode':
        # Get supervisor decision
        context = f"""
        Query: {ctx.state.query}
        Completed work: {ctx.state.agent_outputs}
        """

        result = await supervisor_agent.run(context)
        decision = result.output

        ctx.state.assignments.append(decision.next_agent)

        match decision.next_agent:
            case "research": return ResearchNode(task=decision.task)
            case "coder": return CoderNode(task=decision.task)
            case "reviewer": return ReviewerNode(task=decision.task)
            case "synthesize": return SynthesisNode()
            case _: return SynthesisNode()

# Worker nodes
@dataclass
class ResearchNode(BaseNode[SupervisorState]):
    task: str = ""

    async def run(self, ctx: GraphRunContext[SupervisorState]) -> 'SupervisorNode':
        result = await research_agent.run(self.task)
        ctx.state.agent_outputs["research"] = result.output
        return SupervisorNode()

@dataclass
class CoderNode(BaseNode[SupervisorState]):
    task: str = ""

    async def run(self, ctx: GraphRunContext[SupervisorState]) -> 'SupervisorNode':
        result = await coder_agent.run(self.task)
        ctx.state.agent_outputs["coder"] = result.output
        return SupervisorNode()

@dataclass
class ReviewerNode(BaseNode[SupervisorState]):
    task: str = ""

    async def run(self, ctx: GraphRunContext[SupervisorState]) -> 'SupervisorNode':
        result = await reviewer_agent.run(self.task)
        ctx.state.agent_outputs["reviewer"] = result.output
        return SupervisorNode()

@dataclass
class SynthesisNode(BaseNode[SupervisorState]):
    async def run(self, ctx: GraphRunContext[SupervisorState]) -> End[str]:
        synthesis_agent = Agent(
            'anthropic:claude-sonnet-4-20250514',
            output_type=str,
            system_prompt="Synthesize all agent outputs into a final response."
        )

        result = await synthesis_agent.run(
            f"Synthesize: {ctx.state.agent_outputs}"
        )
        ctx.state.final_result = result.output
        return End(result.output)

# Run the supervisor graph
async def run_supervisor_graph(query: str) -> str:
    state = SupervisorState(query=query)
    graph = Graph(nodes=[SupervisorNode, ResearchNode, CoderNode, ReviewerNode, SynthesisNode])
    return await graph.run(SupervisorNode(), state=state)
```

## Pattern 2: Swarm (Peer-to-Peer Handoff)

```
    ┌───────────┐     ┌───────────┐
    │   Alice   │◄───►│    Bob    │
    │   Node    │     │   Node    │
    └─────┬─────┘     └─────┬─────┘
          │                 │
          └────────┬────────┘
                   │
             ┌─────▼─────┐
             │  Charlie  │
             │   Node    │
             └───────────┘
```

### Swarm Implementation

```python
from dataclasses import dataclass, field
from pydantic import BaseModel
from typing import Literal

@dataclass
class SwarmState:
    topic: str = ""
    conversation: list[dict] = field(default_factory=list)
    current_speaker: str = "alice"
    turns: int = 0
    max_turns: int = 6

class SwarmResponse(BaseModel):
    message: str
    handoff_to: Literal["alice", "bob", "charlie", "done"]
    reasoning: str

# Create swarm agents with handoff capability
alice_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=SwarmResponse,
    system_prompt="""
    You are Alice, an expert in research and information gathering.
    Contribute to the conversation and decide who should speak next:
    - bob: for technical implementation details
    - charlie: for review and quality checks
    - done: if the topic is fully addressed
    """,
    instrument=True
)

bob_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=SwarmResponse,
    system_prompt="""
    You are Bob, an expert in technical implementation.
    Contribute to the conversation and decide who should speak next:
    - alice: for more research/information
    - charlie: for review and validation
    - done: if the topic is fully addressed
    """,
    instrument=True
)

charlie_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=SwarmResponse,
    system_prompt="""
    You are Charlie, an expert in review and quality assurance.
    Contribute to the conversation and decide who should speak next:
    - alice: if more information needed
    - bob: if implementation needs work
    - done: if everything is satisfactory
    """,
    instrument=True
)

@dataclass
class AliceNode(BaseNode[SwarmState]):
    async def run(self, ctx: GraphRunContext[SwarmState]) -> 'BobNode | CharlieNode | End[str]':
        context = f"Topic: {ctx.state.topic}\nConversation: {ctx.state.conversation}"
        result = await alice_agent.run(context)

        ctx.state.conversation.append({"speaker": "alice", "message": result.output.message})
        ctx.state.turns += 1

        if result.output.handoff_to == "done" or ctx.state.turns >= ctx.state.max_turns:
            return End(self._summarize(ctx.state.conversation))

        match result.output.handoff_to:
            case "bob": return BobNode()
            case "charlie": return CharlieNode()
            case _: return BobNode()

    def _summarize(self, conversation: list) -> str:
        return "\n".join(f"{c['speaker']}: {c['message']}" for c in conversation)

@dataclass
class BobNode(BaseNode[SwarmState]):
    async def run(self, ctx: GraphRunContext[SwarmState]) -> 'AliceNode | CharlieNode | End[str]':
        context = f"Topic: {ctx.state.topic}\nConversation: {ctx.state.conversation}"
        result = await bob_agent.run(context)

        ctx.state.conversation.append({"speaker": "bob", "message": result.output.message})
        ctx.state.turns += 1

        if result.output.handoff_to == "done" or ctx.state.turns >= ctx.state.max_turns:
            return End(self._summarize(ctx.state.conversation))

        match result.output.handoff_to:
            case "alice": return AliceNode()
            case "charlie": return CharlieNode()
            case _: return CharlieNode()

    def _summarize(self, conversation: list) -> str:
        return "\n".join(f"{c['speaker']}: {c['message']}" for c in conversation)

@dataclass
class CharlieNode(BaseNode[SwarmState]):
    async def run(self, ctx: GraphRunContext[SwarmState]) -> 'AliceNode | BobNode | End[str]':
        context = f"Topic: {ctx.state.topic}\nConversation: {ctx.state.conversation}"
        result = await charlie_agent.run(context)

        ctx.state.conversation.append({"speaker": "charlie", "message": result.output.message})
        ctx.state.turns += 1

        if result.output.handoff_to == "done" or ctx.state.turns >= ctx.state.max_turns:
            return End(self._summarize(ctx.state.conversation))

        match result.output.handoff_to:
            case "alice": return AliceNode()
            case "bob": return BobNode()
            case _: return AliceNode()

    def _summarize(self, conversation: list) -> str:
        return "\n".join(f"{c['speaker']}: {c['message']}" for c in conversation)
```

## Pattern 3: Router Graph

```
              ┌──────────────┐
              │  RouterNode  │
              │ (classifies) │
              └──────┬───────┘
                     │
     ┌───────────────┼───────────────┐
     ▼               ▼               ▼
┌─────────┐    ┌─────────┐    ┌─────────┐
│   SQL   │    │  Code   │    │  Chat   │
│  Node   │    │  Node   │    │  Node   │
└─────────┘    └─────────┘    └─────────┘
```

### Router Implementation

```python
from dataclasses import dataclass
from pydantic import BaseModel
from typing import Literal

@dataclass
class RouterState:
    query: str = ""
    route: str = ""
    result: str = ""

class RouterDecision(BaseModel):
    route: Literal["sql", "code", "chat"]
    confidence: float
    reasoning: str

router_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=RouterDecision,
    system_prompt="""
    Classify the user's intent:
    - sql: Database queries, data analysis
    - code: Programming, debugging
    - chat: General questions, explanations
    """,
    instrument=True
)

@dataclass
class RouterNode(BaseNode[RouterState]):
    async def run(self, ctx: GraphRunContext[RouterState]) -> 'SQLNode | CodeNode | ChatNode':
        result = await router_agent.run(ctx.state.query)
        ctx.state.route = result.output.route

        match result.output.route:
            case "sql": return SQLNode()
            case "code": return CodeNode()
            case "chat": return ChatNode()
            case _: return ChatNode()

@dataclass
class SQLNode(BaseNode[RouterState]):
    async def run(self, ctx: GraphRunContext[RouterState]) -> End[str]:
        sql_agent = Agent(
            'anthropic:claude-sonnet-4-20250514',
            output_type=str,
            system_prompt="You are a SQL expert.",
            instrument=True
        )
        result = await sql_agent.run(ctx.state.query)
        ctx.state.result = result.output
        return End(result.output)

@dataclass
class CodeNode(BaseNode[RouterState]):
    async def run(self, ctx: GraphRunContext[RouterState]) -> End[str]:
        code_agent = Agent(
            'anthropic:claude-sonnet-4-20250514',
            output_type=str,
            system_prompt="You are a coding expert.",
            instrument=True
        )
        result = await code_agent.run(ctx.state.query)
        ctx.state.result = result.output
        return End(result.output)

@dataclass
class ChatNode(BaseNode[RouterState]):
    async def run(self, ctx: GraphRunContext[RouterState]) -> End[str]:
        chat_agent = Agent(
            'anthropic:claude-sonnet-4-20250514',
            output_type=str,
            system_prompt="You are a helpful assistant.",
            instrument=True
        )
        result = await chat_agent.run(ctx.state.query)
        ctx.state.result = result.output
        return End(result.output)
```

## Pattern 4: Pipeline Graph

```
┌─────────┐    ┌──────────┐    ┌──────────┐    ┌─────────┐
│ Extract │ → │ Transform │ → │  Enrich  │ → │  Load   │
│  Node   │    │   Node   │    │   Node   │    │  Node   │
└─────────┘    └──────────┘    └──────────┘    └─────────┘
```

### Pipeline Implementation

```python
from dataclasses import dataclass, field

@dataclass
class PipelineState:
    raw_input: str = ""
    extracted: dict = field(default_factory=dict)
    transformed: dict = field(default_factory=dict)
    enriched: dict = field(default_factory=dict)
    final_output: str = ""

@dataclass
class ExtractNode(BaseNode[PipelineState]):
    async def run(self, ctx: GraphRunContext[PipelineState]) -> 'TransformNode':
        extract_agent = Agent(
            'anthropic:claude-sonnet-4-20250514',
            output_type=dict,
            system_prompt="Extract structured data from raw text."
        )
        result = await extract_agent.run(ctx.state.raw_input)
        ctx.state.extracted = result.output
        return TransformNode()

@dataclass
class TransformNode(BaseNode[PipelineState]):
    async def run(self, ctx: GraphRunContext[PipelineState]) -> 'EnrichNode':
        transform_agent = Agent(
            'anthropic:claude-sonnet-4-20250514',
            output_type=dict,
            system_prompt="Transform and normalize the extracted data."
        )
        result = await transform_agent.run(str(ctx.state.extracted))
        ctx.state.transformed = result.output
        return EnrichNode()

@dataclass
class EnrichNode(BaseNode[PipelineState]):
    async def run(self, ctx: GraphRunContext[PipelineState]) -> 'LoadNode':
        enrich_agent = Agent(
            'anthropic:claude-sonnet-4-20250514',
            output_type=dict,
            system_prompt="Enrich the data with additional context and metadata."
        )
        result = await enrich_agent.run(str(ctx.state.transformed))
        ctx.state.enriched = result.output
        return LoadNode()

@dataclass
class LoadNode(BaseNode[PipelineState]):
    async def run(self, ctx: GraphRunContext[PipelineState]) -> End[str]:
        load_agent = Agent(
            'anthropic:claude-sonnet-4-20250514',
            output_type=str,
            system_prompt="Format the enriched data for final output."
        )
        result = await load_agent.run(str(ctx.state.enriched))
        ctx.state.final_output = result.output
        return End(result.output)
```

## Pattern 5: Debate Graph

```
        ┌─────────────┐
        │  ProNode    │◄───┐
        │ (argues for)│    │
        └──────┬──────┘    │
               │           │
               ▼           │
        ┌─────────────┐    │
        │  ConNode    │────┘
        │(argues against)
        └──────┬──────┘
               │
               ▼
        ┌─────────────┐
        │  JudgeNode  │
        │ (decides)   │
        └─────────────┘
```

### Debate Implementation

```python
from dataclasses import dataclass, field

@dataclass
class DebateState:
    topic: str = ""
    pro_arguments: list[str] = field(default_factory=list)
    con_arguments: list[str] = field(default_factory=list)
    rounds: int = 0
    max_rounds: int = 3
    verdict: str = ""

class DebateArgument(BaseModel):
    argument: str
    strength: float  # 0-1
    rebuttals: list[str]

@dataclass
class ProNode(BaseNode[DebateState]):
    async def run(self, ctx: GraphRunContext[DebateState]) -> 'ConNode':
        pro_agent = Agent(
            'anthropic:claude-sonnet-4-20250514',
            output_type=DebateArgument,
            system_prompt="You argue IN FAVOR of the topic. Be persuasive."
        )

        context = f"""
        Topic: {ctx.state.topic}
        Previous pro arguments: {ctx.state.pro_arguments}
        Opponent's arguments: {ctx.state.con_arguments}
        """

        result = await pro_agent.run(context)
        ctx.state.pro_arguments.append(result.output.argument)
        return ConNode()

@dataclass
class ConNode(BaseNode[DebateState]):
    async def run(self, ctx: GraphRunContext[DebateState]) -> 'ProNode | JudgeNode':
        con_agent = Agent(
            'anthropic:claude-sonnet-4-20250514',
            output_type=DebateArgument,
            system_prompt="You argue AGAINST the topic. Be persuasive."
        )

        context = f"""
        Topic: {ctx.state.topic}
        Opponent's arguments: {ctx.state.pro_arguments}
        Previous con arguments: {ctx.state.con_arguments}
        """

        result = await con_agent.run(context)
        ctx.state.con_arguments.append(result.output.argument)
        ctx.state.rounds += 1

        if ctx.state.rounds >= ctx.state.max_rounds:
            return JudgeNode()
        return ProNode()

@dataclass
class JudgeNode(BaseNode[DebateState]):
    async def run(self, ctx: GraphRunContext[DebateState]) -> End[str]:
        class Verdict(BaseModel):
            winner: str  # "pro" or "con"
            reasoning: str
            key_points: list[str]

        judge_agent = Agent(
            'anthropic:claude-sonnet-4-20250514',
            output_type=Verdict,
            system_prompt="You are an impartial judge. Evaluate arguments fairly."
        )

        debate_summary = f"""
        Topic: {ctx.state.topic}

        PRO Arguments:
        {chr(10).join(f'- {a}' for a in ctx.state.pro_arguments)}

        CON Arguments:
        {chr(10).join(f'- {a}' for a in ctx.state.con_arguments)}
        """

        result = await judge_agent.run(debate_summary)
        ctx.state.verdict = result.output.reasoning

        return End(f"Winner: {result.output.winner}\n{result.output.reasoning}")
```

## State-Based Coordination

All multi-agent patterns share state through `GraphRunContext`:

```python
@dataclass
class MultiAgentState:
    # Shared context
    shared_knowledge: dict = field(default_factory=dict)

    # Agent-specific message histories
    agent_a_messages: list = field(default_factory=list)
    agent_b_messages: list = field(default_factory=list)

    # Coordination metadata
    current_agent: str = ""
    completed_agents: list[str] = field(default_factory=list)
    handoff_reason: str = ""

# Each agent node can read/write shared state
@dataclass
class AgentANode(BaseNode[MultiAgentState]):
    async def run(self, ctx: GraphRunContext[MultiAgentState]) -> 'AgentBNode':
        # Read shared knowledge
        context = ctx.state.shared_knowledge

        # Call agent with its own message history
        result = await agent_a.run(
            str(context),
            message_history=ctx.state.agent_a_messages
        )

        # Update state
        ctx.state.agent_a_messages = result.all_messages()
        ctx.state.shared_knowledge["agent_a_output"] = result.output
        ctx.state.completed_agents.append("agent_a")

        return AgentBNode()
```

## Output Format

```
⚡ SKILL_ACTIVATED: #MLTI-4H7N

## Multi-Agent Graph: [System Name]

### Pattern
[Supervisor / Swarm / Router / Pipeline / Debate]

### Graph Structure
```
[Node A] → [Node B] → [Node C] → End
              ↑           │
              └───────────┘
```

### State Definition
```python
@dataclass
class [System]State:
    query: str = ""
    agent_outputs: dict = field(default_factory=dict)
    ...
```

### Nodes & Agents
| Node | Agent | Role | Transitions To |
|------|-------|------|----------------|
| [NodeName] | [agent_name] | [role] | [next nodes] |

### Files
- `agents/[system]/graph.py`
- `agents/[system]/nodes/[node].py`
- `agents/[system]/agents/[agent].py`
```

## Common Mistakes

- Not using dataclass for state (use @dataclass, not BaseModel)
- Forgetting to update state before returning next node
- Infinite loops (no termination condition)
- Not preserving agent message_history in state
- Too many nodes (overhead)
- Tight coupling between nodes (use state for communication)
- Missing instrument=True on agents (no tracing)
