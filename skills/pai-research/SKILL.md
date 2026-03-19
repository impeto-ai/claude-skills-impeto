---
name: pai-research
description: Use when researching AI agent patterns, comparing frameworks, exploring Pydantic AI capabilities. Activates for "pesquisar agent", "agent patterns", "comparar frameworks", "pydantic ai docs".
chain: pai-agent
---

# PAI Research

WebSearch + context7 specialist for Pydantic AI research. Always search before building.

## When to Use

- Researching agent architectures
- Finding latest Pydantic AI patterns
- Comparing approaches before building
- NOT when: building agents (use pai-agent)
- CHAIN: → pai-agent (after research)

## Research Process

```
1. UNDERSTAND    → What problem are we solving?
2. CONTEXT7      → Fetch latest Pydantic AI docs
3. WEBSEARCH     → Find production patterns, examples
4. SYNTHESIZE    → Compare options, recommend approach
5. CHAIN         → Pass context to pai-agent
```

## Always Start with context7

```
Tool: mcp__context7__resolve-library-id
Library: pydantic-ai

Tool: mcp__context7__query-docs
Library: /pydantic/pydantic-ai
Query: [specific topic]
```

## WebSearch Queries

```
# Latest patterns
"Pydantic AI agent production patterns 2025"
"Pydantic AI multi-agent delegation example"
"Pydantic AI structured output best practices"

# Comparisons
"Pydantic AI vs LangGraph 2025"
"Pydantic AI vs CrewAI comparison"

# Production
"Pydantic AI FastAPI deployment"
"Pydantic AI testing strategies mock"
"Pydantic AI cost optimization"
```

## Output Format

```
## PAI Research: [Topic]

### Documentation (context7)
- [Key finding from docs]
- [Key finding from docs]

### Web Research
- [Query] → [Finding]
- [Query] → [Finding]

### Recommended Approach
**[Recommendation]** because:
1. [Reason from docs]
2. [Reason from research]

### Relevant Code Examples
[code from docs/research]

### Questions Before Building
1. [Question]?

→ CHAIN: Ready for pai-agent
```

## Common Mistakes

- Building without researching first
- Using outdated patterns (always check context7)
- Single source research (use multiple)
- Ignoring trade-offs
