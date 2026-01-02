# Script to copy the async.go file to the API SDK directory

# Get the directory of this script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sdkDir = Join-Path (Split-Path (Split-Path $scriptDir -Parent) -Parent) "go"
$sourceFile = Join-Path $scriptDir "async.go"
$targetFile = Join-Path $sdkDir "async.go"

# Verify source file exists
if (-not (Test-Path $sourceFile)) {
    Write-Host "Error: Source file not found: $sourceFile" -ForegroundColor Red
    exit 1
}

# Verify SDK directory exists
if (-not (Test-Path $sdkDir)) {
    Write-Host "Error: SDK directory not found: $sdkDir" -ForegroundColor Red
    exit 1
}

# Copy the file
Write-Host "Copying $sourceFile to $targetFile" -ForegroundColor Cyan
try {
    Copy-Item -Path $sourceFile -Destination $targetFile -Force
    Write-Host "Successfully added async functionality to the FlexPrice Go SDK" -ForegroundColor Green
}
catch {
    Write-Host "Error: Failed to copy the file: $_" -ForegroundColor Red
    exit 1
}
