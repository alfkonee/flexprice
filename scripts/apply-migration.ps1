# Apply database migration
param(
    [Parameter(Mandatory=$true)]
    [string]$MigrationFile
)

if (-not (Test-Path $MigrationFile)) {
    Write-Host "Error: Migration file not found: $MigrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "Applying migration file: $MigrationFile" -ForegroundColor Cyan

# Read config.yaml to get database connection details
$configPath = "config.yaml"
if (-not (Test-Path $configPath)) {
    Write-Host "Error: config.yaml not found" -ForegroundColor Red
    exit 1
}

# Parse YAML (simple parsing for postgres section)
$config = Get-Content $configPath -Raw
if ($config -match 'postgres:[\s\S]*?host:\s*(\S+)[\s\S]*?username:\s*(\S+)[\s\S]*?password:\s*(\S+)[\s\S]*?database:\s*(\S+)') {
    $host = $matches[1]
    $username = $matches[2]
    $password = $matches[3]
    $database = $matches[4]
    
    $env:PGPASSWORD = $password
    
    Write-Host "Connecting to PostgreSQL at $host..." -ForegroundColor Yellow
    & psql -h $host -U $username -d $database -f $MigrationFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Migration applied successfully" -ForegroundColor Green
    } else {
        Write-Host "Migration failed" -ForegroundColor Red
        exit $LASTEXITCODE
    }
} else {
    Write-Host "Error: Could not parse database configuration from config.yaml" -ForegroundColor Red
    exit 1
}
