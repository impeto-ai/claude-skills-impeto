---
name: agent-tracing-langfuse
description: Use when implementing observability, tracing, or monitoring for AI agents. Activates for "tracing", "langfuse", "observability", "monitoring agent", "trace spans".
chain: agent-audit-graph
---

# Agent Tracing with Langfuse v3+

Expert in implementing production-grade observability for Pydantic AI agents using **Langfuse v3+**. Covers traces, generations, spans, sessions, and cost tracking.

## When to Use

- Adding observability to agents
- Debugging agent behavior in production
- Tracking costs and latency
- User says: tracing, langfuse, observability, monitoring
- CHAIN: → agent-audit-graph (after tracing implemented)
- NOT when: general logging (use standard logging)

## Langfuse v3 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    LANGFUSE v3 HIERARCHY                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   TRACE      → Container principal (1 por request)              │
│      │         Criado por @observe() no endpoint                │
│      │                                                          │
│      ├── GENERATION → Chamada LLM (tokens, custo, model)        │
│      │                 start_as_current_generation()            │
│      │                                                          │
│      ├── SPAN        → Operação genérica (API, DB, etc)         │
│      │                 start_as_current_span()                  │
│      │                                                          │
│      └── SCORE       → Avaliação de qualidade                   │
│                        langfuse.score()                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start (5 Steps)

### Step 1: Install Langfuse v3+

```bash
pip install "langfuse>=3.0.0"
```

### Step 2: Environment Variables

```bash
# .env
LANGFUSE_PUBLIC_KEY=pk-lf-xxx
LANGFUSE_SECRET_KEY=sk-lf-xxx
LANGFUSE_HOST=https://us.cloud.langfuse.com  # ou https://eu.cloud.langfuse.com
```

### Step 3: @observe no Endpoint (Cria Trace Pai)

```python
from langfuse import observe

@app.post("/search")
@observe(name="product_search_api")  # ← Cria trace automaticamente
async def search_product(request: SearchRequest):
    result = await process_search(request.query)
    return result
```

### Step 4: Capturar trace_id para Propagar

```python
from langfuse import observe, get_client

@observe(name="product_search_api")
async def search_product(request: SearchRequest):
    # Captura trace_id do contexto atual
    trace_id = None
    try:
        langfuse = get_client()
        trace_id = langfuse.get_current_trace_id()
    except Exception:
        pass  # Fallback se Langfuse não disponível

    # Passa trace_id para funções internas
    result = await run_search(request.query, trace_id=trace_id)
    return result
```

### Step 5: Criar Generation para Chamadas LLM

```python
from langfuse import get_client

async def call_llm(prompt: str, trace_id: str | None):
    """Chamada LLM com tracing manual."""

    if trace_id:
        langfuse = get_client()

        with langfuse.start_as_current_generation(
            name="llm.analyze_products",
            model="claude-sonnet-4-20250514",
            trace_context={"trace_id": trace_id},  # ← Liga ao trace pai
            input={"prompt_preview": prompt[:500]},
            metadata={"step": "analysis"},
        ) as generation:

            # Executa chamada LLM
            result = await agent.run(prompt)

            # Atualiza com output e tokens
            usage = result.usage()
            generation.update(
                output=result.output.model_dump() if hasattr(result.output, 'model_dump') else str(result.output),
                usage_details={
                    "input": usage.request_tokens or 0,
                    "output": usage.response_tokens or 0,
                },
            )

            return result.output
    else:
        # Sem tracing
        result = await agent.run(prompt)
        return result.output
```

## Estrutura no Dashboard

```
product_search_api [TRACE] ← criado pelo @observe
├── Latency: 5.73s
├── Cost: $0.000503
│
└── llm.analyze_products [GENERATION] ← criado por start_as_current_generation
    ├── Model: claude-sonnet-4-20250514
    ├── Input: {prompt_preview, ...}
    ├── Output: {analysis, reasoning, ...}
    ├── Tokens: 3,812 → 304 (4,116 total)
    └── Cost: $0.000503
```

## Conceitos Principais

| Conceito | O que faz | Como criar |
|----------|-----------|------------|
| **Trace** | Container principal (1 por request) | `@observe()` no endpoint |
| **Generation** | Chamada LLM com tokens/custo | `start_as_current_generation()` |
| **Span** | Operação genérica (API, DB) | `start_as_current_span()` |
| **trace_id** | ID para ligar filhos ao pai | `get_client().get_current_trace_id()` |

## Spans para Operações Não-LLM

```python
from langfuse import get_client

async def fetch_external_api(product_ids: list[int], trace_id: str | None):
    """API call com tracing."""

    if trace_id:
        langfuse = get_client()

        with langfuse.start_as_current_span(
            name="api.fetch_stock",
            trace_context={"trace_id": trace_id},
            input={"product_ids": product_ids},
        ) as span:
            result = await external_api.get_stock(product_ids)

            span.update(
                output={"items_found": len(result)},
                metadata={"api_version": "v2"}
            )

            return result
    else:
        return await external_api.get_stock(product_ids)
```

