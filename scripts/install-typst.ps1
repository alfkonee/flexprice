# Install Typst for Windows
# This script downloads and installs Typst binary for Windows

$typstVersion = "v0.13.1"
$installDir = "$env:LOCALAPPDATA\Programs\typst"
$binPath = Join-Path $installDir "typst.exe"

# Check if typst is already installed
if (Get-Command typst -ErrorAction SilentlyContinue) {
    Write-Host "✅ Typst is already installed" -ForegroundColor Green
    typst --version
    exit 0
}

Write-Host "📦 Installing Typst binary for Windows..." -ForegroundColor Cyan

# Detect architecture
$arch = $env:PROCESSOR_ARCHITECTURE
Write-Host "Detected architecture: $arch" -ForegroundColor Yellow

# Determine download URL based on architecture
if ($arch -eq "AMD64" -or $arch -eq "x86_64") {
    $downloadUrl = "https://github.com/typst/typst/releases/download/$typstVersion/typst-x86_64-pc-windows-msvc.zip"
}
elseif ($arch -eq "ARM64") {
    $downloadUrl = "https://github.com/typst/typst/releases/download/$typstVersion/typst-aarch64-pc-windows-msvc.zip"
}
else {
    Write-Host "❌ Error: Unsupported architecture: $arch" -ForegroundColor Red
    exit 1
}

# Create installation directory
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Write-Host "Created installation directory: $installDir" -ForegroundColor Yellow
}

# Download Typst
$zipPath = Join-Path $env:TEMP "typst.zip"
Write-Host "Downloading Typst from $downloadUrl..." -ForegroundColor Cyan

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "✅ Download complete" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error downloading Typst: $_" -ForegroundColor Red
    exit 1
}

# Extract the archive
Write-Host "Extracting Typst..." -ForegroundColor Cyan
try {
    Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
    
    # Move the executable to the root of install directory if needed
    $extractedExe = Get-ChildItem -Path $installDir -Filter "typst.exe" -Recurse | Select-Object -First 1
    if ($extractedExe -and $extractedExe.FullName -ne $binPath) {
        Move-Item -Path $extractedExe.FullName -Destination $binPath -Force
    }
    
    # Clean up any subdirectories
    Get-ChildItem -Path $installDir -Directory | Remove-Item -Recurse -Force
    
    Write-Host "✅ Extraction complete" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error extracting Typst: $_" -ForegroundColor Red
    exit 1
}
finally {
    # Clean up the downloaded zip file
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
}

# Add to PATH if not already there
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$installDir*") {
    Write-Host "Adding Typst to PATH..." -ForegroundColor Cyan
    $newPath = "$currentPath;$installDir"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = "$env:Path;$installDir"
    Write-Host "✅ Added to PATH. You may need to restart your terminal." -ForegroundColor Green
}

# Verify installation
if (Test-Path $binPath) {
    Write-Host "✅ Typst installed successfully!" -ForegroundColor Green
    Write-Host "Location: $binPath" -ForegroundColor Cyan
    
    # Try to run typst to verify
    & $binPath --version
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Typst is working correctly" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  Typst installed but may not be working correctly" -ForegroundColor Yellow
    }
}
else {
    Write-Host "❌ Error: Installation failed - typst.exe not found" -ForegroundColor Red
    exit 1
}

Write-Host "`n💡 If 'typst' command is not recognized, please restart your terminal." -ForegroundColor Yellow
