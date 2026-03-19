---
name: pai-production
description: Use when building production-grade Pydantic AI agents. Covers patterns NOT in other pai-* skills — system prompt re-injection, streaming+tools, guard-rails in code, multi-provider fallback, state injection, deterministic routing. Activates for "production agent", "agent production", "pydantic ai production", "pai production".
chain: pai-audit
---

# PAI Production — Battle-Tested Patterns for Pydantic AI

Patterns learned from building a production AI sales agent (1800+ lines, 520+ tests, 3 LLM providers, SSE streaming, 12 tools). These patterns are NOT covered by other pai-* skills and address critical gaps that only surface in real production.

## When to Use

- Building multi-turn conversational agents
- Agents that need streaming + tool calls
- Agents with deterministic business rules (pricing, validation, routing)
- Agents that talk to multiple LLM providers
- Production agents that need guard-rails, cost tracking, observability
- NOT when: learning Pydantic AI basics (use pai-agent first)

## Critical Pattern 1: System Prompt Re-Injection

### The Problem

`SystemPromptPart` is inserted ONLY in the first `ModelRequest`. On turn 2+, Pydantic AI silently drops it when you pass `message_history`.

```python
# What Pydantic AI generates internally:
# Turn 1:
ModelRequest(parts=[
    SystemPromptPart(content='You are a sales agent...'),  # ← PRESENT
    UserPromptPart(content='Oi, tudo bem?'),
])

# Turn 2 (with message_history):
ModelRequest(parts=[
    UserPromptPart(content='Quero 5 caixas'),  # ← NO system prompt!
])
```

### The Fix: Inject SystemPromptPart Every Turn

```python
from pydantic_ai.messages import ModelMessage, ModelRequest, SystemPromptPart

def build_message_history(
    state: AgentState,
    system_prompt: str | None = None,
) -> list[ModelMessage]:
    """Build history with system prompt re-injected every turn."""
    history: list[ModelMessage] = []

    if system_prompt:
        # Re-inject SystemPromptPart so LLM has full context every turn
        history.append(ModelRequest(parts=[SystemPromptPart(content=system_prompt)]))

    return history
```

Then in your node/service:

```python
# Build dynamic context (changes every turn based on state)
context = build_context(state, fase)

# Build history with system prompt injected
history = build_message_history(state, system_prompt=context)

# Run agent — system prompt is ALWAYS present
result = await agent.run(
    user_message,
    deps=deps,
    message_history=history,
)
```

### Why NOT `@agent.system_prompt`?

`@agent.system_prompt` decorators work for the first call, but when you pass `message_history` (required for multi-turn), Pydantic AI skips its own system prompt injection. You must handle it yourself.

---

## Critical Pattern 2: Conversation History as Context Text

### The Problem

Multi-turn requires conversation history. The naive approach is typed `ModelMessage` pairs:

```python
# NAIVE: Pass previous messages as typed history
result = await agent.run(
    user_message,
    message_history=result1.all_messages(),  # user/model/user/model...
)
```

This breaks when:
1. **Agent initiates first** (proactive) — no preceding user message
2. **Gemini requires strict alternation** — user/model/user/model with NO exceptions
3. **History gets long** — context window fills with raw message objects

### The Fix: Embed History as Text in Context

```python
def build_context(state: AgentState, fase: str) -> str:
    """Build dynamic context with embedded conversation history."""
    ctx = f"""
<situacao>
CLIENTE: {state.cliente_nome} | Segmento: {state.segmento}
FASE: {fase}
CARRINHO: {len(state.carrinho)} itens | R${state.carrinho_valor:.2f}
</situacao>
"""

    # Embed conversation as TEXT (not typed messages)
    if state.messages:
        ctx += "\n<historico>\n"
        for msg in state.messages[-12:]:  # Cap at 6 pairs
            role = "CLIENTE" if msg.role == "user" else "VOCE"
            ctx += f"[{role}]: {msg.content}\n"
        ctx += "</historico>\n"

    ctx += f"\nO CLIENTE DISSE: \"{state.last_user_message}\"\n"
    ctx += "TAREFA: Responda ao que o cliente disse.\n"

    return ctx
```

Then pass ONLY system prompt + user message (always 1 system + 1 user = perfect alternation):

```python
history = [ModelRequest(parts=[SystemPromptPart(content=context)])]

result = await agent.run(
    user_message,  # Single UserPromptPart
    message_history=history,
    deps=deps,
)
```

**Result:** Every provider (Claude, GPT, Gemini) gets exactly:
```
SystemPromptPart (context with embedded history)
UserPromptPart (current message)
```
No alternation issues. No proactive-first issues. Clean.