## Pydantic AI Integration

### Global Instrumentation (Auto-trace todas as chamadas)

```python
from pydantic_ai import Agent

# Instrumenta TODOS os agents automaticamente
Agent.instrument_all()

# Agora todas as chamadas são traced
agent = Agent('anthropic:claude-sonnet-4-20250514')
result = await agent.run("Hello!")  # Auto-traced
```

### Per-Agent Instrumentation

```python
# Só este agent é traced
traced_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    instrument=True
)

# Este NÃO é traced
untraced_agent = Agent('anthropic:claude-sonnet-4-20250514')
```

### Combinando @observe + Agent.instrument_all()

```python
from langfuse import observe, get_client
from pydantic_ai import Agent

Agent.instrument_all()

research_agent = Agent('anthropic:claude-sonnet-4-20250514', output_type=ResearchOutput)

@observe(name="research_workflow")
async def research_endpoint(query: str):
    """Endpoint com trace pai + generations automáticas."""

    trace_id = get_client().get_current_trace_id()

    # Agent.instrument_all() cria generations automaticamente
    # E elas são linkadas ao trace pai via contexto
    result = await research_agent.run(query)

    return result.output
```

## Graph Agent Tracing

### Tracing em Nodes do Pydantic Graph

```python
from dataclasses import dataclass, field
from pydantic_graph import BaseNode, End, GraphRunContext
from pydantic_ai import Agent
from langfuse import observe, get_client

Agent.instrument_all()

@dataclass
class WorkflowState:
    query: str = ""
    trace_id: str | None = None
    results: list[str] = field(default_factory=list)

@dataclass
class ResearchNode(BaseNode[WorkflowState]):
    async def run(self, ctx: GraphRunContext[WorkflowState]) -> 'SynthesisNode':
        # Usa trace_id do state para criar span do node
        if ctx.state.trace_id:
            langfuse = get_client()

            with langfuse.start_as_current_span(
                name="node.research",
                trace_context={"trace_id": ctx.state.trace_id},
                input={"query": ctx.state.query},
            ) as span:
                # Agent call é auto-traced e linkado
                result = await research_agent.run(ctx.state.query)
                ctx.state.results = result.output.findings

                span.update(output={"findings_count": len(ctx.state.results)})

        else:
            result = await research_agent.run(ctx.state.query)
            ctx.state.results = result.output.findings

        return SynthesisNode()

# Iniciar graph com trace_id
@observe(name="graph_workflow")
async def run_graph(query: str):
    trace_id = get_client().get_current_trace_id()

    state = WorkflowState(query=query, trace_id=trace_id)
    graph = Graph(nodes=[ResearchNode, SynthesisNode])

    return await graph.run(ResearchNode(), state=state)
```

### Estrutura de Trace para Graphs

```
graph_workflow [TRACE]
├── node.research [SPAN]
│   └── anthropic:claude-sonnet-4-20250514 [GENERATION]
│       ├── Tokens: 500 → 200
│       └── Cost: $0.002
├── node.synthesis [SPAN]
│   └── anthropic:claude-sonnet-4-20250514 [GENERATION]
│       ├── Tokens: 800 → 300
│       └── Cost: $0.003
└── Total Cost: $0.005
```

## Session & User Tracking

```python
from langfuse import observe, get_client

@observe(name="chat_endpoint")
async def chat(user_id: str, session_id: str, message: str):
    """Chat com tracking de user e session."""

    langfuse = get_client()

    # Atualiza trace com user/session
    langfuse.update_current_trace(
        user_id=user_id,
        session_id=session_id,
        tags=["chat", "production"],
        metadata={"app_version": "1.2.3"}
    )

    result = await chat_agent.run(message)
    return result.output
```

## Evaluations & Scoring

```python
from langfuse import get_client

async def run_with_evaluation(query: str, trace_id: str):
    """Executa e avalia qualidade."""

    result = await agent.run(query)

    # Adiciona score ao trace
    langfuse = get_client()
    langfuse.score(
        trace_id=trace_id,
        name="relevance",
        value=0.95,
        comment="Alta relevância para a query"
    )

    langfuse.score(
        trace_id=trace_id,
        name="user_feedback",
        value=1,  # 1 = positivo, 0 = negativo
        data_type="BOOLEAN"
    )

    return result.output
```

## Cost Tracking Manual

```python
from langfuse import get_client

# Pricing por modelo (por 1K tokens)
PRICING = {
    "claude-sonnet-4-20250514": {"input": 0.003, "output": 0.015},
    "gpt-4o": {"input": 0.005, "output": 0.015},
    "gemini-2.0-flash": {"input": 0.0001, "output": 0.0004},
}

async def tracked_llm_call(prompt: str, model: str, trace_id: str):
    langfuse = get_client()

    with langfuse.start_as_current_generation(
        name=f"llm.{model}",
        model=model,
        trace_context={"trace_id": trace_id},
        input={"prompt": prompt[:500]},
    ) as generation:

        result = await agent.run(prompt)
        usage = result.usage()

        # Calcula custo
        input_cost = (usage.request_tokens / 1000) * PRICING[model]["input"]
        output_cost = (usage.response_tokens / 1000) * PRICING[model]["output"]

        generation.update(
            output=str(result.output),
            usage_details={
                "input": usage.request_tokens,
                "output": usage.response_tokens,
            },
            metadata={
                "cost_input": input_cost,
                "cost_output": output_cost,
                "cost_total": input_cost + output_cost,
            }
        )

        return result.output
```

