---
name: agent-resilience
description: Use when implementing error handling, retry logic, fallbacks, circuit breakers for agents. Activates for "resilience", "retry", "fallback", "error handling", "circuit breaker".
---

# Agent Resilience

Expert in building fault-tolerant AI agents with retry, fallback, and circuit breaker patterns.

## When to Use

- Implementing error handling for agents
- Adding retry logic with backoff
- Setting up fallback models/strategies
- User says: resilience, retry, fallback, circuit breaker
- NOT when: building agent logic (use graph-agent)

## Resilience Patterns

```
┌─────────────────────────────────────────────────────────────────┐
│                    RESILIENCE STACK                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. RETRY         → Transient failures                         │
│   2. TIMEOUT       → Hung requests                              │
│   3. FALLBACK      → Primary failure                            │
│   4. CIRCUIT BREAK → Repeated failures                          │
│   5. BULKHEAD      → Isolation                                  │
│   6. RATE LIMIT    → Overload protection                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Pattern 1: Retry with Exponential Backoff

```python
import asyncio
from functools import wraps
from typing import TypeVar, Callable
import random

T = TypeVar("T")

class RetryConfig:
    """Configuration for retry behavior."""
    max_attempts: int = 3
    base_delay: float = 1.0
    max_delay: float = 60.0
    exponential_base: float = 2.0
    jitter: bool = True
    retryable_exceptions: tuple = (TimeoutError, ConnectionError)

def with_retry(config: RetryConfig = RetryConfig()):
    """Decorator for retry with exponential backoff."""
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @wraps(func)
        async def wrapper(*args, **kwargs) -> T:
            last_exception = None

            for attempt in range(config.max_attempts):
                try:
                    return await func(*args, **kwargs)

                except config.retryable_exceptions as e:
                    last_exception = e
                    if attempt < config.max_attempts - 1:
                        delay = min(
                            config.base_delay * (config.exponential_base ** attempt),
                            config.max_delay
                        )
                        if config.jitter:
                            delay *= (0.5 + random.random())

                        await asyncio.sleep(delay)

            raise last_exception

        return wrapper
    return decorator

# Usage
@with_retry(RetryConfig(max_attempts=3))
async def call_llm(prompt: str) -> str:
    """LLM call with automatic retry."""
    return await openai_client.chat.completions.create(...)
```

## Pattern 2: Timeout

```python
import asyncio
from contextlib import asynccontextmanager

class TimeoutError(Exception):
    """Custom timeout error with context."""
    def __init__(self, operation: str, timeout: float):
        self.operation = operation
        self.timeout = timeout
        super().__init__(f"{operation} timed out after {timeout}s")

@asynccontextmanager
async def timeout_context(seconds: float, operation: str = "operation"):
    """Context manager for timeout."""
    try:
        yield await asyncio.wait_for(
            asyncio.sleep(0),  # Placeholder
            timeout=seconds
        )
    except asyncio.TimeoutError:
        raise TimeoutError(operation, seconds)

async def call_with_timeout(
    coro,
    timeout: float,
    operation: str = "LLM call"
):
    """Execute coroutine with timeout."""
    try:
        return await asyncio.wait_for(coro, timeout=timeout)
    except asyncio.TimeoutError:
        raise TimeoutError(operation, timeout)

# Usage
result = await call_with_timeout(
    agent.run("query"),
    timeout=30.0,
    operation="agent_run"
)
```

## Pattern 3: Fallback

```python
from dataclasses import dataclass
from typing import Callable, Any

@dataclass
class FallbackChain:
    """Chain of fallback options."""
    primary: Callable
    fallbacks: list[Callable]
    on_fallback: Callable[[str, Exception], None] | None = None

async def execute_with_fallback(chain: FallbackChain, *args, **kwargs) -> Any:
    """Execute with fallback chain."""
    last_error = None

    # Try primary
    try:
        return await chain.primary(*args, **kwargs)
    except Exception as e:
        last_error = e
        if chain.on_fallback:
            chain.on_fallback("primary", e)

    # Try fallbacks
    for i, fallback in enumerate(chain.fallbacks):
        try:
            return await fallback(*args, **kwargs)
        except Exception as e:
            last_error = e
            if chain.on_fallback:
                chain.on_fallback(f"fallback_{i}", e)

    raise last_error

# Usage: Model fallback
chain = FallbackChain(
    primary=lambda q: gpt4.run(q),
    fallbacks=[
        lambda q: gpt35.run(q),
        lambda q: claude.run(q),
    ],
    on_fallback=lambda name, e: logger.warning(f"{name} failed: {e}")
)

result = await execute_with_fallback(chain, "query")
```

## Pattern 4: Circuit Breaker

```python
from enum import Enum
from dataclasses import dataclass
import time

class CircuitState(Enum):
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Failing, reject requests
    HALF_OPEN = "half_open"  # Testing if recovered

