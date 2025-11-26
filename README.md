# Simple Kubernetes + Helm Platform for Dev/Preprod/Prod

A simple, cost-effective setup for deploying PostgreSQL databases and Python FastAPI applications across dev, preprod, and prod environments using Kubernetes and Helm on Google Cloud Platform (GCP).

**Optimized to stay well within your $300 GCP free credits!**

---

## What This Provides

- **Three Environments**: Dev, Preprod, and Prod in separate Kubernetes namespaces
- **PostgreSQL Databases**: One database per environment with persistent storage
- **Python FastAPI Applications**: REST API with full CRUD operations
- **Cost-Effective**: Single GKE cluster, small resources, easy scaling to zero
- **Windows-Friendly**: All scripts are PowerShell for Windows users
- **Simple Setup**: 4 scripts to setup, deploy, scale, and cleanup

---

## Architecture

```
GKE Autopilot Cluster (Single Cluster)
├── dev namespace
│   ├── PostgreSQL (5Gi PVC, 256Mi RAM)
│   └── Python App (1 replica, 128Mi RAM)
├── preprod namespace
│   ├── PostgreSQL (5Gi PVC, 256Mi RAM)
│   └── Python App (1 replica, 128Mi RAM)
└── prod namespace
    ├── PostgreSQL (10Gi PVC, 512Mi RAM)
    └── Python App (2 replicas, 128Mi RAM)
```

**Key Design Decisions:**
- **One cluster, three namespaces**: Most cost-effective approach
- **In-cluster PostgreSQL**: No Cloud SQL costs (~$7/month saved per environment)
- **No LoadBalancers**: Use `kubectl port-forward` to avoid ~$18-25/month per LB
- **Small resources**: Minimal CPU/memory requests to reduce costs
- **Scalable to zero**: Scale dev/preprod to zero when not in use

---

## Cost Estimate

**Monthly costs with all environments running 24/7:**
- GKE Autopilot compute: ~$50-70/month
- Persistent storage (3x 5Gi + 1x 10Gi): ~$1/month
- **Total: ~$51-71/month**

**With cost-saving measures (scaling dev/preprod to zero when idle):**
- GKE Autopilot compute: ~$25-35/month (prod only)
- Persistent storage: ~$1/month
- **Total: ~$26-36/month**

**Your $300 free credits will last 8-11 months with cost-saving measures!**

---

## Prerequisites

### Required Tools

1. **Google Cloud SDK (gcloud)**
   - Download: https://cloud.google.com/sdk/docs/install#windows
   - Install and run: `gcloud init`

2. **kubectl**
   - Install: `gcloud components install kubectl`

3. **Helm**
   - Install with Chocolatey: `choco install kubernetes-helm`
   - Or download from: https://helm.sh/docs/intro/install/

4. **GCP Account**
   - Sign up at: https://console.cloud.google.com
   - Enable billing (required for free trial)
   - You get $300 in free credits for 90 days

### Verify Installations

```powershell
gcloud version
kubectl version --client
helm version
```

---

## Quick Start (Windows)

### Step 1: Clone Repository

```powershell
git clone https://github.com/sunkaramallikarjuna369/helmgcppython.git
cd helmgcppython
```

### Step 2: Set Up GCP Project

```powershell
# Set your project ID
$env:PROJECT_ID = "your-project-id"
$env:REGION = "us-central1"

# Configure gcloud
gcloud config set project $env:PROJECT_ID
gcloud config set compute/region $env:REGION
```

### Step 3: Run Setup Script

```powershell
cd scripts
.\00-setup.ps1
```

This will:
- Verify prerequisites
- Enable required GCP APIs
- Create a GKE Autopilot cluster (10-15 minutes)
- Configure kubectl

### Step 4: Deploy Applications

```powershell
.\01-deploy.ps1
```

This will:
- Add Bitnami Helm repository
- Create dev, preprod, prod namespaces
- Deploy PostgreSQL + Python app to each environment (5-10 minutes)

### Step 5: Access Applications

```powershell
# Dev environment
kubectl port-forward -n dev svc/platform-dev-app 8000:8000

# Preprod environment (in another terminal)
kubectl port-forward -n preprod svc/platform-preprod-app 8001:8000

# Prod environment (in another terminal)
kubectl port-forward -n prod svc/platform-prod-app 8002:8000
```

Then open in your browser:
- Dev: http://localhost:8000
- Preprod: http://localhost:8001
- Prod: http://localhost:8002

**API Documentation:** http://localhost:8000/docs (Swagger UI)

---

## API Endpoints

Each environment provides the same REST API:

### Health Check
```
GET /health
```

### Users CRUD
```
GET    /users          - List all users
POST   /users          - Create a new user
GET    /users/{id}     - Get user by ID
DELETE /users/{id}     - Delete user by ID
```

### Example: Create a User

```powershell
# Using PowerShell
$body = @{
    name = "John Doe"
    email = "john@example.com"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8000/users" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"
```

### Example: List Users

```powershell
Invoke-RestMethod -Uri "http://localhost:8000/users" -Method Get
```

---

## Cost-Saving Features

### Scale Down When Not in Use

Scale dev and preprod to zero when you're not using them:

```powershell
# Scale down dev and preprod
.\02-scale.ps1 -Environment all -Action down

# Scale back up when needed
.\02-scale.ps1 -Environment all -Action up
```

**Savings:** ~$30-40/month when dev and preprod are scaled to zero

### What Happens When Scaled Down?

- ✅ **Data is preserved** (PersistentVolumes remain)
- ✅ **No compute costs** (pods are stopped)
- ✅ **Storage costs continue** (~$0.20/month per 5Gi PVC)
- ❌ **Applications are offline** until scaled back up

---

## Cleanup

