---
name: agent-prompt-engineer
description: Use when crafting prompts for graph-based agents, designing structured output schemas for nodes. Activates for "prompt", "system message", "schema output", "instruções agent".
---

# Agent Prompt Engineer (Graph-Specialized)

Expert in crafting effective prompts and structured output schemas for **Pydantic AI Agents inside Graph nodes**.

## When to Use

- Designing agent system prompts for graph nodes
- Creating output_type schemas that match node transitions
- Optimizing prompts for stateful graph execution
- User says: prompt, system message, schema, instruções
- NOT when: building graph structure (use graph-agent)

## Graph-Aware Prompt Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                 GRAPH NODE AGENT PROMPT STACK                   │
├─────────────────────────────────────────────────────────────────┤
│  SYSTEM PROMPT                                                  │
│  ├── Role (what this node's agent does)                        │
│  ├── Graph Position (where in workflow)                        │
│  ├── Expected Output (next node or End)                        │
│  └── State Access (what ctx.state provides)                    │
├─────────────────────────────────────────────────────────────────┤
│  DYNAMIC CONTEXT (from GraphRunContext)                        │
│  ├── ctx.state.* (accumulated state)                           │
│  ├── message_history (conversation)                            │
│  └── Previous node outputs                                     │
├─────────────────────────────────────────────────────────────────┤
│  USER MESSAGE                                                   │
│  └── Current task (from node logic)                            │
└─────────────────────────────────────────────────────────────────┘
```

## Agent-in-Node Pattern

### Basic Structure

```python
from dataclasses import dataclass, field
from pydantic import BaseModel
from pydantic_ai import Agent
from pydantic_graph import BaseNode, End, GraphRunContext

# 1. STATE - shared across all nodes
@dataclass
class WorkflowState:
    user_query: str = ""
    research_results: list[str] = field(default_factory=list)
    agent_messages: list = field(default_factory=list)  # For message_history

# 2. OUTPUT SCHEMA - what agent returns (becomes next node or End value)
class ResearchResult(BaseModel):
    findings: list[str]
    confidence: float
    needs_more_research: bool

# 3. AGENT - with output_type matching what node needs
research_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=ResearchResult,
    system_prompt="""
    You are a research specialist in a multi-step workflow.

    Your role: Gather and synthesize information.
    Your position: After query analysis, before synthesis.
    Your output: Structured research findings.

    Guidelines:
    - Set needs_more_research=true if query is complex
    - Confidence should reflect source quality
    - Findings should be atomic facts
    """,
    instrument=True  # Enable tracing
)

# 4. NODE - calls agent, uses output to decide next node
@dataclass
class ResearchNode(BaseNode[WorkflowState]):
    async def run(self, ctx: GraphRunContext[WorkflowState]) -> 'SynthesisNode | ResearchNode':
        result = await research_agent.run(
            f"Research this topic: {ctx.state.user_query}",
            message_history=ctx.state.agent_messages
        )

        # Update state with message history for continuity
        ctx.state.agent_messages = result.all_messages()
        ctx.state.research_results = result.output.findings

        # Output schema drives node transition
        if result.output.needs_more_research:
            return ResearchNode()  # Loop back
        return SynthesisNode()  # Move forward
```

## System Prompt Patterns for Graph Nodes

### Pattern 1: Position-Aware Prompt

```python
# Agent knows its position in the graph
analyst_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=AnalysisOutput,
    system_prompt="""
    # Role
    You are a Data Analyst in a 4-stage pipeline.

    # Your Position in Workflow
    Stage 1: Data Ingestion (complete)
    Stage 2: **Data Analysis** (YOU ARE HERE)
    Stage 3: Report Generation (next)
    Stage 4: Delivery (final)

    # What You Receive
    - Raw data from ingestion stage
    - User's analysis requirements

    # What You Must Output
    - analyzed_data: processed insights
    - key_metrics: numeric KPIs
    - ready_for_report: bool (false = need more data)

    # Constraints
    - NEVER skip to report generation
    - ALWAYS validate data quality first
    - Flag anomalies for human review
    """
)
```

### Pattern 2: State-Aware Prompt

```python
# Agent uses state context
@dataclass
class ConversationNode(BaseNode[ChatState]):
    async def run(self, ctx: GraphRunContext[ChatState]) -> 'ConversationNode | End[str]':
        # Build context from state
        context = f"""
        Previous topics discussed: {ctx.state.topics}
        User preferences: {ctx.state.preferences}
        Conversation turn: {ctx.state.turn_count}
        """

        result = await chat_agent.run(
            ctx.state.current_message,
            message_history=ctx.state.messages,
            deps=context  # Pass state as dependency
        )

        # Update state
        ctx.state.messages = result.all_messages()
        ctx.state.turn_count += 1

        if result.output.should_end:
            return End(result.output.summary)
        return ConversationNode()
