#!/usr/bin/env pwsh
# FlexPrice Helm Chart Validation Test Suite (PowerShell)
# Run this script to validate all use cases for the FlexPrice Helm chart
#
# Prerequisites:
#   helm repo add stackgres https://stackgres.io/downloads/stackgres-k8s/stackgres/helm/
#   helm repo add altinity https://docs.altinity.com/clickhouse-operator/
#   helm repo add redpanda https://charts.redpanda.com
#   helm repo add temporal https://go.temporal.io/helm-charts
#   helm repo update
#   helm dependency build
#
# Usage:
#   ./test-chart.ps1
#   .\test-chart.ps1 -Verbose

param(
    [switch]$Verbose = $false
)

# Configuration
$CHART_NAME = "flexprice"
$CHART_DIR = "./"
$script:PASSED_TESTS = @()
$script:FAILED_TESTS = @()
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Detect if colors are supported
$SUPPORTS_COLOR = $PSVersionTable.PSVersion.Major -ge 6 -or $env:TERM -ne $null

# Color codes
$COLOR_CYAN = "`e[0;36m"
$COLOR_GREEN = "`e[0;32m"
$COLOR_YELLOW = "`e[1;33m"
$COLOR_RED = "`e[0;31m"
$COLOR_RESET = "`e[0m"

if (-not $SUPPORTS_COLOR) {
    $COLOR_CYAN = ""
    $COLOR_GREEN = ""
    $COLOR_YELLOW = ""
    $COLOR_RED = ""
    $COLOR_RESET = ""
}

function Print-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "${COLOR_CYAN}========================================${COLOR_RESET}"
    Write-Host "${COLOR_CYAN}${Text}${COLOR_RESET}"
    Write-Host "${COLOR_CYAN}========================================${COLOR_RESET}"
    Write-Host ""
}

function Print-Test {
    param([string]$Text)
    Write-Host "${COLOR_YELLOW}→ ${Text}${COLOR_RESET}"
}

function Print-Pass {
    param([string]$Text)
    Write-Host "${COLOR_GREEN}✓ PASSED${COLOR_RESET}: ${Text}"
    $script:PASSED_TESTS += $Text
}

function Print-Fail {
    param([string]$Text)
    Write-Host "${COLOR_RED}✗ FAILED${COLOR_RESET}: ${Text}"
    $script:FAILED_TESTS += $Text
}

function Print-Summary {
    $total = $script:PASSED_TESTS.Count + $script:FAILED_TESTS.Count
    
    Print-Header "TEST SUMMARY"
    
    Write-Host "Total Tests: ${total}"
    Write-Host "${COLOR_GREEN}Passed: $($script:PASSED_TESTS.Count)${COLOR_RESET}"
    Write-Host "${COLOR_RED}Failed: $($script:FAILED_TESTS.Count)${COLOR_RESET}"
    Write-Host ""
    
    if ($script:PASSED_TESTS.Count -gt 0) {
        Write-Host "${COLOR_GREEN}Passed Tests:${COLOR_RESET}"
        foreach ($test in $script:PASSED_TESTS) {
            Write-Host "  ✓ ${test}"
        }
        Write-Host ""
    }
    
    if ($script:FAILED_TESTS.Count -gt 0) {
        Write-Host "${COLOR_RED}Failed Tests:${COLOR_RESET}"
        foreach ($test in $script:FAILED_TESTS) {
            Write-Host "  ✗ ${test}"
        }
        Write-Host ""
        return $false
    }
    
    return $true
}

