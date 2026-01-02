# Clean Docker/Podman volumes
param(
    [string]$ContainerRuntime = $env:CONTAINER_RUNTIME
)

if (-not $ContainerRuntime) {
    # Auto-detect container runtime
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        if (docker version 2>$null) {
            $ContainerRuntime = "docker"
        }
    }
    if (-not $ContainerRuntime -and (Get-Command podman -ErrorAction SilentlyContinue)) {
        if (podman version 2>$null) {
            $ContainerRuntime = "podman"
        }
    }
}

if (-not $ContainerRuntime) {
    Write-Host "Error: Neither docker nor podman found" -ForegroundColor Red
    exit 1
}

Write-Host "Removing flexprice volumes using $ContainerRuntime..." -ForegroundColor Yellow

# Get all volumes and filter for flexprice
$volumes = & $ContainerRuntime volume ls -q | Where-Object { $_ -match "flexprice" }

if ($volumes) {
    foreach ($volume in $volumes) {
        Write-Host "Removing volume: $volume" -ForegroundColor Cyan
        & $ContainerRuntime volume rm $volume 2>$null
    }
    Write-Host "Volumes cleaned successfully" -ForegroundColor Green
} else {
    Write-Host "No flexprice volumes found" -ForegroundColor Yellow
}
