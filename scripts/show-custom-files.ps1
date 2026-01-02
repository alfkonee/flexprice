# Show custom files status
Write-Host "Custom files status:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

Write-Host "`nJavaScript custom files:" -ForegroundColor Yellow
if (Test-Path "api\custom\javascript") {
    $jsFiles = Get-ChildItem -Path "api\custom\javascript" -Recurse -File | Where-Object { $_.Name -ne "README.md" }
    if ($jsFiles) {
        foreach ($file in $jsFiles) {
            Write-Host "  $($file.FullName.Replace("$PWD\", ""))" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No custom files found" -ForegroundColor Gray
    }
} else {
    Write-Host "  No custom directory found" -ForegroundColor Gray
}

Write-Host "`nPython custom files:" -ForegroundColor Yellow
if (Test-Path "api\custom\python") {
    $pyFiles = Get-ChildItem -Path "api\custom\python" -Recurse -File | Where-Object { $_.Name -ne "README.md" }
    if ($pyFiles) {
        foreach ($file in $pyFiles) {
            Write-Host "  $($file.FullName.Replace("$PWD\", ""))" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No custom files found" -ForegroundColor Gray
    }
} else {
    Write-Host "  No custom directory found" -ForegroundColor Gray
}

Write-Host "`nGo custom files:" -ForegroundColor Yellow
if (Test-Path "api\custom\go") {
    $goFiles = Get-ChildItem -Path "api\custom\go" -Recurse -File | Where-Object { $_.Name -ne "README.md" }
    if ($goFiles) {
        foreach ($file in $goFiles) {
            Write-Host "  $($file.FullName.Replace("$PWD\", ""))" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No custom files found" -ForegroundColor Gray
    }
} else {
    Write-Host "  No custom directory found" -ForegroundColor Gray
}
