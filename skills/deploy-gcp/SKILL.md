---
name: deploy-gcp
description: Use when deploying to Google Cloud Platform, Cloud Run, GCE. Activates for "GCP", "Cloud Run", "gcloud", "Google Cloud", "deploy gcp".
chain: none
---

# Deploy GCP

Expert in Google Cloud Platform deployment, especially Cloud Run.

## When to Use

- Deploying to GCP Cloud Run
- Setting up GCP projects
- Configuring Cloud Build
- User says: GCP, Cloud Run, gcloud, Google Cloud
- NOT when: deploying to Railway (use deploy-railway)

## GCP Quick Reference

```
┌─────────────────────────────────────────────────────────────────┐
│                    GCP DEPLOYMENT OPTIONS                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Cloud Run      → Serverless containers (recommended)         │
│   Cloud Functions → Serverless functions                       │
│   GKE            → Kubernetes (complex apps)                   │
│   GCE            → Virtual machines                            │
│   App Engine     → PaaS (legacy)                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Cloud Run Deployment

### From Source (Simplest)
```bash
# Deploy directly from source
gcloud run deploy SERVICE_NAME \
  --source . \
  --region us-central1 \
  --allow-unauthenticated

# With environment variables
gcloud run deploy api \
  --source . \
  --region us-central1 \
  --set-env-vars "NODE_ENV=production,API_KEY=xxx" \
  --allow-unauthenticated
```

### From Container Image
```bash
# Build and push to Artifact Registry
gcloud builds submit --tag gcr.io/PROJECT_ID/SERVICE_NAME

# Deploy image
gcloud run deploy SERVICE_NAME \
  --image gcr.io/PROJECT_ID/SERVICE_NAME \
  --region us-central1 \
  --platform managed
```

### With Cloud Build
```yaml
# cloudbuild.yaml
steps:
  # Build the container image
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/$_SERVICE_NAME', '.']

  # Push to Container Registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/$_SERVICE_NAME']

  # Deploy to Cloud Run
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: gcloud
    args:
      - 'run'
      - 'deploy'
      - '$_SERVICE_NAME'
      - '--image'
      - 'gcr.io/$PROJECT_ID/$_SERVICE_NAME'
      - '--region'
      - '$_REGION'
      - '--platform'
      - 'managed'
      - '--allow-unauthenticated'

substitutions:
  _SERVICE_NAME: my-service
  _REGION: us-central1

images:
  - 'gcr.io/$PROJECT_ID/$_SERVICE_NAME'
```

## Service Configuration

### service.yaml
```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: my-service
  annotations:
    run.googleapis.com/launch-stage: GA
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/minScale: '0'
        autoscaling.knative.dev/maxScale: '10'
        run.googleapis.com/cpu-throttling: 'false'
    spec:
      containerConcurrency: 80
      timeoutSeconds: 300
      containers:
        - image: gcr.io/PROJECT_ID/SERVICE_NAME
          ports:
            - containerPort: 8080
          resources:
            limits:
              cpu: '1'
              memory: '512Mi'
          env:
            - name: NODE_ENV
              value: production
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: database-url
                  key: latest
```

Deploy with:
```bash
gcloud run services replace service.yaml --region us-central1
```

## Secrets Management

```bash
# Create secret
echo -n "my-secret-value" | gcloud secrets create MY_SECRET --data-file=-

# Grant access to Cloud Run service account
gcloud secrets add-iam-policy-binding MY_SECRET \
  --member="serviceAccount:PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Use in Cloud Run
gcloud run deploy SERVICE_NAME \
  --set-secrets="DATABASE_URL=database-url:latest,API_KEY=api-key:latest"
```

## CI/CD with GitHub Actions

```yaml
name: Deploy to Cloud Run

on:
  push:
    branches: [main]

env:
  PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  SERVICE_NAME: my-service
  REGION: us-central1

jobs:
  deploy:
    runs-on: ubuntu-latest

    permissions:
      contents: read
      id-token: write

    steps:
      - uses: actions/checkout@v4

      - id: auth
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
          service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Configure Docker
        run: gcloud auth configure-docker

      - name: Build and Push
        run: |
          docker build -t gcr.io/$PROJECT_ID/$SERVICE_NAME:$GITHUB_SHA .
          docker push gcr.io/$PROJECT_ID/$SERVICE_NAME:$GITHUB_SHA

      - name: Deploy to Cloud Run
        uses: google-github-actions/deploy-cloudrun@v2
        with:
          service: ${{ env.SERVICE_NAME }}
          region: ${{ env.REGION }}
          image: gcr.io/${{ env.PROJECT_ID }}/${{ env.SERVICE_NAME }}:${{ github.sha }}
```

## Cloud SQL Connection

```bash
# Deploy with Cloud SQL connection
gcloud run deploy SERVICE_NAME \
  --add-cloudsql-instances PROJECT_ID:REGION:INSTANCE_NAME \
  --set-env-vars "DATABASE_URL=postgresql://user:pass@/dbname?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME"
```

## Domain Mapping

```bash
# Map custom domain
gcloud run domain-mappings create \
  --service SERVICE_NAME \
  --domain api.myapp.com \
  --region us-central1

# List mappings
gcloud run domain-mappings list --region us-central1
```

## Traffic Splitting

```bash
# Deploy new revision without traffic
gcloud run deploy SERVICE_NAME \
  --image NEW_IMAGE \
  --no-traffic

# Split traffic (canary)
gcloud run services update-traffic SERVICE_NAME \
  --to-revisions=SERVICE_NAME-00001=90,SERVICE_NAME-00002=10

# Rollback (100% to previous)
gcloud run services update-traffic SERVICE_NAME \
  --to-revisions=SERVICE_NAME-00001=100
```

## Monitoring

```bash
# View logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=SERVICE_NAME" --limit 50

# Create alert
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="High Error Rate" \
  --condition-display-name="Error rate > 1%" \
  --condition-filter='resource.type="cloud_run_revision"'
```

## Cost Optimization

```yaml
# service.yaml optimizations
spec:
  template:
    metadata:
      annotations:
        # Scale to zero when idle
        autoscaling.knative.dev/minScale: '0'
        # Limit max instances
        autoscaling.knative.dev/maxScale: '5'
        # Allow CPU to be throttled (cheaper)
        run.googleapis.com/cpu-throttling: 'true'
        # Use 2nd gen execution environment
        run.googleapis.com/execution-environment: gen2
    spec:
      # Lower resources
      containers:
        - resources:
            limits:
              cpu: '1'
              memory: '256Mi'
```

## Output Format

```
⚡ SKILL_ACTIVATED: #GCP-8F3R

## GCP Deployment: [Service Name]

### Service Details
| Property | Value |
|----------|-------|
| Project | [project-id] |
| Service | [service-name] |
| Region | us-central1 |
| URL | https://[service]-[hash].run.app |

### Configuration
- CPU: 1
- Memory: 512Mi
- Min Instances: 0
- Max Instances: 10

### Secrets
- DATABASE_URL: from Secret Manager
- API_KEY: from Secret Manager

### Commands Used
```bash
gcloud run deploy ...
gcloud secrets create ...
```

### CI/CD
- GitHub Actions workflow created
- Workload Identity configured
```

## Common Mistakes

- Not enabling required APIs
- Missing IAM permissions
- Hardcoding project ID (use $PROJECT_ID)
- Not using Secret Manager for secrets
- Forgetting --allow-unauthenticated for public APIs
- Not configuring Cloud SQL connector properly