```

### Pattern 3: Decision Node Prompt

```python
# Agent that decides which node comes next
class RouterDecision(BaseModel):
    route: Literal["research", "calculate", "summarize", "end"]
    reasoning: str
    confidence: float

router_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=RouterDecision,
    system_prompt="""
    # Role
    You are a Router Agent that decides the next step in a workflow.

    # Available Routes
    - "research": User needs information lookup
    - "calculate": User needs numerical computation
    - "summarize": User needs content summarization
    - "end": Task is complete

    # Decision Criteria
    1. Analyze user intent
    2. Check what's already been done (from state)
    3. Choose the most appropriate next step

    # Output Format
    - route: one of the valid routes
    - reasoning: why this route (1 sentence)
    - confidence: 0.0-1.0
    """
)

@dataclass
class RouterNode(BaseNode[WorkflowState]):
    async def run(self, ctx: GraphRunContext[WorkflowState]) -> 'ResearchNode | CalculateNode | SummarizeNode | End[str]':
        result = await router_agent.run(
            f"User query: {ctx.state.query}\nCompleted steps: {ctx.state.completed_steps}"
        )

        match result.output.route:
            case "research": return ResearchNode()
            case "calculate": return CalculateNode()
            case "summarize": return SummarizeNode()
            case "end": return End(ctx.state.final_result)
```

## Output Schema Design for Graphs

### Schema That Maps to Node Transitions

```python
from typing import Literal
from pydantic import BaseModel, Field

# Output schema mirrors graph structure
class ProcessingResult(BaseModel):
    """Agent output that drives node transitions."""

    status: Literal["success", "needs_review", "failed"] = Field(
        description="Determines next node: success->next, needs_review->review_node, failed->error_node"
    )

    data: dict = Field(
        description="Processed data to store in state"
    )

    next_action: str | None = Field(
        default=None,
        description="Hint for next node if status=success"
    )

@dataclass
class ProcessNode(BaseNode[State]):
    async def run(self, ctx: GraphRunContext[State]) -> 'NextNode | ReviewNode | ErrorNode':
        result = await process_agent.run(...)

        ctx.state.processed_data = result.output.data

        match result.output.status:
            case "success": return NextNode()
            case "needs_review": return ReviewNode()
            case "failed": return ErrorNode()
```

### Hierarchical Output for Complex Nodes

```python
class SubTask(BaseModel):
    """Individual sub-task in decomposition."""
    id: str
    description: str
    priority: int
    estimated_complexity: Literal["simple", "moderate", "complex"]

class DecompositionOutput(BaseModel):
    """Output for task decomposition node."""

    subtasks: list[SubTask] = Field(
        min_length=1,
        max_length=10,
        description="Decomposed sub-tasks"
    )

    execution_order: list[str] = Field(
        description="Order to execute subtask IDs"
    )

    parallel_groups: list[list[str]] = Field(
        description="Subtasks that can run in parallel"
    )

    requires_human_input: bool = Field(
        description="True if any subtask needs clarification"
    )

decomposition_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=DecompositionOutput,
    system_prompt="""
    You decompose complex tasks into manageable subtasks.

    Rules:
    1. Each subtask must be atomic (single responsibility)
    2. Identify dependencies between subtasks
    3. Group independent subtasks for parallel execution
    4. Flag anything ambiguous for human input

    Output must include execution_order respecting dependencies.
    """
)
```

## Prompt + State Integration

### Using deps for State Context

```python
from dataclasses import dataclass
from pydantic_ai import Agent, RunContext

@dataclass
class NodeDeps:
    """Dependencies injected from GraphRunContext."""
    accumulated_context: str
    previous_results: list[str]
    iteration_count: int

synthesis_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    output_type=SynthesisOutput,
    deps_type=NodeDeps,
    system_prompt="""
    You synthesize information from previous workflow stages.

    Use the provided context to:
    1. Combine findings from all previous steps
    2. Identify patterns and contradictions
    3. Generate actionable conclusions
    """
)

@synthesis_agent.system_prompt
def add_context(ctx: RunContext[NodeDeps]) -> str:
    return f"""

    # Context from Previous Nodes
    {ctx.deps.accumulated_context}

    # Results to Synthesize
    {chr(10).join(f'- {r}' for r in ctx.deps.previous_results)}

    # Iteration
    This is synthesis attempt #{ctx.deps.iteration_count}
    """

