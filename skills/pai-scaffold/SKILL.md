---
name: pai-scaffold
description: Use when creating new Pydantic AI agent projects, restructuring existing projects, or adding new agents. Activates for "scaffold agent", "novo projeto agent", "new agent project", "estrutura agent", "cookiecutter agent", "reestruturar agent".
chain: pai-agent
---

# PAI Scaffold

Scaffolds new or restructures existing Pydantic AI projects following Clean Architecture (domain/application/infrastructure).

## When to Use

- Creating a new agent project from scratch
- **Restructuring an existing project** to follow Clean Architecture
- Adding a new agent to an existing project
- NOT when: modifying agent logic (use pai-agent)

## Decision Flow

```
Project exists?
│
├─ NO → Mode 1: New Project (scaffold completo)
│
├─ YES → Has Clean Architecture structure (domain/application/infrastructure)?
│   │
│   ├─ YES → Mode 3: Add Agent (só adicionar agent novo)
│   │
│   └─ NO → Mode 2: Restructure (migrar para Clean Architecture)
```

**IMPORTANT:** NEVER skip restructuring. If the project exists but doesn't follow Clean Architecture, you MUST use Mode 2 to reorganize before building agents.

## Target Structure

```
{project_name}/
├── src/{project_slug}/
│   ├── __init__.py
│   ├── config.py                 # BaseSettings
│   ├── deps.py                   # Shared @dataclass dependencies
│   ├── types.py                  # Annotated reusable types
│   │
│   ├── domain/
│   │   ├── __init__.py
│   │   ├── exceptions.py         # Custom exceptions
│   │   ├── agents/               # Agent definitions
│   │   │   ├── __init__.py
│   │   │   └── {agent_name}.py   # Agent + output schema
│   │   ├── tools/                # Shared tools
│   │   │   ├── __init__.py
│   │   │   └── {tool_name}.py
│   │   ├── prompts/              # Prompt templates
│   │   │   └── __init__.py
│   │   └── memory/               # Memory abstractions
│   │       └── __init__.py
│   │
│   ├── application/
│   │   ├── __init__.py
│   │   └── chat_service/         # Service layer
│   │       ├── __init__.py
│   │       └── service.py
│   │
│   └── infrastructure/
│       ├── __init__.py
│       ├── api/
│       │   ├── __init__.py
│       │   ├── main.py           # FastAPI app
│       │   └── models.py         # Request/Response models
│       ├── db/                   # Database implementations
│       │   └── __init__.py
│       └── monitoring/           # Observability
│           └── __init__.py
│
├── tests/
│   ├── __init__.py
│   ├── conftest.py               # Shared fixtures
│   ├── test_agents/
│   ├── test_tools/
│   └── test_api/
│
├── .env.example
├── .gitignore
├── .python-version               # 3.12
├── Dockerfile
├── docker-compose.yaml
├── Makefile
├── pyproject.toml
└── README.md
```

## Mode 1: New Project (from scratch)
When project doesn't exist yet:

1. Create directory structure above
2. Generate pyproject.toml with pydantic-ai, fastapi, uvicorn, httpx
3. Generate Dockerfile with uv
4. Generate docker-compose.yaml
5. Generate .env.example
6. Generate Makefile (dev, test, lint, docker)
7. Generate config.py with BaseSettings
8. Generate deps.py with base @dataclass
9. Generate main.py with FastAPI + lifespan
10. Generate conftest.py with fixtures

## Mode 2: Restructure Existing Project
When project exists but does NOT follow Clean Architecture:

### Step 1: Audit current structure
1. Map ALL existing files (agents, tools, services, configs, tests)
2. Identify what each file does and where it belongs in Clean Architecture
3. Present a migration plan to the user:

```
MIGRATION PLAN:
Current                          → Target
─────────────────────────────────────────────
src/agent.py                     → src/{slug}/domain/agents/main_agent.py
src/tools.py                     → src/{slug}/domain/tools/
src/prompts.py                   → src/{slug}/domain/prompts/
src/api.py                       → src/{slug}/infrastructure/api/main.py
src/models.py (request/response) → src/{slug}/infrastructure/api/models.py
src/models.py (output schemas)   → src/{slug}/domain/agents/{name}.py
src/db.py                        → src/{slug}/infrastructure/db/
src/config.py                    → src/{slug}/config.py
tests/                           → tests/ (reorganize by layer)

NEW FILES NEEDED:
+ src/{slug}/deps.py             (@dataclass dependencies)
+ src/{slug}/domain/exceptions.py
+ src/{slug}/application/{service}/service.py
+ src/{slug}/infrastructure/monitoring/__init__.py
```

### Step 2: Execute migration
1. Create the Clean Architecture directory structure
2. Move existing code to correct locations (preserve git history with `git mv`)
3. Update all imports
4. Create missing files (deps.py, exceptions.py, service layer)
5. Apply fixes:
   - `os.environ` → `BaseSettings`
   - `BaseModel` deps → `@dataclass` deps
   - Missing `instrument=True` → add to all agents
   - pip requirements → `pyproject.toml` with uv
6. Verify the app still runs after restructuring

### Step 3: Fill gaps
1. Add Dockerfile if missing
2. Add Makefile if missing
3. Add docker-compose.yaml if missing
4. Add .env.example if missing
5. Add test structure if missing

**CRITICAL:** Do NOT delete or rewrite agent logic. Only MOVE and REORGANIZE. The business logic stays intact.

## Mode 3: Add Agent (in existing Clean Architecture project)
When project already follows Clean Architecture:

1. Create `domain/agents/{name}.py` with Agent + output schema
2. Create `domain/tools/{name}_tools.py` if tools needed
3. Create `tests/test_agents/test_{name}.py`
4. Update application service if needed

## Agent Template

```python
# domain/agents/{name}.py
from dataclasses import dataclass
from pydantic import BaseModel, Field
from pydantic_ai import Agent, RunContext

from ..deps import BaseDeps


class {Name}Output(BaseModel):
    """Output schema for {name} agent."""
    response: str = Field(min_length=1)
    confidence: float = Field(ge=0.0, le=1.0)


{name}_agent = Agent(
    'anthropic:claude-sonnet-4-20250514',
    deps_type=BaseDeps,
    output_type={Name}Output,
    system_prompt='You are a {description}.',
    instrument=True,
)
```

## Config Template

```python
# config.py
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # LLM
    openai_api_key: str = ""
    anthropic_api_key: str = ""

    # App
    app_env: str = "development"
    log_level: str = "INFO"
    port: int = 8000

    model_config = {"env_file": ".env"}


settings = Settings()
```

## Deps Template

```python
# deps.py
from dataclasses import dataclass
import httpx


@dataclass
class BaseDeps:
    """Base dependencies shared across agents."""
    http_client: httpx.AsyncClient
```

## Rules

- Always use Clean Architecture (domain/application/infrastructure)
- 1 agent per file in domain/agents/
- Shared tools in domain/tools/
- @dataclass for deps (never BaseModel)
- BaseSettings for config (never os.environ)
- uv as package manager (never pip)
- instrument=True on all agents

## Chain Behavior

After scaffolding:
→ CHAIN: pai-agent (start building the agent)
