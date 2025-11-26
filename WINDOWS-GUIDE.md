# Complete Windows Deployment Guide

Step-by-step guide for deploying PostgreSQL databases and Python applications across dev, preprod, and prod environments on Windows using PowerShell.

---

## Table of Contents

1. [Prerequisites Setup](#prerequisites-setup)
2. [GCP Account Setup](#gcp-account-setup)
3. [Tool Installation](#tool-installation)
4. [Cluster Setup](#cluster-setup)
5. [Application Deployment](#application-deployment)
6. [Accessing Applications](#accessing-applications)
7. [Cost Management](#cost-management)
8. [Troubleshooting](#troubleshooting)
9. [Cleanup](#cleanup)

---

## Prerequisites Setup

### System Requirements

- Windows 10 or Windows 11
- Administrator access (for some installations)
- Stable internet connection
- At least 2GB free disk space

### Time Requirements

- **Total setup time**: 30-40 minutes
  - GCP account setup: 10 minutes
  - Tool installation: 10 minutes
  - Cluster creation: 15-20 minutes
  - Application deployment: 10-15 minutes

---

## GCP Account Setup

### Step 1: Create GCP Account (10 minutes)

1. **Go to GCP Console**
   - Open: https://console.cloud.google.com
   - Click "Get started for free" or "Try for free"

2. **Sign In**
   - Use your Google account (or create one)
   - Accept the Terms of Service

3. **Set Up Billing**
   - Select your Country
   - Enter billing information (name, address)
   - Enter payment method (credit card or bank account)
   - **Important**: You will NOT be charged during the 90-day free trial
   - Click "Start my free trial"
   - You should see: "You have $300 in free credits for 90 days"

4. **Create a Project**
   - Click the project dropdown (top left, next to "Google Cloud")
   - Click "New Project"
   - Enter project name: e.g., "platform-demo"
   - **Copy your Project ID** - you'll need this later
   - Click "Create"
   - Wait for project creation (takes a few seconds)

5. **Link Billing to Project**
   - Go to: Billing → Account management
   - Click "My Projects" tab
   - Find your project in the list
   - Click the three dots (⋮) on the right
   - Click "Change billing account"
   - Select your billing account
   - Click "Set account"

6. **Verify Billing**
   - Your project should now show the billing account name
   - Status should be "Active"

---

## Tool Installation

### Step 2: Install Google Cloud SDK (5 minutes)

1. **Download Installer**
   - Go to: https://cloud.google.com/sdk/docs/install#windows
   - Click "Download the Google Cloud CLI installer"
   - Choose "Windows 64-bit" (most common)

2. **Run Installer**
   - Run `GoogleCloudSDKInstaller.exe`
   - Follow the installation wizard
   - Accept default installation location
   - Check "Start Cloud SDK Shell" at the end
   - Click "Finish"

3. **Initialize gcloud**
   - A PowerShell window will open automatically
   - Run: `gcloud init`
   - Follow the prompts:
     - Log in to your Google account (browser will open)
     - Select your project
     - Choose default region: `us-central1`

4. **Verify Installation**
   ```powershell
   gcloud version
   ```
   You should see version information.

### Step 3: Install kubectl (2 minutes)

1. **Install via gcloud**
   ```powershell
   gcloud components install kubectl
   ```

2. **Verify Installation**
   ```powershell
   kubectl version --client
   ```

### Step 4: Install Helm (5 minutes)

**Option A: Using Chocolatey (Recommended)**

1. **Install Chocolatey** (if not already installed)
   - Open PowerShell as Administrator
   - Run:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
   iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   ```

2. **Install Helm**
   ```powershell
   choco install kubernetes-helm
   ```

3. **Verify Installation**
   ```powershell
   helm version
   ```

**Option B: Manual Installation**

1. Download from: https://github.com/helm/helm/releases
2. Extract the zip file
3. Move `helm.exe` to `C:\Program Files\helm\`
4. Add to PATH:
   - Search "Environment Variables" in Windows
   - Edit "Path" variable
   - Add `C:\Program Files\helm\`
   - Click OK
5. Restart PowerShell
6. Verify: `helm version`

### Step 5: Install Git (if needed)

1. Download from: https://git-scm.com/download/win
2. Run the installer
3. Use default settings
4. Verify: `git --version`

---

## Cluster Setup

### Step 6: Clone Repository (2 minutes)

```powershell
# Clone the repository
git clone https://github.com/sunkaramallikarjuna369/helmgcppython.git
cd helmgcppython
```

### Step 7: Configure PowerShell (1 minute)

Allow running local scripts:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 8: Set Environment Variables (1 minute)

```powershell
# Set your project ID (use the Project ID you created earlier)
$env:PROJECT_ID = "your-project-id-here"
$env:REGION = "us-central1"

# Configure gcloud
gcloud config set project $env:PROJECT_ID
gcloud config set compute/region $env:REGION
```

### Step 9: Run Setup Script (15-20 minutes)

```powershell
cd scripts
.\00-setup.ps1
```

**What this script does:**
1. Verifies all prerequisites are installed
2. Checks billing is enabled
3. Enables required GCP APIs (Container, Compute)
4. Creates a GKE Autopilot cluster (takes 10-15 minutes)
5. Configures kubectl to access the cluster
6. Verifies cluster is running

**Expected output:**
```
========================================
GKE Cluster Setup for Dev/Preprod/Prod
========================================

Checking prerequisites...
[OK] gcloud CLI is installed
[OK] kubectl is installed
[OK] Helm is installed

Project Configuration:
Project ID: your-project-id
Region: us-central1
Cluster Name: platform-cluster

...

[OK] Cluster created successfully!
[OK] kubectl configured

Setup Complete!
```

---

## Application Deployment

### Step 10: Deploy Applications (10-15 minutes)

```powershell
.\01-deploy.ps1
```

**What this script does:**
1. Adds Bitnami Helm repository
2. Updates Helm chart dependencies (PostgreSQL)
3. Creates three namespaces: dev, preprod, prod
4. Deploys PostgreSQL + Python app to each environment
5. Waits for all pods to be ready
6. Displays deployment summary

**Expected output:**
```
========================================
Deploy Platform to Dev/Preprod/Prod
========================================

[OK] Cluster is accessible
[OK] Bitnami repository added
[OK] Dependencies updated

Creating namespaces...
  [OK] Created namespace: dev
  [OK] Created namespace: preprod
  [OK] Created namespace: prod

Deploying to DEV environment...
[OK] Dev deployment complete

Deploying to PREPROD environment...
[OK] Preprod deployment complete

Deploying to PROD environment...
[OK] Prod deployment complete

Deployment Summary
==================

Environment: dev
Pods:
NAME                              READY   STATUS    RESTARTS   AGE
platform-dev-app-xxx              1/1     Running   0          2m
platform-dev-postgresql-0         1/1     Running   0          2m

Services:
NAME                        TYPE        CLUSTER-IP     PORT(S)
platform-dev-app            ClusterIP   10.x.x.x       8000/TCP
platform-dev-postgresql     ClusterIP   10.x.x.x       5432/TCP
```

---

## Accessing Applications

### Step 11: Access via Port-Forward

**Dev Environment:**

```powershell
# In PowerShell window 1
kubectl port-forward -n dev svc/platform-dev-app 8000:8000
```

Then open in browser: http://localhost:8000

**Preprod Environment:**

```powershell
# In PowerShell window 2
kubectl port-forward -n preprod svc/platform-preprod-app 8001:8000
```

Then open in browser: http://localhost:8001

**Prod Environment:**

```powershell
# In PowerShell window 3
kubectl port-forward -n prod svc/platform-prod-app 8002:8000
```

Then open in browser: http://localhost:8002

### Step 12: Test the API

**View API Documentation:**
- Open: http://localhost:8000/docs
- You'll see Swagger UI with all API endpoints

**Test Health Endpoint:**

```powershell
Invoke-RestMethod -Uri "http://localhost:8000/health" -Method Get
```

**Create a User:**

```powershell
$body = @{
    name = "John Doe"
    email = "john@example.com"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8000/users" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"
```

**List Users:**

```powershell
Invoke-RestMethod -Uri "http://localhost:8000/users" -Method Get
```

**Get User by ID:**

```powershell
Invoke-RestMethod -Uri "http://localhost:8000/users/1" -Method Get
```

**Delete User:**

```powershell
Invoke-RestMethod -Uri "http://localhost:8000/users/1" -Method Delete
```

---

## Cost Management

### Understanding Costs

**With all environments running 24/7:**
- GKE Autopilot compute: ~$50-70/month
- Persistent storage: ~$1/month
- **Total: ~$51-71/month**

**With cost-saving measures:**
- GKE Autopilot compute: ~$25-35/month (prod only)
- Persistent storage: ~$1/month
- **Total: ~$26-36/month**

### Step 13: Scale Down When Not in Use

**Scale down dev and preprod:**

```powershell
.\02-scale.ps1 -Environment all -Action down
```

This will:
- Scale application pods to 0 replicas
- Scale PostgreSQL StatefulSets to 0 replicas
- **Preserve all data** (PersistentVolumes remain)
- Save ~$30-40/month

**Scale back up when needed:**

```powershell
.\02-scale.ps1 -Environment all -Action up
```

**Scale specific environment:**

```powershell
# Scale down dev only
.\02-scale.ps1 -Environment dev -Action down

# Scale up preprod only
.\02-scale.ps1 -Environment preprod -Action up
```

### Step 14: Monitor Costs

1. **Check GCP Billing Dashboard**
   - Go to: https://console.cloud.google.com/billing
   - Click on your billing account
   - View "Credits" section to see remaining free trial credits

2. **Set Up Budget Alerts**
   - Go to: Billing → Budgets & alerts
   - Click "Create Budget"
   - Set budget amount: $50, $100, $150, etc.
   - Set alert thresholds: 50%, 75%, 90%, 100%
   - Add your email for notifications

3. **View Cost Breakdown**
   - Go to: Billing → Reports
   - Filter by: Service, SKU, Project
   - See which services are consuming credits

---

## Troubleshooting

### Issue: PowerShell Execution Policy Error

**Error:**
```
cannot be loaded because running scripts is disabled on this system
```

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: gcloud Not Found

**Error:**
```
gcloud : The term 'gcloud' is not recognized
```

**Solution:**
1. Restart PowerShell
2. If still not working, add to PATH manually:
   - Search "Environment Variables" in Windows
   - Edit "Path" variable
   - Add: `C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin`
   - Restart PowerShell

### Issue: kubectl Not Found

**Error:**
```
kubectl : The term 'kubectl' is not recognized
```

**Solution:**
```powershell
gcloud components install kubectl
# Restart PowerShell
```

### Issue: Cluster Creation Failed

**Error:**
```
ERROR: Failed to create cluster!
```

**Possible causes:**
1. **Billing not enabled**: Check billing at https://console.cloud.google.com/billing
2. **Quota exceeded**: Check quotas at https://console.cloud.google.com/iam-admin/quotas
3. **APIs not enabled**: Run `.\00-setup.ps1` again

### Issue: Pods Not Starting

**Check pod status:**
```powershell
kubectl get pods -n dev
kubectl describe pod <pod-name> -n dev
kubectl logs <pod-name> -n dev
```

**Common causes:**
- **Image pull error**: Wait a few minutes, Autopilot will retry
- **Insufficient resources**: Autopilot will auto-scale nodes
- **Database not ready**: Wait 1-2 minutes for PostgreSQL to start

### Issue: Cannot Connect to Database

**Check database pod:**
```powershell
kubectl get pods -n dev | Select-String postgresql
kubectl logs platform-dev-postgresql-0 -n dev
```

**Verify database is ready:**
```powershell
kubectl exec -it platform-dev-postgresql-0 -n dev -- psql -U devuser -d devdb -c "SELECT 1"
```

### Issue: Port-Forward Connection Refused

**Check service exists:**
```powershell
kubectl get svc -n dev
```

**Check pods are running:**
```powershell
kubectl get pods -n dev
```

**Try different port:**
```powershell
kubectl port-forward -n dev svc/platform-dev-app 9000:8000
# Then access at http://localhost:9000
```

### Issue: Out of Free Credits

**Check remaining credits:**
- Go to: https://console.cloud.google.com/billing
- View "Credits" section

**Reduce costs immediately:**
1. Scale down dev/preprod:
   ```powershell
   .\02-scale.ps1 -Environment all -Action down
   ```
2. Delete unused resources:
   ```powershell
   .\99-cleanup.ps1
   ```

---

## Cleanup

### Remove Applications Only (Keep Cluster)

If you want to keep the cluster but remove applications:

```powershell
.\99-cleanup.ps1
```

When prompted "Delete GKE cluster?", type `no`

This will:
- Uninstall all Helm releases
- Delete all PersistentVolumeClaims
- Delete namespaces (dev, preprod, prod)
- **Keep the GKE cluster** (you can redeploy later)

### Remove Everything (Including Cluster)

To delete everything and stop all charges:

```powershell
.\99-cleanup.ps1
```

When prompted "Delete GKE cluster?", type `yes`

This will:
- Uninstall all Helm releases
- Delete all PersistentVolumeClaims
- Delete namespaces
- **Delete the GKE cluster** (takes 5-10 minutes)

### Verify Cleanup

```powershell
# Check no clusters exist
gcloud container clusters list --project=$env:PROJECT_ID

# Check no persistent disks
gcloud compute disks list --project=$env:PROJECT_ID --filter="name~gke-"
```

Both commands should return empty or "Listed 0 items".

---

## Summary

### Complete Command Sequence

For quick reference, here's the complete sequence:

```powershell
# 1. Clone repository
git clone https://github.com/sunkaramallikarjuna369/helmgcppython.git
cd helmgcppython

# 2. Set environment variables
$env:PROJECT_ID = "your-project-id"
$env:REGION = "us-central1"
gcloud config set project $env:PROJECT_ID

# 3. Run setup
cd scripts
.\00-setup.ps1

# 4. Deploy applications
.\01-deploy.ps1

# 5. Access applications
kubectl port-forward -n dev svc/platform-dev-app 8000:8000
# Open http://localhost:8000

# 6. Scale down when not in use
.\02-scale.ps1 -Environment all -Action down

# 7. Cleanup when done
.\99-cleanup.ps1
```

### Time Breakdown

| Step | Time | Description |
|------|------|-------------|
| GCP Account Setup | 10 min | Create account, enable billing, create project |
| Tool Installation | 10 min | Install gcloud, kubectl, Helm |
| Clone Repository | 2 min | Clone from GitHub |
| Cluster Setup | 15-20 min | Create GKE cluster |
| Application Deployment | 10-15 min | Deploy to all environments |
| **Total** | **47-57 min** | Complete setup |

### Cost Summary

| Scenario | Monthly Cost | Credits Duration |
|----------|--------------|------------------|
| All running 24/7 | $51-71 | 4-6 months |
| With scaling (dev/preprod off) | $26-36 | 8-11 months |
| Cleanup after use | $0 | Full 90 days |

---

## Next Steps

1. **Customize the Application**
   - Edit `charts/platform/templates/app-configmap.yaml`
   - Add your own API endpoints
   - Redeploy with `.\01-deploy.ps1`

2. **Add More Environments**
   - Create `values-staging.yaml`
   - Deploy: `helm install platform-staging . -n staging --values values-staging.yaml`

3. **Set Up CI/CD**
   - Use GitHub Actions
   - Automate deployments on git push

4. **Learn More**
   - Kubernetes: https://kubernetes.io/docs/
   - Helm: https://helm.sh/docs/
   - FastAPI: https://fastapi.tiangolo.com/

---

**Remember: Always run `.\99-cleanup.ps1` when you're done to avoid unnecessary charges!**
