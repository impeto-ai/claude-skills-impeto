---
name: docker-optimizer
description: Use when optimizing Dockerfiles, reducing image size, improving build times. Activates for "Docker", "Dockerfile", "container", "image size", "docker build".
chain: none
---

# Docker Optimizer

Expert in Dockerfile optimization, multi-stage builds, and container best practices.

## When to Use

- Optimizing Docker images
- Reducing image size
- Speeding up builds
- User says: Docker, Dockerfile, container, image size
- NOT when: deploying containers (use deploy-railway or deploy-gcp)

## Optimization Priorities

```
┌─────────────────────────────────────────────────────────────────┐
│                    DOCKER OPTIMIZATION                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. IMAGE SIZE    → Smaller = faster deploys, lower costs     │
│   2. BUILD TIME    → Cache layers effectively                  │
│   3. SECURITY      → Minimal attack surface                    │
│   4. REPRODUCIBILITY → Deterministic builds                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Multi-Stage Build Patterns

### Node.js
```dockerfile
# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 3: Production
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# Security: non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 app
USER app

# Copy only what's needed
COPY --from=deps --chown=app:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=app:nodejs /app/dist ./dist
COPY --from=builder --chown=app:nodejs /app/package.json ./

EXPOSE 3000
CMD ["node", "dist/main.js"]
```

### Python
```dockerfile
# Stage 1: Build
FROM python:3.12-slim AS builder

WORKDIR /app
RUN pip install --no-cache-dir uv

COPY pyproject.toml uv.lock ./
RUN uv pip install --system --no-cache -r pyproject.toml

COPY . .

# Stage 2: Production
FROM python:3.12-slim AS runner
WORKDIR /app

# Security: non-root user
RUN useradd --create-home --shell /bin/bash app
USER app

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /app .

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Go
```dockerfile
# Stage 1: Build
FROM golang:1.22-alpine AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/server

# Stage 2: Minimal runtime
FROM scratch
COPY --from=builder /app/server /server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

EXPOSE 8080
ENTRYPOINT ["/server"]
```

## Layer Optimization

### Bad (Cache Invalidation)
```dockerfile
# Every code change invalidates npm install cache
COPY . .
RUN npm install
RUN npm run build
```

### Good (Optimized Caching)
```dockerfile
# Dependencies change less often than code
COPY package*.json ./
RUN npm ci

# Code changes don't invalidate dependencies
COPY . .
RUN npm run build
```

### Combine RUN Commands
```dockerfile
# Bad: Multiple layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get clean

# Good: Single layer + cleanup
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

## Size Reduction Techniques

### Use Alpine Base
```dockerfile
# Bad: 1GB+
FROM node:20

# Good: ~150MB
FROM node:20-alpine

# Better: ~50MB (distroless)
FROM gcr.io/distroless/nodejs20-debian12
```

### .dockerignore
```
# .dockerignore
node_modules
npm-debug.log
.git
.gitignore
.env*
*.md
docs/
tests/
coverage/
.vscode/
.idea/
__pycache__/
*.pyc
.pytest_cache/
dist/
build/
```

### Remove Build Dependencies
```dockerfile
# Install, use, then remove build deps
RUN apk add --no-cache --virtual .build-deps \
      gcc \
      musl-dev \
      python3-dev && \
    pip install --no-cache-dir -r requirements.txt && \
    apk del .build-deps
```

## Security Best Practices

### Non-Root User
```dockerfile
# Create user
RUN addgroup --system --gid 1001 app && \
    adduser --system --uid 1001 --ingroup app app

# Set ownership
COPY --chown=app:app . .

# Switch to user
USER app
```

### Read-Only Filesystem
```dockerfile
# In docker-compose or run command
docker run --read-only --tmpfs /tmp myapp
```

### No Secrets in Image
```dockerfile
# Bad: Secret in image layer
COPY .env .
ENV API_KEY=secret123

# Good: Runtime secrets
# Pass via docker run -e or compose secrets
```

### Scan for Vulnerabilities
```bash
# Using Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image myapp:latest

# Using Docker Scout
docker scout cves myapp:latest
```

## Build Optimization

### BuildKit Features
```dockerfile
# Enable BuildKit
# DOCKER_BUILDKIT=1 docker build .

# Cache mounts (don't download deps each build)
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# Secret mounts (don't leak secrets)
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm ci
```

### Parallel Builds
```dockerfile
# Build multiple stages in parallel
FROM node:20-alpine AS frontend-builder
COPY frontend/ .
RUN npm run build

FROM python:3.12-slim AS backend-builder
COPY backend/ .
RUN pip install .

FROM nginx:alpine AS final
COPY --from=frontend-builder /app/dist /usr/share/nginx/html
COPY --from=backend-builder /app /app
```

## Health Checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

## Compose Optimization

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      cache_from:
        - myapp:latest
      args:
        - BUILDKIT_INLINE_CACHE=1
    image: myapp:latest

  # Development with hot reload
  app-dev:
    build:
      target: deps  # Stop at deps stage
    volumes:
      - .:/app
      - /app/node_modules  # Prevent overwrite
    command: npm run dev
```

## Size Comparison

| Base Image | Size |
|------------|------|
| node:20 | ~1GB |
| node:20-slim | ~250MB |
| node:20-alpine | ~150MB |
| distroless/nodejs | ~50MB |
| scratch (Go) | ~10MB |

## Output Format

```
⚡ SKILL_ACTIVATED: #DOCK-2G5S

## Docker Optimization: [Image Name]

### Before/After
| Metric | Before | After |
|--------|--------|-------|
| Image Size | 1.2GB | 150MB |
| Build Time | 5m | 1m |
| Layers | 15 | 8 |

### Optimizations Applied
1. Multi-stage build
2. Alpine base image
3. Layer caching optimization
4. .dockerignore added
5. Non-root user

### Security Improvements
- ✓ Non-root user
- ✓ No secrets in image
- ✓ Minimal packages

### Dockerfile
```dockerfile
[optimized Dockerfile]
```
```

## Common Mistakes

- Using `latest` tag (not reproducible)
- Not using .dockerignore
- Installing dev dependencies in production
- Running as root
- Not cleaning up in same layer
- Copying entire context before installing deps
