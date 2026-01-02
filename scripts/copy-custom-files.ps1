# Generic Custom Files Copy Script
# This script copies custom files from the custom directory to any generated SDK
# Usage: .\copy-custom-files.ps1 <sdk-type>
# Example: .\copy-custom-files.ps1 javascript

param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet('javascript', 'python', 'go')]
    [string]$SdkType
)

# Function to show usage
function Show-Usage {
    Write-Host "Usage: .\copy-custom-files.ps1 <sdk-type>" -ForegroundColor Cyan
    Write-Host "`nSupported SDK types:" -ForegroundColor Yellow
    Write-Host "  javascript  - JavaScript/TypeScript SDK"
    Write-Host "  python      - Python SDK"
    Write-Host "  go          - Go SDK"
    Write-Host "`nExamples:" -ForegroundColor Yellow
    Write-Host "  .\copy-custom-files.ps1 javascript"
    Write-Host "  .\copy-custom-files.ps1 python"
    Write-Host "  .\copy-custom-files.ps1 go"
}

# Configuration based on SDK type
switch ($SdkType) {
    "javascript" {
        $customDir = "api\custom\javascript"
        $targetDir = "api\javascript"
        $sdkName = "JavaScript/TypeScript SDK"
    }
    "python" {
        $customDir = "api\custom\python"
        $targetDir = "api\python"
        $sdkName = "Python SDK"
    }
    "go" {
        $customDir = "api\custom\go"
        $targetDir = "api\go"
        $sdkName = "Go SDK"
    }
}

Write-Host "🔄 Copying custom files to $sdkName..." -ForegroundColor Cyan

# Check if custom directory exists
if (-not (Test-Path $customDir)) {
    Write-Host "⚠️  No custom directory found at $customDir" -ForegroundColor Yellow
    Write-Host "💡 Custom files will not be copied" -ForegroundColor Yellow
    exit 0
}

# Check if target directory exists
if (-not (Test-Path $targetDir)) {
    Write-Host "❌ Error: Target directory not found at $targetDir" -ForegroundColor Red
    Write-Host "💡 Please run 'make generate-$SdkType-sdk' first" -ForegroundColor Yellow
    exit 1
}

# Check if there are any custom files to copy
$customFiles = Get-ChildItem -Path $customDir -Recurse -File | Where-Object { $_.Name -ne "README.md" }

if (-not $customFiles) {
    Write-Host "⚠️  No custom files found to copy" -ForegroundColor Yellow
    Write-Host "💡 Add custom files to $customDir to include them in the SDK" -ForegroundColor Yellow
    exit 0
}

# Copy custom files
Write-Host "📂 Found custom files, copying to generated SDK..." -ForegroundColor Cyan
$filesCopied = 0
$customApis = @()

foreach ($file in $customFiles) {
    # Calculate relative path from custom directory
    $relPath = $file.FullName.Substring($customDir.Length + 1)
    
    # Create target file path
    $targetFile = Join-Path $targetDir $relPath
    
    # Create target directory if it doesn't exist
    $targetFileDir = Split-Path $targetFile -Parent
    if (-not (Test-Path $targetFileDir)) {
        New-Item -ItemType Directory -Path $targetFileDir -Force | Out-Null
    }
    
    # Copy the file
    Copy-Item -Path $file.FullName -Destination $targetFile -Force
    Write-Host "✅ Copied: $relPath" -ForegroundColor Green
    $filesCopied++
    
    # Track custom API files for index.ts update
    if ($relPath -match '^src\\apis\\.*\.ts$' -and $relPath -ne 'src\apis\index.ts') {
        $apiName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $customApis += $apiName
    }
}

# Update index.ts if custom APIs were copied
if ($customApis.Count -gt 0) {
    Write-Host "📝 Updating index.ts with custom APIs..." -ForegroundColor Cyan
    $indexFile = Join-Path $targetDir "src\apis\index.ts"
    
    if (Test-Path $indexFile) {
        # Read existing exports and filter out custom APIs
        $existingExports = Get-Content $indexFile | Where-Object { 
            $_ -match '^export \* from' -and -not ($customApis | Where-Object { $_ -match $_ })
        }
        
        # Add custom API exports in alphabetical order
        $customExports = $customApis | Sort-Object | ForEach-Object { "export * from './$_';" }
        
        # Combine and write back
        $allExports = $existingExports + $customExports
        Set-Content -Path $indexFile -Value $allExports
        
        Write-Host "✅ Updated index.ts with custom APIs: $($customApis -join ', ')" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  Warning: index.ts not found at $indexFile" -ForegroundColor Yellow
    }
}

Write-Host "📁 Total files copied: $filesCopied" -ForegroundColor Green
Write-Host "✅ Custom files copy complete!" -ForegroundColor Green
Write-Host "💡 Custom files have been copied to $targetDir" -ForegroundColor Cyan
