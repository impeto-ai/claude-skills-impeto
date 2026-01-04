---
name: agent-prompt-engineer
description: Use when crafting prompts for agents, designing structured output schemas. Activates for "prompt", "system message", "schema output", "instruções agent".
---

# Agent Prompt Engineer

Expert in crafting effective prompts and structured output schemas for AI agents.

## When to Use

- Designing agent system prompts
- Creating structured output schemas
- Optimizing prompt performance
- User says: prompt, system message, schema, instruções
- NOT when: building agent logic (use graph-agent)

## Prompt Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      AGENT PROMPT STACK                         │
├─────────────────────────────────────────────────────────────────┤
│  SYSTEM PROMPT                                                  │
│  ├── Role Definition                                            │
│  ├── Capabilities & Constraints                                 │
│  ├── Output Format Instructions                                 │
│  └── Tool Usage Guidelines                                      │
├─────────────────────────────────────────────────────────────────┤
│  DYNAMIC CONTEXT                                                │
│  ├── Retrieved Information                                      │
│  ├── Previous Actions                                           │
│  └── Current State                                              │
├─────────────────────────────────────────────────────────────────┤
│  USER MESSAGE                                                   │
│  └── Current Task/Query                                         │
└─────────────────────────────────────────────────────────────────┘
```

## System Prompt Template

```python
SYSTEM_PROMPT = """
# Role
You are {role_name}, an AI assistant specialized in {domain}.

# Capabilities
You CAN:
- {capability_1}
- {capability_2}
- {capability_3}

You CANNOT:
- {constraint_1}
- {constraint_2}

# Available Tools
{tool_descriptions}

# Output Format
Always respond in the following JSON structure:
```json
{output_schema_example}
```

# Guidelines
1. {guideline_1}
2. {guideline_2}
3. {guideline_3}

# Examples
{few_shot_examples}
"""
```

## Prompt Patterns

### Pattern 1: Role-First

```python
system_prompt = """
# Role
You are a Senior Data Analyst with expertise in SQL and Python.
You analyze data, find patterns, and provide actionable insights.

# Your Approach
1. Understand the question fully before analyzing
2. Use SQL for data queries, Python for complex analysis
3. Always validate your findings before presenting
4. Explain your reasoning clearly

# Output Format
Provide your analysis as:
- Summary (2-3 sentences)
- Key Findings (bullet points)
- Recommendations (actionable steps)
- Confidence Level (high/medium/low)
"""
```

### Pattern 2: Constraint-Heavy

```python
system_prompt = """
# Task
Answer customer support queries about our product.

# Constraints
- NEVER reveal internal processes or system details
- NEVER make promises about features not in documentation
- NEVER provide medical, legal, or financial advice
- ALWAYS refer complex issues to human support
- MAXIMUM response length: 200 words

# Tone
- Professional but friendly
- Empathetic to customer frustration
- Clear and direct

# Escalation Triggers
Escalate to human if:
- Customer is upset (3+ negative messages)
- Request involves refunds > $100
- Technical issue not in knowledge base
"""
```

### Pattern 3: Few-Shot Examples

```python
system_prompt = """
# Task
Extract structured information from text.

# Examples

Input: "John Smith, 35, works at Google as a software engineer"
Output:
```json
{
  "name": "John Smith",
  "age": 35,
  "company": "Google",
  "role": "software engineer"
}
```

Input: "The CEO, Sarah Johnson, announced quarterly earnings"
Output:
```json
{
  "name": "Sarah Johnson",
  "age": null,
  "company": null,
  "role": "CEO"
}
```

# Instructions
Extract person information from the input. Use null for missing fields.
"""
```

### Pattern 4: Chain-of-Thought

```python
system_prompt = """
# Task
Solve complex problems step by step.

# Process
1. <understanding>
   Restate the problem in your own words.
   Identify key information and constraints.
   </understanding>

2. <planning>
   Break down into sub-problems.
   Identify which tools to use.
   </planning>

3. <execution>
   Solve each sub-problem.
   Show your work.
   </execution>

4. <verification>
   Check your answer.
   Consider edge cases.
   </verification>

5. <answer>
   Provide final answer with confidence level.
   </answer>
"""
```

## Structured Output Design

### Basic Schema

```python
from pydantic import BaseModel, Field
from typing import Literal

