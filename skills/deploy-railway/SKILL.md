---
name: deploy-railway
description: Use when deploying to Railway, setting up Railway projects. Activates for "Railway", "deploy railway", "railway up", "railway deploy".
chain: none
---

# Deploy Railway

Expert in Railway deployment, configuration, and automation.

## When to Use

- Deploying applications to Railway
- Setting up Railway projects
- Configuring Railway services
- User says: Railway, railway up, deploy to railway
- NOT when: deploying to GCP (use deploy-gcp)

## Railway CLI Essentials

```
┌─────────────────────────────────────────────────────────────────┐
│                    RAILWAY DEPLOYMENT                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   railway login     → Authenticate                             │
│   railway init      → Create new project                       │
│   railway link      → Link to existing project                 │
│   railway up        → Deploy current directory                 │
│   railway logs      → View logs                                │
│   railway variables → Manage env vars                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Deploy Commands

```bash
# Login
railway login

# Link to project
railway link

# Deploy
railway up

# Deploy specific service
railway up --service api

# Deploy to specific environment
railway up --environment production

# Deploy without waiting
railway up --detach

# Redeploy latest
railway redeploy --yes

# View logs
railway logs --service api

# Open dashboard
railway open
```

## Project Configuration

### railway.json
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "npm run build"
  },
  "deploy": {
    "startCommand": "npm start",
    "healthcheckPath": "/health",
    "healthcheckTimeout": 300,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

### Environment Variables
```bash
# Set variable
railway variables set API_KEY=xxx

# Set multiple
railway variables set \
  DATABASE_URL=postgres://... \
  REDIS_URL=redis://...

# From file
railway variables set < .env.production

# View all
railway variables

# Reference other services
DATABASE_URL=${{Postgres.DATABASE_URL}}
REDIS_URL=${{Redis.REDIS_URL}}
```

## Dockerfile Setup

```dockerfile
# Multi-stage build for small images
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 app
USER app

COPY --from=builder --chown=app:nodejs /app/dist ./dist
COPY --from=builder --chown=app:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=app:nodejs /app/package.json ./

EXPOSE 3000
CMD ["node", "dist/main.js"]
```

## Pre-Deploy Commands

```json
// railway.json
{
  "deploy": {
    "startCommand": "npm start",
    "preDeployCommand": "npm run db:migrate"
  }
}
```

For database migrations:
```bash
# Pre-deploy command runs between build and deploy
# Has access to environment variables
# Has access to private network (databases)
# Must exit 0 to proceed
```

## CI/CD Integration

### GitHub Actions
```yaml
name: Deploy to Railway

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    container: ghcr.io/railwayapp/cli:latest
    env:
      RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}

    steps:
      - uses: actions/checkout@v4

      - name: Deploy
        run: railway up --service ${{ vars.SERVICE_NAME }}

      - name: Run migrations
        run: railway run npm run db:migrate
```

### Multiple Environments
```yaml
jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4
      - name: Deploy Staging
        run: |
          npm i -g @railway/cli
          RAILWAY_TOKEN=${{ secrets.RAILWAY_TOKEN_STAGING }} \
          railway up --environment staging

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - name: Deploy Production
        run: |
          npm i -g @railway/cli
          RAILWAY_TOKEN=${{ secrets.RAILWAY_TOKEN_PROD }} \
          railway up --environment production
```

## Service Templates

### Node.js API
```bash
# Initialize
railway init

# Add Postgres
railway add --plugin postgresql

# Set variables
railway variables set \
  NODE_ENV=production \
  DATABASE_URL='${{Postgres.DATABASE_URL}}'

# Deploy
railway up
```

### Python FastAPI
```bash
# Procfile
web: uvicorn main:app --host 0.0.0.0 --port $PORT

# requirements.txt
fastapi
uvicorn[standard]
```

### Full-Stack (Next.js + API)
```
project/
├── frontend/     → Deploy as service "web"
├── backend/      → Deploy as service "api"
└── railway.json
```

```bash
# Deploy frontend
cd frontend && railway up --service web

# Deploy backend
cd backend && railway up --service api

# Link services
railway variables set \
  --service web \
  API_URL='${{api.RAILWAY_PUBLIC_DOMAIN}}'
```

## Database Services

```bash
# Add PostgreSQL
railway add --plugin postgresql

# Add Redis
railway add --plugin redis

# Add MongoDB
railway add --plugin mongodb

# Reference in app
DATABASE_URL=${{Postgres.DATABASE_URL}}
REDIS_URL=${{Redis.REDIS_URL}}
MONGO_URL=${{MongoDB.MONGO_URL}}
```

## Monitoring & Logs

```bash
# Live logs
railway logs -f

# Specific service
railway logs --service api

# With timestamps
railway logs --timestamps

# Deployments
railway deployments

# Status
railway status
```

## Rollback

```bash
# List deployments
railway deployments

# Redeploy specific
railway redeploy --deployment-id <id>

# Quick rollback to previous
railway redeploy --yes
```

## Cost Optimization

```
TIPS:
- Use sleep mode for dev environments
- Set memory limits in railway.json
- Use multi-stage Docker builds
- Enable auto-sleep for staging
- Monitor with railway metrics
```

## Output Format

```
⚡ SKILL_ACTIVATED: #RAIL-5E7Q

## Railway Deployment: [Project Name]

### Services
| Service | Type | Status |
|---------|------|--------|
| api | Docker | ✓ Deployed |
| web | Nixpacks | ✓ Deployed |
| db | PostgreSQL | ✓ Running |

### Environment Variables
- DATABASE_URL: ${{Postgres.DATABASE_URL}}
- API_KEY: [set in dashboard]

### URLs
- Production: https://[project].up.railway.app
- API: https://api-[project].up.railway.app

### Commands Used
```bash
railway link
railway up --service api
railway variables set ...
```
```

## Common Mistakes

- Not using --detach for CI (waits forever)
- Hardcoding URLs (use service references)
- Missing health check endpoint
- Not setting NODE_ENV=production
- Forgetting pre-deploy for migrations
- Not using project tokens in CI