---

## Critical Pattern 3: Streaming + Signal Tools

### The Problem

Real-time streaming (token-by-token to client) and structured `output_type` are **fundamentally incompatible**:

- **Streaming** = raw text chunks, no schema validation
- **Structured output** = entire response buffered for schema validation
- **You cannot have both simultaneously**

### The Fix: Signal Tools

Tools that **mutate state during streaming** without interrupting the text flow:

```python
from pydantic_ai import Agent, RunContext

agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    deps_type=AgentDeps,
    output_type=str,  # Plain string for streaming
)

# Signal tool — mutates state, LLM keeps streaming text
@agent.tool
async def detectar_objecao(
    ctx: RunContext[AgentDeps],
    tipo: str,
) -> str:
    """Register a client objection. Call when client complains about price, etc.
    The client does NOT see this call — it's internal bookkeeping.
    """
    state = ctx.deps._state
    state.objecoes.append(Objecao(tipo=tipo))
    state.rodadas_negociacao += 1
    return f"Objeção '{tipo}' registrada."

# Signal tool — triggers phase change
@agent.tool
async def solicitar_escalar(
    ctx: RunContext[AgentDeps],
    motivo: str,
) -> str:
    """Escalate to human. Sets flag that changes phase next turn."""
    state = ctx.deps._state
    state.escalar = True
    state.motivo_escalacao = motivo
    return "Escalação registrada. Finalize a conversa com empatia."
```

**Architecture:**
```
Streaming (primary):  text tokens → client sees word-by-word
Signal tools:         mutate state → phase/context changes for next turn
Structured (fallback): only if streaming completely fails
```

### SSE Integration

Tools set **flags** that the SSE layer reads after the LLM finishes:

```python
@agent.tool
async def buscar_produtos(ctx: RunContext[AgentDeps], query: str) -> str:
    results = await ctx.deps.search_fn(query)

    # Set flag for SSE layer (emitted AFTER LLM response)
    state = ctx.deps._state
    object.__setattr__(state, '_search_products_this_turn', True)
    object.__setattr__(state, '_search_product_groups', [{"label": query, "products": results}])

    return f"Encontrados {len(results)} produtos."

# In SSE emission (after LLM response):
if getattr(state, '_search_products_this_turn', False):
    await emit(sse_product_carousel(state._search_product_groups))
```

---

## Critical Pattern 4: Guard-Rails in Code, Not Prompt

### The Problem

LLMs are unreliable at enforcing hard business rules. Prompts like "never go below 5% margin" WILL be violated.

### The Fix: Deterministic Post-Processing

```python
async def run_turn(state, user_message) -> str:
    # 1. LLM generates response (advisory prompt guides, doesn't guarantee)
    response = await run_agent_stream(agent, context, state)

    # 2. CODE enforces hard rules (deterministic, guaranteed)
    response = apply_guard_rails(state, response)

    return response


def apply_guard_rails(state: AgentState, response: str) -> str:
    """Deterministic validation AFTER LLM generates response."""

    # HARD BLOCK: margin below threshold
    if state.carrinho and state.margem_composta < 5.0:
        state.escalar = True
        state.flags_hitl.append("guard-rail: margem < hard block 5%")
        return "Tive um problema com a precificação. Vou passar para o vendedor."

    # FIX: hallucinated prices
    response = sanitize_prices(response, state.carrinho)

    # FIX: forbidden internal terms
    response = sanitize_forbidden_words(response)
    # "margem" → removed, "custo" → removed, "piso ágil" → removed

    # FIX: factual hallucinations
    response = fix_wrong_facts(response)
    # pedido_minimo != R$250 → corrected
    # prazo_credito != 12 dias → corrected

    # CLEAN: markdown for WhatsApp
    response = strip_markdown(response)

    return response
```

### Separation of Concerns

| Layer | Responsibility | Example |
|-------|---------------|---------|
| **Prompt** | Advisory guidance | "Tente manter margem acima de 8.7%" |
| **Tool** | Business logic | `flexibilizar_pedido()` applies ladder |
| **Guard-rail** | Hard enforcement | Code blocks margin < 5%, always |
| **Sanitizer** | Output cleanup | Remove markdown, fix hallucinations |

---

## Critical Pattern 5: Multi-Provider Fallback with Cost Tracking

### The Problem

Single-provider agents fail in production. Rate limits, timeouts, outages.

### The Fix: Per-Node Config + Cascading Fallback

