# Scaling Script - Scale Applications Up or Down to Save Costs
# Run this script from PowerShell on Windows
#
# This script helps you scale dev and preprod environments to zero
# when not in use, saving significant costs while preserving data.

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "preprod", "prod", "all")]
    [string]$Environment = "all",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("up", "down")]
    [string]$Action = "down"
)

# ============================================================================
# STEP 1: Display Information
# ============================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Scale Platform Resources" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($Action -eq "down") {
    Write-Host "This will scale DOWN the following:" -ForegroundColor Yellow
    Write-Host "  - Application pods to 0 replicas" -ForegroundColor White
    Write-Host "  - PostgreSQL StatefulSet to 0 replicas" -ForegroundColor White
    Write-Host ""
    Write-Host "Benefits:" -ForegroundColor Green
    Write-Host "  - Saves compute costs (no running pods)" -ForegroundColor White
    Write-Host "  - Data is preserved (PersistentVolumes remain)" -ForegroundColor White
    Write-Host "  - Can scale back up anytime" -ForegroundColor White
    Write-Host ""
    Write-Host "Note: Applications will be offline until scaled back up" -ForegroundColor Yellow
} else {
    Write-Host "This will scale UP the following:" -ForegroundColor Yellow
    Write-Host "  - Application pods to normal replicas" -ForegroundColor White
    Write-Host "  - PostgreSQL StatefulSet to 1 replica" -ForegroundColor White
    Write-Host ""
    Write-Host "Your data will be restored from PersistentVolumes" -ForegroundColor Green
}

Write-Host ""

# ============================================================================
# STEP 2: Determine Environments to Scale
# ============================================================================
$environments = @()

if ($Environment -eq "all") {
    $environments = @("dev", "preprod")
    Write-Host "WARNING: This will affect DEV and PREPROD environments" -ForegroundColor Yellow
    Write-Host "PROD environment will NOT be scaled (for safety)" -ForegroundColor Green
} elseif ($Environment -eq "prod") {
    Write-Host "WARNING: You are about to scale PRODUCTION!" -ForegroundColor Red
    $confirm = Read-Host "Are you SURE you want to scale prod? (type 'YES' to confirm)"
    if ($confirm -ne "YES") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
    $environments = @("prod")
} else {
    $environments = @($Environment)
}

Write-Host ""
Write-Host "Environments to scale: $($environments -join ', ')" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor Cyan
Write-Host ""

$confirmation = Read-Host "Do you want to proceed? (yes/no)"
if ($confirmation -ne "yes") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""

# ============================================================================
# STEP 3: Scale Resources
# ============================================================================
foreach ($env in $environments) {
    Write-Host "Processing environment: $env" -ForegroundColor Green
    Write-Host ""
    
    if ($Action -eq "down") {
        # Scale down application
        Write-Host "  Scaling down application..." -ForegroundColor Yellow
        kubectl scale deployment platform-$env-app --replicas=0 -n $env
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Application scaled to 0" -ForegroundColor Green
        } else {
            Write-Host "    [FAILED] Could not scale application" -ForegroundColor Red
        }
        
        # Scale down database
        Write-Host "  Scaling down database..." -ForegroundColor Yellow
        kubectl scale statefulset platform-$env-postgresql --replicas=0 -n $env
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Database scaled to 0" -ForegroundColor Green
        } else {
            Write-Host "    [FAILED] Could not scale database" -ForegroundColor Red
        }
        
        Write-Host "  [INFO] Environment $env is now offline (data preserved)" -ForegroundColor Cyan
    } else {
        # Scale up database first
        Write-Host "  Scaling up database..." -ForegroundColor Yellow
        kubectl scale statefulset platform-$env-postgresql --replicas=1 -n $env
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Database scaled to 1" -ForegroundColor Green
        } else {
            Write-Host "    [FAILED] Could not scale database" -ForegroundColor Red
        }
        
        # Wait for database to be ready
        Write-Host "  Waiting for database to be ready..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
        
        # Scale up application
        Write-Host "  Scaling up application..." -ForegroundColor Yellow
        
        # Get original replica count from values file
        $replicas = 1
        if ($env -eq "prod") {
            $replicas = 2
        }
        
        kubectl scale deployment platform-$env-app --replicas=$replicas -n $env
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Application scaled to $replicas" -ForegroundColor Green
        } else {
            Write-Host "    [FAILED] Could not scale application" -ForegroundColor Red
        }
        
        Write-Host "  [INFO] Environment $env is now online" -ForegroundColor Cyan
    }
    
    Write-Host ""
}

# ============================================================================
# STEP 4: Display Current Status
# ============================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Current Status" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($env in $environments) {
    Write-Host "Environment: $env" -ForegroundColor Yellow
    kubectl get pods -n $env
    Write-Host ""
}

# ============================================================================
# STEP 5: Display Cost Savings Information
# ============================================================================
if ($Action -eq "down") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Cost Savings" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Estimated savings per environment when scaled to zero:" -ForegroundColor Yellow
    Write-Host "  - Compute: ~$15-20/month per environment" -ForegroundColor White
    Write-Host "  - Storage: Still charged (~$0.20/month per 5Gi PVC)" -ForegroundColor White
    Write-Host ""
    Write-Host "Total savings for dev + preprod: ~$30-40/month" -ForegroundColor Green
    Write-Host ""
    Write-Host "To scale back up, run:" -ForegroundColor Yellow
    Write-Host "  .\02-scale.ps1 -Environment all -Action up" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Access Your Applications" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Wait 1-2 minutes for pods to be ready, then use port-forward:" -ForegroundColor Yellow
    Write-Host ""
    foreach ($env in $environments) {
        $port = 8000
        if ($env -eq "preprod") { $port = 8001 }
        if ($env -eq "prod") { $port = 8002 }
        Write-Host "$env environment:" -ForegroundColor Cyan
        Write-Host "  kubectl port-forward -n $env svc/platform-$env-app ${port}:8000" -ForegroundColor Gray
        Write-Host "  Then open: http://localhost:$port" -ForegroundColor Gray
        Write-Host ""
    }
}
