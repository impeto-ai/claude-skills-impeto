---
name: pai-deploy
description: Use when deploying Pydantic AI agents to production. Activates for "deploy agent", "docker agent", "ci agent", "production agent", "deploy pydantic".
chain: none
---

# PAI Deploy

Expert in deploying Pydantic AI agents to production with Docker, CI/CD, and uv.

## When to Use

- Dockerizing agent applications
- Setting up CI/CD for agent projects
- Deploying to production
- NOT when: building agent logic (use pai-agent)

## Dockerfile (uv + Python 3.12)

```dockerfile
FROM python:3.12-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Install dependencies first (cache layer)
COPY uv.lock pyproject.toml README.md ./
RUN uv sync --frozen --no-cache --no-dev

# Copy source
COPY src/ src/

# Run
EXPOSE 8000
CMD ["uv", "run", "uvicorn", "src.my_project.infrastructure.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## docker-compose.yaml

```yaml
services:
  agent-api:
    build: .
    ports:
      - "8000:8000"
    env_file:
      - .env
    networks:
      - agent-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  agent-network:
    driver: bridge
```

## .env.example

```bash
# LLM Providers
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=...

# Application
APP_ENV=production
LOG_LEVEL=INFO
PORT=8000
```

## pyproject.toml

```toml
[project]
name = "my-agent"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "pydantic-ai>=1.0.0",
    "fastapi>=0.115.0",
    "uvicorn>=0.34.0",
    "httpx>=0.28.0",
    "pydantic-settings>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.24",
    "coverage>=7.0",
    "ruff>=0.8.0",
]

[tool.ruff]
line-length = 120
select = ["E", "W", "F", "I", "B", "UP"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
```

## GitHub Actions CI

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.12", "3.13"]
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
      - run: uv sync --locked --all-extras
      - run: uv run ruff check .
      - run: uv run pytest --cov -v
```

## Config with BaseSettings

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    openai_api_key: str = ""
    anthropic_api_key: str = ""
    app_env: str = "development"
    log_level: str = "INFO"
    port: int = 8000

    model_config = {"env_file": ".env"}

settings = Settings()
```

## Makefile

```makefile
.PHONY: dev test lint docker

dev:
	uv run uvicorn src.my_project.infrastructure.api.main:app --reload

test:
	uv run pytest --cov -v

lint:
	uv run ruff check . --fix
	uv run ruff format .

docker:
	docker compose up --build

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
```

## Production Checklist

```
- [ ] Dockerfile with uv (not pip)
- [ ] .env.example with all required vars
- [ ] Health check endpoint
- [ ] CI pipeline (lint + test)
- [ ] No secrets in Docker image
- [ ] Graceful shutdown handling
- [ ] Logging configured (structured JSON)
- [ ] Error tracking (Sentry or similar)
```

## Common Mistakes

- Using pip instead of uv (slower, no lockfile)
- Secrets in Dockerfile or git
- No health check endpoint
- No CI pipeline
- Missing .env.example
- No graceful shutdown