## Production Patterns

### Sampling para Alto Volume

```python
import random
from langfuse import observe

SAMPLE_RATE = 0.1  # Trace 10% dos requests

@observe(enabled=lambda: random.random() < SAMPLE_RATE)
async def high_volume_endpoint(request: str):
    """Só faz trace de 10% dos requests."""
    return await agent.run(request)
```

### Error Tracking

```python
from langfuse import observe, get_client

@observe(name="safe_agent_call")
async def safe_agent_call(prompt: str):
    """Agent call com error tracking."""

    try:
        result = await agent.run(prompt)

        get_client().update_current_observation(
            level="DEFAULT",
            status_message="Success"
        )

        return result.output

    except Exception as e:
        get_client().update_current_observation(
            level="ERROR",
            status_message=str(e),
            metadata={
                "error_type": type(e).__name__,
                "error_message": str(e)
            }
        )
        raise
```

### Flush para Serverless

```python
from langfuse import get_client

async def lambda_handler(event: dict):
    """Lambda handler com flush."""

    try:
        result = await run_agent(event["input"])
        return {"statusCode": 200, "body": result}
    finally:
        # CRÍTICO: Flush antes da função terminar
        get_client().flush()
```

## Helper Class Completa

```python
from dataclasses import dataclass
from langfuse import observe, get_client
from typing import Any

@dataclass
class LangfuseTracer:
    """Helper para tracing consistente."""

    trace_id: str | None = None

    @classmethod
    def from_current_context(cls) -> "LangfuseTracer":
        """Cria tracer do contexto atual."""
        try:
            trace_id = get_client().get_current_trace_id()
        except Exception:
            trace_id = None
        return cls(trace_id=trace_id)

    def generation(self, name: str, model: str, **kwargs):
        """Context manager para LLM generation."""
        if not self.trace_id:
            return nullcontext()

        return get_client().start_as_current_generation(
            name=name,
            model=model,
            trace_context={"trace_id": self.trace_id},
            **kwargs
        )

    def span(self, name: str, **kwargs):
        """Context manager para span genérico."""
        if not self.trace_id:
            return nullcontext()

        return get_client().start_as_current_span(
            name=name,
            trace_context={"trace_id": self.trace_id},
            **kwargs
        )

    def score(self, name: str, value: float, **kwargs):
        """Adiciona score ao trace."""
        if not self.trace_id:
            return

        get_client().score(
            trace_id=self.trace_id,
            name=name,
            value=value,
            **kwargs
        )

# Uso
@observe(name="my_endpoint")
async def my_endpoint(query: str):
    tracer = LangfuseTracer.from_current_context()

    with tracer.generation("llm.research", "claude-sonnet-4-20250514", input={"query": query}) as gen:
        result = await agent.run(query)
        gen.update(output=str(result.output))

    tracer.score("quality", 0.9)

    return result.output
```

## Checklist

### Setup
- [ ] `pip install "langfuse>=3.0.0"`
- [ ] Env vars: `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `LANGFUSE_HOST`
- [ ] `@observe()` no endpoint principal
- [ ] `get_client().get_current_trace_id()` para propagar

### Production
- [ ] Sampling configurado para alto volume
- [ ] `flush()` em serverless
- [ ] Error tracking implementado
- [ ] User/session tracking
- [ ] Cost tracking verificado

### Debug
- [ ] Trace aparece no dashboard
- [ ] Generations linkadas ao trace pai
- [ ] Tokens e custos calculados
- [ ] Scores registrados

## Output Format

```
⚡ SKILL_ACTIVATED: #TRAC-7K4M

## Tracing: [Component]

### Setup
```python
from langfuse import observe, get_client

@observe(name="endpoint")
async def endpoint():
    trace_id = get_client().get_current_trace_id()
    ...
```

### Trace Structure
```
endpoint [TRACE]
├── operation [SPAN]
└── llm_call [GENERATION]
```

### Implementation
- [ ] @observe no endpoint
- [ ] trace_id propagado
- [ ] Generations para LLM calls
- [ ] Spans para operações

→ CHAIN: Ready for agent-audit-graph
```

## Common Mistakes

- Usar `LANGFUSE_BASE_URL` em vez de `LANGFUSE_HOST` (v3)
- Não propagar `trace_id` para funções filhas
- Esquecer `trace_context={"trace_id": trace_id}` em generations
- Não chamar `flush()` em serverless
- Tracing 100% em produção de alto volume
- Usar `langfuse_context` (v2) em vez de `get_client()` (v3)
- Não atualizar generation com `usage_details`