### Remove Applications Only (Keep Cluster)

```powershell
.\99-cleanup.ps1
# Choose "no" when asked about cluster deletion
```

### Remove Everything (Including Cluster)

```powershell
.\99-cleanup.ps1
# Choose "yes" when asked about cluster deletion
```

**Important:** Always run cleanup when you're done to avoid unnecessary charges!

---

## Detailed Guide

### Script Reference

| Script | Purpose | Time |
|--------|---------|------|
| `00-setup.ps1` | Create GKE cluster and configure environment | 15-20 min |
| `01-deploy.ps1` | Deploy applications to all environments | 10-15 min |
| `02-scale.ps1` | Scale environments up or down | 1-2 min |
| `99-cleanup.ps1` | Remove all resources | 5-15 min |

### Environment Variables

Make these permanent by adding to your PowerShell profile:

```powershell
# Open profile
notepad $PROFILE

# Add these lines
$env:PROJECT_ID = "your-project-id"
$env:REGION = "us-central1"
```

### Monitoring Costs

Check your GCP billing dashboard:
- https://console.cloud.google.com/billing
- View "Credits" section to see remaining free trial credits
- Set up budget alerts to get notified at $50, $100, $150, etc.

---

## Troubleshooting

### Issue: Pods Not Starting

**Check pod status:**
```powershell
kubectl get pods -n dev
kubectl describe pod <pod-name> -n dev
```

**Common causes:**
- Insufficient resources (Autopilot will auto-scale)
- Image pull errors (check image name)
- Database not ready (wait 1-2 minutes)

### Issue: Cannot Connect to Database

**Check database pod:**
```powershell
kubectl get pods -n dev | Select-String postgresql
kubectl logs <postgresql-pod-name> -n dev
```

**Verify connection:**
```powershell
# Port-forward to database
kubectl port-forward -n dev svc/platform-dev-postgresql 5432:5432

# Test connection (requires psql)
psql -h localhost -U devuser -d devdb
```

### Issue: Port-Forward Not Working

**Check service:**
```powershell
kubectl get svc -n dev
```

**Try different port:**
```powershell
kubectl port-forward -n dev svc/platform-dev-app 9000:8000
# Then access at http://localhost:9000
```

### Issue: Out of Credits

**Check remaining credits:**
- Go to: https://console.cloud.google.com/billing
- Click on your billing account
- View "Credits" section

**Reduce costs:**
1. Scale down dev/preprod: `.\02-scale.ps1 -Environment all -Action down`
2. Delete unused resources: `.\99-cleanup.ps1`
3. Consider using smaller resources in values files

---

## Architecture Details

### Helm Chart Structure

```
charts/platform/
├── Chart.yaml              # Chart metadata and dependencies
├── values.yaml             # Default values
├── values-dev.yaml         # Dev overrides
├── values-preprod.yaml     # Preprod overrides
├── values-prod.yaml        # Prod overrides
└── templates/
    ├── secret-db.yaml      # Database credentials
    ├── app-configmap.yaml  # Python application code
    ├── app-deployment.yaml # Application deployment
    └── app-service.yaml    # Application service
```

### Database Connection

The Python app connects to PostgreSQL using environment variables:

```python
DB_HOST = os.getenv("DB_HOST")        # platform-dev-postgresql
DB_PORT = os.getenv("DB_PORT")        # 5432
DB_NAME = os.getenv("DB_NAME")        # devdb
DB_USER = os.getenv("DB_USER")        # devuser
DB_PASSWORD = os.getenv("DB_PASSWORD") # dev_password_123
```

### Storage

Each PostgreSQL instance uses a PersistentVolumeClaim (PVC):
- **Dev/Preprod**: 5Gi standard persistent disk
- **Prod**: 10Gi standard persistent disk
- **Storage Class**: `standard-rwo` (cheapest option on GKE)

---

## Customization

### Change Database Credentials

Edit the values files:

```yaml
# values-dev.yaml
database:
  name: mydb
  username: myuser
  password: my_secure_password
```

Then redeploy:

```powershell
cd charts/platform
helm upgrade platform-dev . -n dev --values values-dev.yaml
```

### Change Resource Limits

Edit the values files:

```yaml
# values-prod.yaml
app:
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi

postgresql:
  primary:
    resources:
      requests:
        cpu: 250m
        memory: 512Mi
```

### Add More Environments

1. Create a new values file: `values-staging.yaml`
2. Create namespace: `kubectl create namespace staging`
3. Deploy: `helm install platform-staging . -n staging --values values-staging.yaml`

---

## Security Notes

- **Credentials**: Stored in Kubernetes Secrets (base64 encoded)
- **Network**: All services use ClusterIP (internal only)
- **Access**: Use `kubectl port-forward` for temporary access
- **Production**: Change default passwords in `values-prod.yaml`

**For production use, consider:**
- Using Google Secret Manager for credentials
- Implementing network policies
- Adding authentication to the API
- Using Cloud SQL with private IP
- Implementing backup strategies

---

## Next Steps

1. **Customize the Application**: Modify `app-configmap.yaml` to add your own API endpoints
2. **Add More Services**: Deploy additional applications to the same namespaces
3. **Set Up CI/CD**: Use GitHub Actions to automate deployments
4. **Monitor Costs**: Set up billing alerts in GCP Console
5. **Learn More**: Explore Kubernetes and Helm documentation

---

## Support

- **GCP Documentation**: https://cloud.google.com/docs
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Helm Documentation**: https://helm.sh/docs/
- **FastAPI Documentation**: https://fastapi.tiangolo.com/

---

## License

This project is provided as-is for educational purposes.

---

**Remember to run `.\99-cleanup.ps1` when you're done to avoid unnecessary charges!**
