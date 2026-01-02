# Run ClickHouse migrations
Write-Host "Wait for clickhouse to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$migrationFiles = Get-ChildItem -Path "migrations\clickhouse\*.sql" -ErrorAction SilentlyContinue

if ($migrationFiles) {
    foreach ($file in $migrationFiles) {
        Write-Host "Running migration: $($file.FullName)" -ForegroundColor Cyan
        Get-Content $file.FullName | & docker compose exec -T clickhouse clickhouse-client --user=flexprice --password=flexprice123 --database=flexprice --multiquery
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Migration failed: $($file.Name)" -ForegroundColor Red
            exit $LASTEXITCODE
        }
    }
    Write-Host "Clickhouse migrations complete" -ForegroundColor Green
} else {
    Write-Host "No migration files found in migrations\clickhouse\" -ForegroundColor Yellow
}
