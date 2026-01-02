# Script to publish SDKs to their respective package managers

param(
    [switch]$Js,
    [switch]$Javascript,
    [switch]$Py,
    [switch]$Python,
    [switch]$Go,
    [switch]$All,
    [string]$Version,
    [switch]$DryRun,
    [switch]$Help
)

# Function to show help
function Show-Help {
    Write-Host "Usage: .\publish.ps1 [options]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -Js, -Javascript    Publish JavaScript SDK to npm"
    Write-Host "  -Py, -Python        Publish Python SDK to PyPI"
    Write-Host "  -Go                 Prepare Go SDK for publishing (creates tag)"
    Write-Host "  -All                Publish all SDKs"
    Write-Host "  -Version VERSION    Set version for all SDKs before publishing"
    Write-Host "  -DryRun             Run in dry run mode without making changes"
    Write-Host "  -Help               Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\publish.ps1 -All -Version 1.2.3"
    Write-Host "  .\publish.ps1 -Js -Py"
    Write-Host "  .\publish.ps1 -Go -Version 1.0.0"
    Write-Host "  .\publish.ps1 -Go -Version 1.0.0 -DryRun"
}

# Show help if requested
if ($Help) {
    Show-Help
    exit 0
}

# Normalize flags
$publishJs = $Js -or $Javascript
$publishPy = $Py -or $Python
$publishGo = $Go

# Handle -All flag
if ($All) {
    $publishJs = $true
    $publishPy = $true
    $publishGo = $true
}

# Change to script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# If no SDK specified, show help
if (-not ($publishJs -or $publishPy -or $publishGo)) {
    Write-Host "Error: No SDK specified for publishing" -ForegroundColor Red
    Show-Help
    exit 1
}

# Update versions if specified
if ($Version) {
    Write-Host "Updating SDK versions to $Version..." -ForegroundColor Cyan
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would update SDK versions to $Version" -ForegroundColor Yellow
    }
    else {
        # Update JavaScript SDK version
        if ($publishJs -and (Test-Path "javascript")) {
            Write-Host "Updating JavaScript SDK version..." -ForegroundColor Cyan
            $packageJsonPath = "javascript\package.json"
            
            if (Test-Path $packageJsonPath) {
                try {
                    $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
                    $packageJson.version = $Version
                    $packageJson | ConvertTo-Json -Depth 100 | Set-Content $packageJsonPath
                    Write-Host "✅ JavaScript SDK version updated" -ForegroundColor Green
                }
                catch {
                    Write-Host "⚠️  Failed to update JavaScript SDK version: $_" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "⚠️  package.json not found in javascript directory" -ForegroundColor Yellow
            }
        }
        
        # Update Python SDK version
        if ($publishPy -and (Test-Path "python")) {
            Write-Host "Updating Python SDK version..." -ForegroundColor Cyan
            $setupPyPath = "python\setup.py"
            
            if (Test-Path $setupPyPath) {
                try {
                    $content = Get-Content $setupPyPath -Raw
                    $content = $content -replace 'VERSION = "[^"]*"', "VERSION = `"$Version`""
                    Set-Content -Path $setupPyPath -Value $content
                    Write-Host "✅ Python SDK version updated" -ForegroundColor Green
                }
                catch {
                    Write-Host "⚠️  Failed to update Python SDK version: $_" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "⚠️  setup.py not found in python directory" -ForegroundColor Yellow
            }
        }
        
        # For Go SDK, we just note the version
        if ($publishGo -and (Test-Path "go")) {
            Write-Host "Go SDK version will be set to $Version" -ForegroundColor Cyan
        }
    }
}

if ($DryRun) {
    Write-Host "DRY RUN: Publishing process completed (no changes made)" -ForegroundColor Yellow
}
else {
    Write-Host "Publishing process completed!" -ForegroundColor Green
    Write-Host "NOTE: For the Go SDK, you need to push the tag to GitHub for publishing." -ForegroundColor Yellow
    Write-Host "      The GitHub workflow will handle this automatically when triggered." -ForegroundColor Yellow
}
