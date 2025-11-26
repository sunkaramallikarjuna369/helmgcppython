# Setup Script - Create GKE Cluster and Configure Environment
# Run this script from PowerShell on Windows
#
# This script creates a single GKE Autopilot cluster that will host
# dev, preprod, and prod environments in separate namespaces.
# This is the most cost-effective approach.

# ============================================================================
# STEP 1: Validate Prerequisites
# ============================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GKE Cluster Setup for Dev/Preprod/Prod" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if gcloud is installed
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
$gcloudVersion = gcloud version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: gcloud CLI is not installed!" -ForegroundColor Red
    Write-Host "Please install from: https://cloud.google.com/sdk/docs/install#windows" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] gcloud CLI is installed" -ForegroundColor Green

# Check if kubectl is installed
$kubectlVersion = kubectl version --client 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: kubectl is not installed!" -ForegroundColor Red
    Write-Host "Install with: gcloud components install kubectl" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] kubectl is installed" -ForegroundColor Green

# Check if helm is installed
$helmVersion = helm version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Helm is not installed!" -ForegroundColor Red
    Write-Host "Install from: https://helm.sh/docs/intro/install/" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Helm is installed" -ForegroundColor Green

Write-Host ""

# ============================================================================
# STEP 2: Get Project Configuration
# ============================================================================
Write-Host "Project Configuration:" -ForegroundColor Yellow
Write-Host ""

# Prompt for project ID if not set
if (-not $env:PROJECT_ID) {
    $env:PROJECT_ID = Read-Host "Enter your GCP Project ID"
}

# Set default region if not set
if (-not $env:REGION) {
    $env:REGION = "us-central1"
    Write-Host "Using default region: $env:REGION" -ForegroundColor Yellow
}

$CLUSTER_NAME = "platform-cluster"

Write-Host "Project ID: $env:PROJECT_ID" -ForegroundColor Cyan
Write-Host "Region: $env:REGION" -ForegroundColor Cyan
Write-Host "Cluster Name: $CLUSTER_NAME" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# STEP 3: Set GCP Project
# ============================================================================
Write-Host "Setting GCP project..." -ForegroundColor Yellow
gcloud config set project $env:PROJECT_ID

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to set project!" -ForegroundColor Red
    exit 1
}

# Verify billing is enabled
Write-Host "Verifying billing is enabled..." -ForegroundColor Yellow
$billingInfo = gcloud billing projects describe $env:PROJECT_ID --format="value(billingEnabled)" 2>&1

if ($billingInfo -ne "True") {
    Write-Host "ERROR: Billing is not enabled for this project!" -ForegroundColor Red
    Write-Host "Please enable billing at: https://console.cloud.google.com/billing" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Billing is enabled" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 4: Enable Required APIs
# ============================================================================
Write-Host "Enabling required GCP APIs..." -ForegroundColor Yellow
Write-Host "This may take 2-3 minutes..." -ForegroundColor Gray

$apis = @(
    "container.googleapis.com",
    "compute.googleapis.com"
)

foreach ($api in $apis) {
    Write-Host "  Enabling $api..." -ForegroundColor Cyan
    gcloud services enable $api --project=$env:PROJECT_ID 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK]" -ForegroundColor Green
    } else {
        Write-Host "    [FAILED]" -ForegroundColor Red
    }
}

Write-Host ""

# ============================================================================
# STEP 5: Create GKE Autopilot Cluster
# ============================================================================
Write-Host "Creating GKE Autopilot cluster..." -ForegroundColor Green
Write-Host "This will take 10-15 minutes. Please wait..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Cost estimate: ~$0.10/hour for minimal workloads" -ForegroundColor Gray
Write-Host "With 3 small apps + 3 small databases: ~$50-70/month" -ForegroundColor Gray
Write-Host "Well within your $300 free credits!" -ForegroundColor Green
Write-Host ""

$confirmation = Read-Host "Do you want to proceed? (yes/no)"
if ($confirmation -ne "yes") {
    Write-Host "Setup cancelled." -ForegroundColor Yellow
    exit 0
}

# Create the cluster
gcloud container clusters create-auto $CLUSTER_NAME `
    --region=$env:REGION `
    --project=$env:PROJECT_ID `
    --release-channel=regular

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Failed to create cluster!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[OK] Cluster created successfully!" -ForegroundColor Green

# ============================================================================
# STEP 6: Get Cluster Credentials
# ============================================================================
Write-Host ""
Write-Host "Configuring kubectl..." -ForegroundColor Yellow

gcloud container clusters get-credentials $CLUSTER_NAME `
    --region=$env:REGION `
    --project=$env:PROJECT_ID

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to get cluster credentials!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] kubectl configured" -ForegroundColor Green

# ============================================================================
# STEP 7: Verify Cluster
# ============================================================================
Write-Host ""
Write-Host "Verifying cluster..." -ForegroundColor Yellow
kubectl cluster-info

Write-Host ""
Write-Host "Checking nodes..." -ForegroundColor Yellow
kubectl get nodes

# ============================================================================
# STEP 8: Save Environment Variables
# ============================================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment variables:" -ForegroundColor Yellow
Write-Host "  PROJECT_ID: $env:PROJECT_ID" -ForegroundColor Cyan
Write-Host "  REGION: $env:REGION" -ForegroundColor Cyan
Write-Host "  CLUSTER_NAME: $CLUSTER_NAME" -ForegroundColor Cyan
Write-Host ""
Write-Host "To make these permanent, add to your PowerShell profile:" -ForegroundColor Yellow
Write-Host "  notepad `$PROFILE" -ForegroundColor Gray
Write-Host ""
Write-Host "Add these lines:" -ForegroundColor Yellow
Write-Host "  `$env:PROJECT_ID = '$env:PROJECT_ID'" -ForegroundColor Gray
Write-Host "  `$env:REGION = '$env:REGION'" -ForegroundColor Gray
Write-Host ""
Write-Host "Next step: Run .\01-deploy.ps1 to deploy applications" -ForegroundColor Green
Write-Host ""