@dataclass
class CircuitBreaker:
    """Circuit breaker for fault tolerance."""
    name: str
    failure_threshold: int = 5
    recovery_timeout: float = 30.0
    half_open_max_calls: int = 3

    state: CircuitState = CircuitState.CLOSED
    failure_count: int = 0
    last_failure_time: float = 0
    half_open_calls: int = 0

    def can_execute(self) -> bool:
        """Check if execution is allowed."""
        if self.state == CircuitState.CLOSED:
            return True

        if self.state == CircuitState.OPEN:
            if time.time() - self.last_failure_time > self.recovery_timeout:
                self.state = CircuitState.HALF_OPEN
                self.half_open_calls = 0
                return True
            return False

        if self.state == CircuitState.HALF_OPEN:
            return self.half_open_calls < self.half_open_max_calls

        return False

    def record_success(self):
        """Record successful execution."""
        if self.state == CircuitState.HALF_OPEN:
            self.half_open_calls += 1
            if self.half_open_calls >= self.half_open_max_calls:
                self.state = CircuitState.CLOSED
                self.failure_count = 0

    def record_failure(self):
        """Record failed execution."""
        self.failure_count += 1
        self.last_failure_time = time.time()

        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN

class CircuitOpenError(Exception):
    """Raised when circuit is open."""
    pass

# Decorator
def circuit_breaker(breaker: CircuitBreaker):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            if not breaker.can_execute():
                raise CircuitOpenError(f"Circuit {breaker.name} is open")

            try:
                result = await func(*args, **kwargs)
                breaker.record_success()
                return result
            except Exception as e:
                breaker.record_failure()
                raise
        return wrapper
    return decorator

# Usage
openai_breaker = CircuitBreaker(name="openai", failure_threshold=5)

@circuit_breaker(openai_breaker)
async def call_openai(prompt: str):
    return await openai.chat.completions.create(...)
```

## Pattern 5: Rate Limiting

```python
import asyncio
from collections import deque
import time

class RateLimiter:
    """Token bucket rate limiter."""

    def __init__(self, rate: float, burst: int):
        self.rate = rate  # tokens per second
        self.burst = burst  # max tokens
        self.tokens = burst
        self.last_update = time.time()
        self._lock = asyncio.Lock()

    async def acquire(self, tokens: int = 1) -> bool:
        """Acquire tokens, waiting if necessary."""
        async with self._lock:
            now = time.time()
            elapsed = now - self.last_update

            # Refill tokens
            self.tokens = min(
                self.burst,
                self.tokens + elapsed * self.rate
            )
            self.last_update = now

            if self.tokens >= tokens:
                self.tokens -= tokens
                return True

            # Wait for tokens
            wait_time = (tokens - self.tokens) / self.rate
            await asyncio.sleep(wait_time)
            self.tokens = 0
            return True

# Usage
limiter = RateLimiter(rate=10, burst=20)  # 10 req/sec, burst of 20

async def rate_limited_call(prompt: str):
    await limiter.acquire()
    return await call_llm(prompt)
```

## Complete Resilient Agent

```python
class ResilientAgent:
    """Agent with full resilience patterns."""

    def __init__(self):
        self.circuit = CircuitBreaker("llm", failure_threshold=5)
        self.rate_limiter = RateLimiter(rate=10, burst=20)
        self.fallback_chain = FallbackChain(
            primary=self._call_gpt4,
            fallbacks=[self._call_gpt35, self._call_claude]
        )

    @with_retry(RetryConfig(max_attempts=3))
    @circuit_breaker(circuit)
    async def _call_gpt4(self, prompt: str) -> str:
        await self.rate_limiter.acquire()
        return await call_with_timeout(
            gpt4.run(prompt),
            timeout=30.0
        )

    async def run(self, prompt: str) -> str:
        """Run with full resilience."""
        try:
            return await execute_with_fallback(
                self.fallback_chain,
                prompt
            )
        except CircuitOpenError:
            # Circuit open, use cached response or graceful degradation
            return await self._graceful_degradation(prompt)

    async def _graceful_degradation(self, prompt: str) -> str:
        """Graceful response when all else fails."""
        return (
            "I'm currently experiencing high demand. "
            "Please try again in a few minutes."
        )
```

## Output Format

```
⚡ SKILL_ACTIVATED: #RSLN-9G3L

## Resilience Setup: [Agent Name]

### Retry Configuration
- Max attempts: 3
- Backoff: Exponential (base 2)
- Jitter: Enabled

### Timeout Configuration
- LLM calls: 30s
- Tool calls: 10s
- Total request: 60s

### Fallback Chain
1. GPT-4 (primary)
2. GPT-3.5 (fallback 1)
3. Claude (fallback 2)

### Circuit Breaker
- Threshold: 5 failures
- Recovery: 30s

### Rate Limits
- Rate: 10 req/s
- Burst: 20

### Files
- `agents/[name]/resilience.py`
```

## Common Mistakes

- No retry on transient failures
- Retry on non-retriable errors (wasted tokens)
- No timeout (requests hang forever)
- No fallback (single point of failure)
- Circuit breaker too sensitive (false opens)
- No rate limiting (API bans)