```python
import asyncio
from dataclasses import dataclass

@dataclass
class NodeModelsConfig:
    primary: str        # "anthropic:claude-sonnet-4-20250514"
    fallback_1: str     # "openai:gpt-4o"
    fallback_2: str     # "google-gla:gemini-2.5-flash"

@dataclass
class RoutingConfig:
    timeout_ms: int = 10_000
    max_retries_429: int = 2

# Pricing table for cost tracking
MODEL_PRICING = {
    "claude-sonnet-4-5": {"input": 3.00, "output": 15.00},  # per 1M tokens
    "gpt-4o": {"input": 2.50, "output": 10.00},
    "gemini-2.5-flash": {"input": 0.15, "output": 0.60},
}

async def call_with_fallback(
    agent: Agent,
    context: str,
    node_name: str,
    config: NodeModelsConfig,
    timeout_s: float = 10.0,
    message_history: list | None = None,
    deps: Any = None,
    state: Any = None,
) -> Any:
    """Try primary → fallback_1 → fallback_2 with timeout and 429 retry."""

    candidates = [config.primary, config.fallback_1, config.fallback_2]
    candidates = [m for m in candidates if m]
    last_error = None

    for i, model_id in enumerate(candidates):
        for retry_429 in range(3):  # Max 2 retries on rate limit
            try:
                result = await asyncio.wait_for(
                    agent.run(context, model=model_id,
                              message_history=message_history, deps=deps),
                    timeout=timeout_s,
                )

                # Track usage and cost
                if state and hasattr(result, 'usage'):
                    usage = result.usage()
                    inp = usage.input_tokens or 0
                    out = usage.output_tokens or 0
                    cost = calculate_cost(model_id, inp, out)
                    state.total_tokens += inp + out
                    state.total_cost_usd += cost
                    state.model_used = model_id

                return result

            except TimeoutError:
                break  # Timeout → next provider (don't retry)

            except Exception as e:
                is_429 = "429" in str(e) or "rate_limit" in str(e).lower()
                if is_429 and retry_429 < 2:
                    wait = (retry_429 + 1) * 15  # 15s, 30s backoff
                    await asyncio.sleep(wait)
                    continue
                last_error = e
                break  # Non-retryable → next provider

    # All failed → HITL flag
    if state:
        state.flags_hitl.append(f"all providers failed: {last_error}")
    raise AgentUnavailableError(f"All providers failed for {node_name}")


def calculate_cost(model_id: str, input_tokens: int, output_tokens: int) -> float:
    key = model_id.split(":")[-1] if ":" in model_id else model_id
    pricing = MODEL_PRICING.get(key, {"input": 1.0, "output": 3.0})
    return (input_tokens * pricing["input"] + output_tokens * pricing["output"]) / 1_000_000
```

---

## Critical Pattern 6: Deterministic Phase Routing

### The Problem

LLM-based routing (pai-multi approach) is unreliable for business-critical phase transitions:
- LLM might skip mandatory phases
- LLM might loop between phases
- LLM might not recognize escalation triggers

### The Fix: Code Routes, LLM Executes

```python
from enum import StrEnum

class Fase(StrEnum):
    ABERTURA = "abertura"
    OFERTA = "oferta"
    NEGOCIACAO = "negociacao"
    HANDOFF = "handoff"

def determinar_fase(state: AgentState) -> Fase:
    """Deterministic phase routing. Priority order matters."""

    # Priority 1: Terminal states
    if state.sessao_finalizada or state.escalar:
        return Fase.HANDOFF

    # Priority 2: Max negotiation rounds exceeded
    if state.rodadas_negociacao >= state.max_rodadas:
        state.escalar = True
        state.flags_hitl.append("max rodadas atingido")
        return Fase.HANDOFF

    # Priority 3: First contact
    if not state.perfil_preparado:
        return Fase.ABERTURA

    # Priority 4: Active negotiation
    has_objecoes = any(o.resolucao != "resolvida" for o in state.objecoes)
    if has_objecoes and state.carrinho:
        return Fase.NEGOCIACAO

    # Default
    return Fase.OFERTA
```

Then use the phase to select the **dynamic prompt** (same agent, different instructions):

```python
PROMPTS = {
    Fase.ABERTURA: PROMPT_BASE + PROMPT_ABERTURA,
    Fase.OFERTA: PROMPT_BASE + PROMPT_OFERTA,
    Fase.NEGOCIACAO: PROMPT_BASE + PROMPT_NEGOCIACAO,
    Fase.HANDOFF: PROMPT_BASE + PROMPT_HANDOFF,
}

async def run_turn(state, user_message):
    fase = determinar_fase(state)
    context = build_context(state, fase)  # Dynamic per phase
    system_prompt = PROMPTS[fase]  # Different tools/instructions per phase

    result = await call_with_fallback(
        agent, context, "vendedor", config,
        message_history=build_message_history(state, system_prompt=context),
        deps=deps, state=state,
    )
```

