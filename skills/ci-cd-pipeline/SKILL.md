---
name: ci-cd-pipeline
description: Use when setting up CI/CD, GitHub Actions, automated pipelines. Activates for "CI/CD", "GitHub Actions", "pipeline", "workflow", "deploy automation".
chain: none
---

# CI/CD Pipeline

Expert in setting up automated build, test, and deployment pipelines.

## When to Use

- Setting up CI/CD from scratch
- Adding GitHub Actions workflows
- Automating build/test/deploy
- User says: CI/CD, pipeline, GitHub Actions, automate deploy
- NOT when: manual deployment (use deploy-railway or deploy-gcp)

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     CI/CD PIPELINE                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   COMMIT → LINT → TEST → BUILD → DEPLOY-STAGING → DEPLOY-PROD  │
│     │       │       │       │          │              │         │
│     │       │       │       │          │              │         │
│     ▼       ▼       ▼       ▼          ▼              ▼         │
│   trigger  code   unit    docker    auto         manual/        │
│            check  integ   image    deploy        approval       │
│                   e2e                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## GitHub Actions Templates

### Basic CI (Lint + Test)
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci
      - run: npm run lint
      - run: npm run type-check

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci
      - run: npm test -- --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
```

### Python CI
```yaml
# .github/workflows/ci-python.yml
name: Python CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ['3.11', '3.12']

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Install dependencies
        run: |
          pip install uv
          uv pip install -e ".[dev]"

      - name: Lint with Ruff
        run: ruff check .

      - name: Type check with mypy
        run: mypy src/

      - name: Test with pytest
        run: pytest --cov=src --cov-report=xml

      - name: Upload coverage
        uses: codecov/codecov-action@v4
```

### Full CD Pipeline
```yaml
# .github/workflows/cd.yml
name: CD

on:
  push:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}

    steps:
      - uses: actions/checkout@v4

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=
            type=raw,value=latest

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    environment: staging

    steps:
      - name: Deploy to staging
        run: |
          # Railway/GCP/AWS deploy command
          echo "Deploying to staging..."

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://myapp.com

    steps:
      - name: Deploy to production
        run: |
          echo "Deploying to production..."
```

### PR Preview Deployment
```yaml
# .github/workflows/preview.yml
name: Preview

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  deploy-preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy Preview
        id: deploy
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}

      - name: Comment PR
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '🚀 Preview: ${{ steps.deploy.outputs.preview-url }}'
            })
```

## Workflow Patterns

### Matrix Strategy
```yaml
jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        node: [18, 20, 22]
        exclude:
          - os: macos-latest
            node: 18
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
```

### Conditional Jobs
```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying..."
```

### Reusable Workflows
```yaml
# .github/workflows/reusable-deploy.yml
name: Reusable Deploy

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
    secrets:
      deploy-token:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - run: echo "Deploying to ${{ inputs.environment }}"
```

```yaml
# .github/workflows/main.yml
jobs:
  deploy-staging:
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: staging
    secrets:
      deploy-token: ${{ secrets.DEPLOY_TOKEN }}
```

## Secrets Management

```yaml
# Using secrets
env:
  API_KEY: ${{ secrets.API_KEY }}
  DATABASE_URL: ${{ secrets.DATABASE_URL }}

# Using environments
jobs:
  deploy:
    environment: production  # Has its own secrets
    steps:
      - run: echo ${{ secrets.PROD_API_KEY }}
```

## Caching Strategies

```yaml
# Node modules
- uses: actions/setup-node@v4
  with:
    cache: 'npm'

# Python dependencies
- uses: actions/setup-python@v5
  with:
    cache: 'pip'

# Docker layers
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max

# Custom cache
- uses: actions/cache@v4
  with:
    path: ~/.cache/my-tool
    key: ${{ runner.os }}-my-tool-${{ hashFiles('**/lockfile') }}
```

## Branch Protection

```yaml
# Required in GitHub settings
# Settings → Branches → Branch protection rules

Required checks:
  - lint
  - test
  - build

Options:
  ✓ Require pull request reviews (1)
  ✓ Dismiss stale reviews
  ✓ Require status checks to pass
  ✓ Require branches to be up to date
  ✓ Require conversation resolution
```

## Output Format

```
⚡ SKILL_ACTIVATED: #CICD-6D4P

## CI/CD Setup: [Project Name]

### Pipeline Structure
```
commit → lint → test → build → deploy
```

### Workflows Created
| Workflow | Trigger | Jobs |
|----------|---------|------|
| ci.yml | push, PR | lint, test |
| cd.yml | push main | build, deploy |

### Secrets Required
- `DEPLOY_TOKEN` - For deployment
- `CODECOV_TOKEN` - For coverage

### Branch Protection
- Required checks: lint, test
- Reviews required: 1
```

## Common Mistakes

- Not caching dependencies (slow builds)
- Running all jobs sequentially (use parallel)
- No artifact retention policy
- Secrets in logs (use masking)
- No timeout on jobs
- Not using environments for approvals