@dataclass
class SynthesisNode(BaseNode[WorkflowState]):
    async def run(self, ctx: GraphRunContext[WorkflowState]) -> End[str]:
        deps = NodeDeps(
            accumulated_context=ctx.state.context,
            previous_results=ctx.state.all_results,
            iteration_count=ctx.state.synthesis_attempts
        )

        result = await synthesis_agent.run(
            "Synthesize all findings into final report",
            deps=deps
        )

        return End(result.output.final_report)
```

## Message History Patterns

### Preserving Conversation Across Nodes

```python
@dataclass
class ChatState:
    messages: list = field(default_factory=list)
    context: str = ""

@dataclass
class ChatNode(BaseNode[ChatState]):
    user_input: str

    async def run(self, ctx: GraphRunContext[ChatState]) -> 'ChatNode | End[str]':
        result = await chat_agent.run(
            self.user_input,
            message_history=ctx.state.messages  # Continue conversation
        )

        # IMPORTANT: Update message history in state
        ctx.state.messages = result.all_messages()

        if result.output.conversation_complete:
            return End(result.output.summary)

        return ChatNode(user_input=result.output.follow_up_question)
```

### Multi-Agent Message Passing

```python
@dataclass
class MultiAgentState:
    researcher_messages: list = field(default_factory=list)
    critic_messages: list = field(default_factory=list)
    shared_context: str = ""

# Each agent maintains its own history
@dataclass
class ResearchNode(BaseNode[MultiAgentState]):
    async def run(self, ctx: GraphRunContext[MultiAgentState]) -> 'CriticNode':
        result = await researcher_agent.run(
            ctx.state.shared_context,
            message_history=ctx.state.researcher_messages
        )
        ctx.state.researcher_messages = result.all_messages()
        ctx.state.shared_context = result.output.findings
        return CriticNode()

@dataclass
class CriticNode(BaseNode[MultiAgentState]):
    async def run(self, ctx: GraphRunContext[MultiAgentState]) -> 'ResearchNode | End[str]':
        result = await critic_agent.run(
            f"Review: {ctx.state.shared_context}",
            message_history=ctx.state.critic_messages
        )
        ctx.state.critic_messages = result.all_messages()

        if result.output.approved:
            return End(ctx.state.shared_context)
        return ResearchNode()  # Back to research
```

## Testing Graph Agent Prompts

```python
import pytest
from pydantic_graph import Graph

class TestGraphAgentPrompts:
    """Test prompts produce valid outputs for graph transitions."""

    @pytest.mark.asyncio
    async def test_output_enables_valid_transition(self):
        """Agent output maps to valid next node."""
        result = await router_agent.run("Calculate 2+2")

        # Output should be valid route
        assert result.output.route in ["research", "calculate", "summarize", "end"]
        assert 0 <= result.output.confidence <= 1

    @pytest.mark.asyncio
    async def test_state_preserved_across_nodes(self):
        """Message history preserved through node transitions."""
        graph = Graph(nodes=[ChatNode, SummaryNode])
        state = ChatState()

        result = await graph.run(ChatNode(user_input="Hello"), state=state)

        # Messages should accumulate
        assert len(state.messages) > 0

    @pytest.mark.asyncio
    async def test_deterministic_routing(self):
        """Same input produces consistent routing."""
        results = [await router_agent.run("What is 2+2?") for _ in range(3)]

        # Should consistently route to calculate
        routes = [r.output.route for r in results]
        assert routes.count("calculate") >= 2  # Allow some variation
```

## Output Format

```
⚡ SKILL_ACTIVATED: #PRMT-2E8R

## Graph Agent Prompt: [Node Name]

### System Prompt
```
[Full system prompt with graph position awareness]
```

### Output Schema
```python
class [Name]Output(BaseModel):
    # Fields that map to node transitions
    ...
```

### State Integration
- Uses ctx.state.[fields]: [list]
- Updates ctx.state.[fields]: [list]
- Message history: [yes/no]

### Graph Position
```
[Previous Node] → [THIS NODE] → [Next Nodes]
```

### Test Cases
- [x] Valid transition for success case
- [x] Valid transition for failure case
- [x] State properly updated
- [x] Message history preserved
```

## Common Mistakes

- Not specifying graph position (agent doesn't know its role)
- Output schema doesn't match possible node transitions
- Forgetting to update message_history in state
- Not using deps for state context injection
- Missing instrument=True for tracing
- Output type not matching node return type annotation
