# Deployment Script - Deploy Applications to Dev/Preprod/Prod
# Run this script from PowerShell on Windows
#
# This script deploys the platform (PostgreSQL + Python app) to three
# separate namespaces: dev, preprod, and prod

# ============================================================================
# STEP 1: Validate Environment
# ============================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploy Platform to Dev/Preprod/Prod" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if kubectl is configured
$nodes = kubectl get nodes 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: kubectl is not configured or cluster is not accessible!" -ForegroundColor Red
    Write-Host "Please run .\00-setup.ps1 first" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Cluster is accessible" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 2: Add Bitnami Helm Repository
# ============================================================================
Write-Host "Adding Bitnami Helm repository..." -ForegroundColor Yellow
helm repo add bitnami https://charts.bitnami.com/bitnami 2>&1 | Out-Null
helm repo update 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Bitnami repository added" -ForegroundColor Green
} else {
    Write-Host "ERROR: Failed to add Bitnami repository!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# ============================================================================
# STEP 3: Update Helm Dependencies
# ============================================================================
Write-Host "Updating Helm chart dependencies..." -ForegroundColor Yellow
$chartPath = Join-Path $PSScriptRoot "..\charts\platform"

if (-not (Test-Path $chartPath)) {
    Write-Host "ERROR: Chart not found at $chartPath" -ForegroundColor Red
    exit 1
}

cd $chartPath
helm dependency update

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to update dependencies!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Dependencies updated" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 4: Create Namespaces
# ============================================================================
Write-Host "Creating namespaces..." -ForegroundColor Yellow

$namespaces = @("dev", "preprod", "prod")

foreach ($ns in $namespaces) {
    kubectl create namespace $ns 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Created namespace: $ns" -ForegroundColor Green
    } else {
        Write-Host "  [INFO] Namespace $ns already exists" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================================
# STEP 5: Deploy to Dev Environment
# ============================================================================
Write-Host "Deploying to DEV environment..." -ForegroundColor Green
Write-Host "This will take 5-10 minutes on first deploy (image pulls)..." -ForegroundColor Gray

# Build Helm command with values files
$helmArgs = @(
    "upgrade", "--install", "platform-dev", ".",
    "--namespace", "dev",
    "--values", "values-dev.yaml"
)

# Add local values file if it exists
$localValuesFile = "values-dev.local.yaml"
if (Test-Path $localValuesFile) {
    Write-Host "  Using local values file: $localValuesFile" -ForegroundColor Cyan
    $helmArgs += @("--values", $localValuesFile)
} elseif ($env:DEV_DB_PASSWORD) {
    Write-Host "  Using password from DEV_DB_PASSWORD environment variable" -ForegroundColor Cyan
    $helmArgs += @("--set-string", "database.password=$env:DEV_DB_PASSWORD")
} else {
    Write-Host "  WARNING: No password configured!" -ForegroundColor Yellow
    Write-Host "  Either:" -ForegroundColor Yellow
    Write-Host "    1. Copy values-dev.local.yaml.example to values-dev.local.yaml and set password" -ForegroundColor Gray
    Write-Host "    2. Set DEV_DB_PASSWORD environment variable" -ForegroundColor Gray
    Write-Host "  Using default password for now (NOT SECURE)" -ForegroundColor Red
    $helmArgs += @("--set-string", "database.password=dev_password_123")
}

$helmArgs += @("--wait", "--timeout", "15m")

# Execute Helm command
& helm $helmArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to deploy to dev!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Dev deployment complete" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 6: Deploy to Preprod Environment
# ============================================================================
Write-Host "Deploying to PREPROD environment..." -ForegroundColor Green
Write-Host "This will take 5-10 minutes on first deploy (image pulls)..." -ForegroundColor Gray

# Build Helm command with values files
$helmArgs = @(
    "upgrade", "--install", "platform-preprod", ".",
    "--namespace", "preprod",
    "--values", "values-preprod.yaml"
)

# Add local values file if it exists
$localValuesFile = "values-preprod.local.yaml"
if (Test-Path $localValuesFile) {
    Write-Host "  Using local values file: $localValuesFile" -ForegroundColor Cyan
    $helmArgs += @("--values", $localValuesFile)
} elseif ($env:PREPROD_DB_PASSWORD) {
    Write-Host "  Using password from PREPROD_DB_PASSWORD environment variable" -ForegroundColor Cyan
    $helmArgs += @("--set-string", "database.password=$env:PREPROD_DB_PASSWORD")
} else {
    Write-Host "  WARNING: No password configured!" -ForegroundColor Yellow
    Write-Host "  Either:" -ForegroundColor Yellow
    Write-Host "    1. Copy values-preprod.local.yaml.example to values-preprod.local.yaml and set password" -ForegroundColor Gray
    Write-Host "    2. Set PREPROD_DB_PASSWORD environment variable" -ForegroundColor Gray
    Write-Host "  Using default password for now (NOT SECURE)" -ForegroundColor Red
    $helmArgs += @("--set-string", "database.password=preprod_password_456")
}

$helmArgs += @("--wait", "--timeout", "15m")

# Execute Helm command
& helm $helmArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to deploy to preprod!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Preprod deployment complete" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 7: Deploy to Prod Environment
# ============================================================================
Write-Host "Deploying to PROD environment..." -ForegroundColor Green
Write-Host "This will take 5-10 minutes on first deploy (image pulls)..." -ForegroundColor Gray

# Build Helm command with values files
$helmArgs = @(
    "upgrade", "--install", "platform-prod", ".",
    "--namespace", "prod",
    "--values", "values-prod.yaml"
)

# Add local values file if it exists
$localValuesFile = "values-prod.local.yaml"
if (Test-Path $localValuesFile) {
    Write-Host "  Using local values file: $localValuesFile" -ForegroundColor Cyan
    $helmArgs += @("--values", $localValuesFile)
} elseif ($env:PROD_DB_PASSWORD) {
    Write-Host "  Using password from PROD_DB_PASSWORD environment variable" -ForegroundColor Cyan
    $helmArgs += @("--set-string", "database.password=$env:PROD_DB_PASSWORD")
} else {
    Write-Host "  WARNING: No password configured!" -ForegroundColor Yellow
    Write-Host "  Either:" -ForegroundColor Yellow
    Write-Host "    1. Copy values-prod.local.yaml.example to values-prod.local.yaml and set password" -ForegroundColor Gray
    Write-Host "    2. Set PROD_DB_PASSWORD environment variable" -ForegroundColor Gray
    Write-Host "  Using default password for now (NOT SECURE)" -ForegroundColor Red
    $helmArgs += @("--set-string", "database.password=prod_password_789")
}

$helmArgs += @("--wait", "--timeout", "15m")

# Execute Helm command
& helm $helmArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to deploy to prod!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Prod deployment complete" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 8: Verify Deployments
# ============================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($ns in $namespaces) {
    Write-Host "Environment: $ns" -ForegroundColor Yellow
    Write-Host "Pods:" -ForegroundColor Gray
    kubectl get pods -n $ns
    Write-Host ""
    Write-Host "Services:" -ForegroundColor Gray
    kubectl get svc -n $ns
    Write-Host ""
    Write-Host "---" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================================
# STEP 9: Display Access Instructions
# ============================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "How to Access Your Applications" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To access the applications, use kubectl port-forward:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Dev environment:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n dev svc/platform-dev-app 8000:8000" -ForegroundColor Gray
Write-Host "  Then open: http://localhost:8000" -ForegroundColor Gray
Write-Host ""
Write-Host "Preprod environment:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n preprod svc/platform-preprod-app 8001:8000" -ForegroundColor Gray
Write-Host "  Then open: http://localhost:8001" -ForegroundColor Gray
Write-Host ""
Write-Host "Prod environment:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n prod svc/platform-prod-app 8002:8000" -ForegroundColor Gray
Write-Host "  Then open: http://localhost:8002" -ForegroundColor Gray
Write-Host ""
Write-Host "API Documentation:" -ForegroundColor Yellow
Write-Host "  http://localhost:8000/docs (Swagger UI)" -ForegroundColor Gray
Write-Host ""
Write-Host "Cost Saving Tip:" -ForegroundColor Yellow
Write-Host "  Run .\02-scale.ps1 to scale down dev/preprod when not in use!" -ForegroundColor Green
Write-Host ""
