---
name: pai-api
description: Use when building FastAPI endpoints for Pydantic AI agents. Activates for "api agent", "fastapi agent", "endpoint agent", "servir agent", "agent api".
chain: pai-deploy
---

# PAI API

Expert in exposing Pydantic AI agents via FastAPI endpoints following Clean Architecture.

## When to Use

- Creating API endpoints for agents
- Integrating agents with FastAPI
- Building chat/streaming endpoints
- NOT when: building agent logic (use pai-agent)

## Project Structure

```
src/{project}/
├── infrastructure/
│   └── api/
│       ├── main.py           # FastAPI app + lifespan
│       ├── models.py         # Request/Response Pydantic models
│       ├── routes/
│       │   ├── chat.py       # Chat endpoints
│       │   └── health.py     # Health check
│       └── dependencies.py   # FastAPI Depends
├── application/
│   └── chat_service/
│       └── service.py        # Agent orchestration
└── domain/
    └── agents/
        └── chat_agent.py     # Agent definition
```

## Basic Agent Endpoint

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from contextlib import asynccontextmanager
import httpx

from my_project.agents.chat_agent import agent, AgentDeps

# Request/Response models
class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=10000)
    session_id: str | None = None

class ChatResponse(BaseModel):
    response: str
    session_id: str
    usage: dict

# Shared resources via lifespan
@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http_client = httpx.AsyncClient()
    yield
    await app.state.http_client.aclose()

app = FastAPI(title="Agent API", lifespan=lifespan)

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    deps = AgentDeps(
        http_client=app.state.http_client,
        api_key=settings.api_key,
    )
    try:
        result = await agent.run(request.message, deps=deps)
        return ChatResponse(
            response=result.output.response,
            session_id=request.session_id or "new",
            usage=result.usage().model_dump(),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

## Streaming Endpoint

```python
from fastapi.responses import StreamingResponse

@app.post("/chat/stream")
async def chat_stream(request: ChatRequest):
    deps = AgentDeps(http_client=app.state.http_client)

    async def generate():
        async with agent.run_stream(request.message, deps=deps) as stream:
            async for chunk in stream.stream_text():
                yield f"data: {chunk}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")
```

## Conversation with Message History

```python
from pydantic_ai.messages import ModelMessage

sessions: dict[str, list[ModelMessage]] = {}

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    history = sessions.get(request.session_id, [])

    result = await agent.run(
        request.message,
        deps=deps,
        message_history=history,
    )

    sessions[request.session_id] = result.all_messages()

    return ChatResponse(
        response=result.output,
        session_id=request.session_id,
    )
```

## Health Check

```python
@app.get("/health")
async def health():
    return {"status": "healthy", "version": "1.0.0"}
```

## Common Mistakes

- Creating httpx client per request (use lifespan)
- No request validation (use Pydantic models)
- No error handling (use HTTPException)
- Blocking sync calls in async endpoints
- No streaming support for long responses
- Hardcoded config (use BaseSettings)