class AgentResponse(BaseModel):
    """Standard agent response schema."""

    thought: str = Field(
        ...,
        description="Agent's reasoning process",
        min_length=10
    )

    action: Literal["respond", "use_tool", "ask_clarification"] = Field(
        ...,
        description="What action to take"
    )

    response: str | None = Field(
        default=None,
        description="Response to user (if action=respond)"
    )

    tool_call: dict | None = Field(
        default=None,
        description="Tool to call (if action=use_tool)"
    )
```

### Discriminated Unions

```python
from typing import Literal, Annotated
from pydantic import BaseModel, Field

class SuccessResponse(BaseModel):
    status: Literal["success"] = "success"
    data: dict
    confidence: float = Field(ge=0, le=1)

class ErrorResponse(BaseModel):
    status: Literal["error"] = "error"
    error_code: str
    message: str
    recoverable: bool

class PendingResponse(BaseModel):
    status: Literal["pending"] = "pending"
    next_action: str
    estimated_steps: int

AgentOutput = Annotated[
    SuccessResponse | ErrorResponse | PendingResponse,
    Field(discriminator="status")
]
```

### Nested Schemas for Complex Output

```python
class ReasoningStep(BaseModel):
    """Single step in agent reasoning."""
    step_number: int
    thought: str
    action_taken: str | None
    observation: str | None

class ToolUsage(BaseModel):
    """Record of tool usage."""
    tool_name: str
    input: dict
    output: dict
    duration_ms: int

class AgentTrace(BaseModel):
    """Complete agent execution trace."""
    query: str
    reasoning: list[ReasoningStep]
    tools_used: list[ToolUsage]
    final_answer: str
    total_tokens: int
    total_time_ms: int
```

## Prompt Optimization Techniques

### 1. Clear Delimiters

```python
# Use consistent delimiters
prompt = """
<context>
{retrieved_context}
</context>

<task>
{user_query}
</task>

<format>
Respond in JSON format.
</format>
"""
```

### 2. Explicit Formatting

```python
# Tell model exactly what to output
prompt = """
Output ONLY a JSON object with these exact keys:
- "answer": string (your response)
- "confidence": number between 0 and 1
- "sources": array of strings

Do NOT include any text before or after the JSON.
Do NOT use markdown code blocks.
"""
```

### 3. Negative Examples

```python
# Show what NOT to do
prompt = """
# Bad Example (DO NOT do this)
"I think the answer might be 42, but I'm not sure..."

# Good Example (DO this)
{"answer": "42", "confidence": 0.95, "reasoning": "Based on..."}
"""
```

## Testing Prompts

```python
import pytest
from pydantic import ValidationError

class TestAgentPrompts:
    """Test prompt produces valid outputs."""

    @pytest.mark.asyncio
    async def test_output_matches_schema(self, agent):
        """Agent output matches expected schema."""
        result = await agent.run("Test query")

        # Should not raise
        AgentResponse.model_validate(result)

    @pytest.mark.asyncio
    async def test_handles_edge_cases(self, agent):
        """Agent handles edge cases gracefully."""
        edge_cases = [
            "",  # Empty
            "a" * 10000,  # Very long
            "SELECT * FROM users; DROP TABLE users;",  # Injection
        ]

        for case in edge_cases:
            result = await agent.run(case)
            assert result.status in ["success", "error"]
```

## Output Format

```
⚡ SKILL_ACTIVATED: #PRMT-2E8R

## Prompt Design: [Agent Name]

### System Prompt
```
[Full system prompt]
```

### Output Schema
```python
class [Name]Output(BaseModel):
    ...
```

### Key Design Decisions
1. [Decision 1]: [Rationale]
2. [Decision 2]: [Rationale]

### Test Cases
- [x] Standard query
- [x] Edge cases
- [x] Malicious input
```

## Common Mistakes

- Vague role definitions (be specific)
- No output format instructions (inconsistent outputs)
- Missing constraints (agent goes off-rails)
- Too many examples (token waste)
- Not testing edge cases
- Hardcoding values that should be dynamic