**Single agent, multiple phases, code-routed.** No agent-as-tool overhead, no routing hallucinations.

---

## Critical Pattern 7: Dependency Injection with Callable Fields

### The Problem

Testing agents requires mocking external services (DB, APIs). Standard deps don't support this.

### The Fix: Callable Fields with Defaults

```python
from dataclasses import dataclass, field
from typing import Any, Callable

@dataclass
class AgentDeps:
    """Dependencies with callable fields for testability.

    Default: real implementations (Supabase, APIs).
    Tests: inject mocks by passing different callables.
    """
    # Data access (mockable)
    buscar_produtos_fn: Callable = field(default=real_buscar_produtos)
    buscar_historico_fn: Callable = field(default=real_buscar_historico)
    buscar_substitutos_fn: Callable = field(default=real_buscar_substitutos)

    # Shared resources
    motor: MotorDeCalculo = field(default_factory=MotorDeCalculo)

    # State reference (injected by node before agent.run)
    _state: Any = field(default=None, repr=False)

# Production:
deps = AgentDeps()  # Uses real Supabase functions

# Tests:
deps = AgentDeps(
    buscar_produtos_fn=lambda q: [{"codprod": 1, "nome": "Test", "custo": 10.0}],
    buscar_historico_fn=lambda id: [],
)
```

Tools use deps callables (never import DB directly):

```python
@agent.tool
async def buscar_produtos(ctx: RunContext[AgentDeps], query: str) -> str:
    # Uses injectable callable, not hardcoded DB import
    results = await ctx.deps.buscar_produtos_fn(query)
    return format_results(results)
```

State injection by the node:

```python
# In your node, BEFORE calling agent.run():
deps._state = state  # Tools can access state via ctx.deps._state
```

---

## Critical Pattern 8: Concession Engine (Domain Logic in Code)

### The Problem

Business rules like pricing ladders, discount calculations, and margin enforcement are too complex and critical for LLM reasoning.

### The Fix: Motor de Cálculo (Deterministic Engine)

```python
class ConcessionEngine:
    """Deterministic pricing engine. LLM calls tools, engine calculates."""

    LADDER = [20.0, 15.0, 11.0, 8.7, 8.0, 7.0]  # Composite margin steps
    FLOOR = 6.0   # Agent can't go below
    BLOCK = 5.0   # System blocks the sale

    @staticmethod
    def next_step(current_margin: float, intensity: int = 5) -> float | None:
        """Return next margin step in the ladder.

        Args:
            current_margin: Current composite margin %
            intensity: 0-10 (maps to 50%-100% of step size)

        Returns:
            New target margin, or None if no more room (try substitutes).
        """
        if current_margin <= 7.0:
            return None  # No more room → suggest substitutes

        for rung in ConcessionEngine.LADDER:
            if rung < current_margin:
                return rung

        return None

    @staticmethod
    def calculate_price(custo: float, margem_pct: float) -> float:
        """Calculate sell price from cost and target margin."""
        return round(custo / (1 - margem_pct / 100), 2)

    @staticmethod
    def composite_margin(items: list[CartItem]) -> float:
        """Calculate composite margin across entire order."""
        total_custo = sum(i.custo * i.qty for i in items)
        total_venda = sum(i.preco * i.qty for i in items)
        if total_venda == 0:
            return 0.0
        return round((total_venda - total_custo) / total_venda * 100, 2)
```

The LLM calls `flexibilizar_pedido()` → the tool calls `ConcessionEngine.next_step()` → code enforces the ladder. The LLM never calculates prices directly.

---

## Critical Pattern 9: HITL Flags (Human-In-The-Loop)

Track exceptional events for human review:

