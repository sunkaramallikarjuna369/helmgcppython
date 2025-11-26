# Cleanup Script - Remove All Resources
# Run this script from PowerShell on Windows
#
# WARNING: This will delete ALL resources including data!
# Use this when you're completely done with the platform.

# ============================================================================
# STEP 1: Display Warning
# ============================================================================
Write-Host "========================================" -ForegroundColor Red
Write-Host "CLEANUP WARNING" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""
Write-Host "This will DELETE the following:" -ForegroundColor Yellow
Write-Host "  - All Helm releases (dev, preprod, prod)" -ForegroundColor White
Write-Host "  - All databases and data" -ForegroundColor White
Write-Host "  - All PersistentVolumes and PersistentVolumeClaims" -ForegroundColor White
Write-Host "  - GKE cluster (optional)" -ForegroundColor White
Write-Host ""
Write-Host "This action CANNOT be undone!" -ForegroundColor Red
Write-Host ""

$confirmation = Read-Host "Type 'DELETE' to confirm deletion"

if ($confirmation -ne "DELETE") {
    Write-Host ""
    Write-Host "Cleanup cancelled. No resources were deleted." -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "Starting cleanup process..." -ForegroundColor Yellow
Write-Host ""

# ============================================================================
# STEP 2: Uninstall Helm Releases
# ============================================================================
Write-Host "Step 1: Uninstalling Helm releases..." -ForegroundColor Cyan

$environments = @("dev", "preprod", "prod")

foreach ($env in $environments) {
    Write-Host "  Uninstalling platform-$env..." -ForegroundColor Yellow
    helm uninstall platform-$env --namespace $env 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] Uninstalled" -ForegroundColor Green
    } else {
        Write-Host "    [INFO] Release not found or already deleted" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================================
# STEP 3: Delete PersistentVolumeClaims
# ============================================================================
Write-Host "Step 2: Deleting PersistentVolumeClaims..." -ForegroundColor Cyan

foreach ($env in $environments) {
    Write-Host "  Deleting PVCs in namespace $env..." -ForegroundColor Yellow
    kubectl delete pvc --all -n $env 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] PVCs deleted" -ForegroundColor Green
    } else {
        Write-Host "    [INFO] No PVCs found" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================================
# STEP 4: Delete Namespaces
# ============================================================================
Write-Host "Step 3: Deleting namespaces..." -ForegroundColor Cyan

foreach ($env in $environments) {
    Write-Host "  Deleting namespace $env..." -ForegroundColor Yellow
    kubectl delete namespace $env 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] Namespace deleted" -ForegroundColor Green
    } else {
        Write-Host "    [INFO] Namespace not found" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================================
# STEP 5: Ask About Cluster Deletion
# ============================================================================
Write-Host "Step 4: GKE Cluster Deletion" -ForegroundColor Cyan
Write-Host ""
Write-Host "Do you want to delete the GKE cluster?" -ForegroundColor Yellow
Write-Host "  - YES: Delete cluster (saves all costs, ~$50-70/month)" -ForegroundColor White
Write-Host "  - NO: Keep cluster (you can redeploy applications later)" -ForegroundColor White
Write-Host ""

$deleteCluster = Read-Host "Delete GKE cluster? (yes/no)"

if ($deleteCluster -eq "yes") {
    Write-Host ""
    Write-Host "Deleting GKE cluster..." -ForegroundColor Yellow
    Write-Host "This will take 5-10 minutes..." -ForegroundColor Gray
    Write-Host ""
    
    # Get cluster name and region
    if (-not $env:PROJECT_ID) {
        $env:PROJECT_ID = Read-Host "Enter your GCP Project ID"
    }
    if (-not $env:REGION) {
        $env:REGION = "us-central1"
    }
    
    $CLUSTER_NAME = "platform-cluster"
    
    gcloud container clusters delete $CLUSTER_NAME `
        --region=$env:REGION `
        --project=$env:PROJECT_ID `
        --quiet
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Cluster deleted" -ForegroundColor Green
    } else {
        Write-Host "[FAILED] Failed to delete cluster" -ForegroundColor Red
        Write-Host "You may need to delete it manually from GCP Console" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "[INFO] Cluster kept. You can redeploy applications with .\01-deploy.ps1" -ForegroundColor Cyan
}

Write-Host ""

# ============================================================================
# STEP 6: Verify Cleanup
# ============================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleanup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($deleteCluster -eq "yes") {
    Write-Host "All resources have been deleted." -ForegroundColor White
    Write-Host ""
    Write-Host "Verify in GCP Console:" -ForegroundColor Yellow
    Write-Host "  https://console.cloud.google.com/kubernetes/list" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To start fresh, run .\00-setup.ps1" -ForegroundColor Green
} else {
    Write-Host "Applications and data have been deleted." -ForegroundColor White
    Write-Host "GKE cluster is still running." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Current cluster status:" -ForegroundColor Yellow
    kubectl get nodes
    Write-Host ""
    Write-Host "To redeploy applications, run .\01-deploy.ps1" -ForegroundColor Green
    Write-Host "To delete the cluster later, run this script again" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Cost Monitoring:" -ForegroundColor Yellow
Write-Host "  Check your GCP billing: https://console.cloud.google.com/billing" -ForegroundColor Gray
Write-Host "  Free trial credits remaining: Check 'Credits' section" -ForegroundColor Gray
Write-Host ""