function Run-HelmTest {
    param(
        [string]$TestName,
        [string]$HelmCommand,
        [int]$MinLines = 1000
    )
    
    Print-Test $TestName
    
    try {
        # Run the helm command
        $output = Invoke-Expression $HelmCommand 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            # Count lines
            $lineCount = if ($output -is [array]) { $output.Count } else { 1 }
            
            if ($lineCount -gt $MinLines) {
                Print-Pass "$TestName ($lineCount lines generated)"
                return $true
            }
            else {
                Print-Fail "$TestName (expected >$MinLines lines, got $lineCount)"
                return $false
            }
        }
        else {
            Print-Fail "$TestName (command failed with exit code $LASTEXITCODE)"
            if ($Verbose) {
                Write-Host "Error output:"
                $output | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" }
            }
            return $false
        }
    }
    catch {
        Print-Fail "$TestName (exception: $($_.Exception.Message))"
        return $false
    }
}

# Main execution
function Main {
    # Change to chart directory
    if (-not (Test-Path $CHART_DIR)) {
        Write-Host "${COLOR_RED}Error: Chart directory $CHART_DIR not found${COLOR_RESET}"
        exit 1
    }
    
    Push-Location $CHART_DIR
    
    try {
        Print-Header "FLEXPRICE HELM CHART VALIDATION SUITE"
        
        Write-Host "Chart: $CHART_NAME"
        Write-Host "Directory: $(Get-Location)"
        Write-Host ""
        
        # Test 1: Pre-installed operators
        Run-HelmTest `
            "Use Case 1: Pre-Installed Operators" `
            "helm template $CHART_NAME . --set postgres.operator.install=false --set clickhouse.operator.install=false --set kafka.operator.install=false --set temporal.operator.install=false" `
            1200 | Out-Null
        Write-Host ""
        
        # Test 2: External services
        Run-HelmTest `
            "Use Case 2: External Services" `
            "helm template $CHART_NAME . -f examples/values-external.yaml" `
            1200 | Out-Null
        Write-Host ""
        
        # Test 3: Operator deployment
        Run-HelmTest `
            "Use Case 3: Operator Deployment" `
            "helm template $CHART_NAME . -f examples/values-operators.yaml" `
            10000 | Out-Null
        Write-Host ""
        
        # Test 4: Minimal development
        Run-HelmTest `
            "Use Case 4: Minimal Development" `
            "helm template $CHART_NAME . -f examples/values-minimal.yaml" `
            1200 | Out-Null
        Write-Host ""
        
        # Test 5: Chart lint
        Print-Test "Chart Validation: Helm lint"
        try {
            $lintOutput = helm lint . 2>&1
            if ($LASTEXITCODE -eq 0) {
                Print-Pass "Chart Validation: Chart passes linting"
            }
            else {
                Print-Fail "Chart Validation: Chart lint failed"
                if ($Verbose) {
                    Write-Host "Lint output:"
                    $lintOutput | ForEach-Object { Write-Host "  $_" }
                }
            }
        }
        catch {
            Print-Fail "Chart Validation: Helm lint failed"
        }
        Write-Host ""
        
        # Test 6: Dependency check
        Print-Test "Dependencies: Verify chart dependencies"
        try {
            $depOutput = helm dependency list . 2>&1
            if ($LASTEXITCODE -eq 0 -and $depOutput -match "temporal") {
                Print-Pass "Dependencies: All required charts available"
            }
            else {
                Print-Fail "Dependencies: Missing required charts"
                if ($Verbose) {
                    Write-Host "Dependency output:"
                    $depOutput | ForEach-Object { Write-Host "  $_" }
                }
            }
        }
        catch {
            Print-Fail "Dependencies: Could not check dependencies"
        }
        Write-Host ""
        
        # Print summary and exit with proper code
        $success = Print-Summary
        
        if ($success) {
            Write-Host "${COLOR_GREEN}All tests passed! Chart is ready for deployment.${COLOR_RESET}"
            Write-Host ""
            exit 0
        }
        else {
            Write-Host "${COLOR_RED}Some tests failed. Please review the output above.${COLOR_RESET}"
            Write-Host ""
            exit 1
        }
    }
    finally {
        Pop-Location
    }
}

# Run main function
Main