```python
@dataclass
class AgentState:
    flags_hitl: list[str] = field(default_factory=list)

    def add_hitl_flag(self, flag: str):
        self.flags_hitl.append(f"{datetime.now().isoformat()} | {flag}")

# Usage in guard-rails:
if margem < HARD_BLOCK:
    state.add_hitl_flag("guard-rail: margem abaixo do hard block")
    state.escalar = True

# Usage in fallback:
if all_providers_failed:
    state.add_hitl_flag("HITL: todos os providers falharam")

# Usage in handoff summary:
def generate_seller_summary(state):
    summary = f"Cliente: {state.cliente_nome}\n"
    if state.flags_hitl:
        summary += "\n⚠️ ALERTAS:\n"
        for flag in state.flags_hitl:
            summary += f"  - {flag}\n"
    return summary
```

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────┐
│                    DETERMINISTIC (Code)                       │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐ │
│  │  Phase    │   │ Context  │   │  Guard-  │   │   SSE    │ │
│  │ Routing  │──▶│ Builder  │   │  Rails   │   │ Emitter  │ │
│  └──────────┘   └────┬─────┘   └────▲─────┘   └────▲─────┘ │
│                      │              │              │         │
│                      ▼              │              │         │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                  AGENTIC (LLM)                          │ │
│  │  ┌──────────┐   ┌──────────┐   ┌──────────┐            │ │
│  │  │ Streaming│   │  Tool    │   │  Signal  │            │ │
│  │  │  Text    │   │  Calls   │   │  Tools   │────────────┤ │
│  │  └──────────┘   └──────────┘   └──────────┘            │ │
│  └─────────────────────────────────────────────────────────┘ │
│                      │                                       │
│                      ▼                                       │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐                │
│  │  Motor   │   │  Cost    │   │  HITL    │                │
│  │ Cálculo  │   │ Tracker  │   │  Flags   │                │
│  └──────────┘   └──────────┘   └──────────┘                │
└─────────────────────────────────────────────────────────────┘
```

**Rule of thumb:** If a business rule has the word "NEVER" or "ALWAYS" — it belongs in code, not prompt.

---

## Production Checklist

```
Architecture:
- [ ] System prompt re-injected every turn via build_message_history()
- [ ] Conversation history embedded as text in context (not typed messages)
- [ ] Phase routing is deterministic code, not LLM decision
- [ ] Guard-rails enforce hard rules AFTER LLM response

Streaming:
- [ ] Primary path is real token streaming (output_type=str)
- [ ] Signal tools mutate state during streaming
- [ ] Structured output is fallback only (if streaming fails)

Resilience:
- [ ] Multi-provider fallback with per-node config
- [ ] Per-provider timeout (asyncio.wait_for)
- [ ] 429 rate limit retry with exponential backoff
- [ ] HITL flags on all-provider failure

Testing:
- [ ] Deps use callable fields (mockable)
- [ ] State injected into deps._state before agent.run()
- [ ] Unit tests mock all external calls via deps
- [ ] E2E tests track token cost per test

Observability:
- [ ] Token tracking per turn (input/output separated)
- [ ] Cost calculation per model (pricing table)
- [ ] Cumulative session cost
- [ ] Model used per turn recorded

Business Logic:
- [ ] Pricing/margin calculations in deterministic engine
- [ ] LLM calls tools → tools call engine → engine returns numbers
- [ ] Guard-rail sanitizes hallucinated prices/facts
- [ ] Forbidden internal terms filtered from output
```

## Relationship to Other pai-* Skills

| Skill | Status | This skill adds |
|-------|--------|----------------|
| pai-agent | ✅ Keep | System prompt re-injection, state injection |
| pai-prompts | ⚠️ Supplement | Advisory vs. enforcement separation |
| pai-tools | ✅ Keep | Callable fields, signal tools pattern |
| pai-multi | ⚠️ Supplement | Deterministic routing alternative |
| pai-api | ⚠️ Supplement | Streaming + signal tools architecture |
| pai-resilience | ⚠️ Supplement | Per-node config, 429 retry, cost tracking |
| pai-test | ✅ Keep | Cost budget tracking |
| pai-scaffold | ✅ Keep | No changes needed |
| pai-deploy | ✅ Keep | No changes needed |

## Common Mistakes

- Using `@agent.system_prompt` and expecting it to persist across turns with `message_history`
- Passing typed `ModelMessage` pairs for conversation history (breaks with Gemini, proactive agents)
- Trying to combine `output_type=MySchema` with real streaming (incompatible)
- Putting hard business rules only in prompts (LLM WILL violate them)
- Using LLM for phase routing in business-critical flows (unreliable)
- Creating new Agent instances per provider in fallback (reuse one Agent, pass `model=`)
- Hardcoding DB calls in tools (use callable fields in deps for testability)
- Not tracking token cost per turn (leads to surprise bills)
- Not setting HITL flags when guard-rails trigger (human reviewers need context)

## Chain Behavior

After ANY code change:
→ AUTOMATICALLY trigger: pai-audit
→ Validate implementation quality against these production patterns
