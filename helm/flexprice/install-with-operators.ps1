#!/usr/bin/env pwsh
# Two-step FlexPrice installation with operators
# This script ensures operators are deployed and CRDs are registered before creating cluster resources
#
# Usage:
#   .\install-with-operators.ps1
#   .\install-with-operators.ps1 -Values .\examples\values-operators-minimal.yaml
#   .\install-with-operators.ps1 -Values .\examples\values-operators.yaml -Namespace flexprice

param(
    [string]$Values = ".\examples\values-operators-minimal.yaml",
    [string]$Namespace = "default",
    [string]$ReleaseName = "flexprice"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FlexPrice Two-Step Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Install only the operators (subcharts)
Write-Host "Step 1: Installing operators..." -ForegroundColor Yellow
Write-Host "This will install Stackgres, ClickHouse, Redpanda, and Temporal operators" -ForegroundColor Gray
Write-Host ""

# First install - operators only, disable CRD creation
helm upgrade --install $ReleaseName . `
    -f $Values `
    -n $Namespace `
    --set postgres.operator.enabled=false `
    --set clickhouse.operator.enabled=false `
    --set kafka.operator.enabled=false `
    --wait --timeout 10m

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to install operators" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Operators installed successfully" -ForegroundColor Green
Write-Host ""

# Wait for CRDs to be registered
Write-Host "Step 2: Waiting for CRDs to be registered..." -ForegroundColor Yellow
Write-Host "Checking for required CRDs..." -ForegroundColor Gray

$maxWait = 120  # 2 minutes
$waited = 0
$interval = 5

$requiredCRDs = @(
    "sgclusters.stackgres.io",
    "clickhouseinstallations.clickhouse.altinity.com",
    "redpandas.cluster.redpanda.com"
)

while ($waited -lt $maxWait) {
    $allReady = $true
    
    foreach ($crd in $requiredCRDs) {
        $exists = kubectl get crd $crd 2>$null
        if ($LASTEXITCODE -ne 0) {
            $allReady = $false
            Write-Host "  Waiting for CRD: $crd" -ForegroundColor Gray
            break
        }
    }
    
    if ($allReady) {
        Write-Host "✓ All CRDs are registered" -ForegroundColor Green
        break
    }
    
    Start-Sleep -Seconds $interval
    $waited += $interval
}

if ($waited -ge $maxWait) {
    Write-Host "✗ Timeout waiting for CRDs" -ForegroundColor Red
    Write-Host "Please check operator deployments and try again" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 3: Install the complete chart including CRDs
Write-Host "Step 3: Creating database clusters..." -ForegroundColor Yellow
Write-Host "This will create PostgreSQL, ClickHouse, and Redpanda clusters" -ForegroundColor Gray
Write-Host ""

helm upgrade --install $ReleaseName . `
    -f $Values `
    -n $Namespace `
    --wait --timeout 15m

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to create database clusters" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Database clusters created successfully" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Check pod status: kubectl get pods -n $Namespace" -ForegroundColor Gray
Write-Host "  2. Run tests: helm test $ReleaseName -n $Namespace" -ForegroundColor Gray
Write-Host "  3. View logs: kubectl logs -l app.kubernetes.io/instance=$ReleaseName -n $Namespace" -ForegroundColor Gray
Write-Host ""
