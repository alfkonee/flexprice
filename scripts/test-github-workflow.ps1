# Test GitHub workflow locally
Write-Host "Testing GitHub workflow locally..." -ForegroundColor Cyan

# Check if act is installed
if (-not (Get-Command act -ErrorAction SilentlyContinue)) {
    Write-Host "act is not installed. Installing..." -ForegroundColor Yellow
    
    # Install act using scoop if available, otherwise provide instructions
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        scoop install act
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install act-cli -y
    } else {
        Write-Host "Please install act manually from https://github.com/nektos/act" -ForegroundColor Red
        Write-Host "You can install it using:" -ForegroundColor Yellow
        Write-Host "  - Scoop: scoop install act" -ForegroundColor Gray
        Write-Host "  - Chocolatey: choco install act-cli" -ForegroundColor Gray
        exit 1
    }
}

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "Error: .env file not found. Please create a .env file with SDK_DEPLOY_GIT_TOKEN, NPM_AUTH_TOKEN, and PYPI_API_TOKEN" -ForegroundColor Red
    exit 1
}

# Read environment variables from .env file
$envVars = @{}
Get-Content ".env" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.+)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

$SDK_DEPLOY_GIT_TOKEN = $envVars['SDK_DEPLOY_GIT_TOKEN']
$NPM_AUTH_TOKEN = $envVars['NPM_AUTH_TOKEN']
$PYPI_API_TOKEN = $envVars['PYPI_API_TOKEN']

if (-not $SDK_DEPLOY_GIT_TOKEN -or -not $NPM_AUTH_TOKEN -or -not $PYPI_API_TOKEN) {
    Write-Host "Error: Missing required environment variables in .env file" -ForegroundColor Red
    exit 1
}

Write-Host "Running act with GitHub workflow..." -ForegroundColor Yellow

& act release -e .github/workflows/test-event.json `
    -s "SDK_DEPLOY_GIT_TOKEN=$SDK_DEPLOY_GIT_TOKEN" `
    -s "NPM_AUTH_TOKEN=$NPM_AUTH_TOKEN" `
    -s "PYPI_API_TOKEN=$PYPI_API_TOKEN" `
    -P ubuntu-latest=catthehacker/ubuntu:act-latest `
    --container-architecture linux/amd64 `
    --action-offline-mode

if ($LASTEXITCODE -eq 0) {
    Write-Host "GitHub workflow test completed successfully" -ForegroundColor Green
} else {
    Write-Host "GitHub workflow test failed" -ForegroundColor Red
    exit $LASTEXITCODE
}
