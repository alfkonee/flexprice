# Fix Swagger references - replace allOf with direct $ref
# This improves type definitions in generated documentation

$swaggerFile = "docs\swagger\swagger.json"
$backupFile = "$swaggerFile.bak"

# Check if the swagger file exists
if (-not (Test-Path $swaggerFile)) {
    Write-Host "Error: Swagger file not found at $swaggerFile" -ForegroundColor Red
    exit 1
}

# Create a backup of the original file
Copy-Item $swaggerFile $backupFile -Force
Write-Host "Created backup at $backupFile" -ForegroundColor Yellow

try {
    # Read the JSON file
    $content = Get-Content $swaggerFile -Raw
    
    # Count original references
    $originalRefCount = ([regex]::Matches($content, '"\$ref"')).Count
    
    # Define the pattern to match - "allOf": [ { "$ref": "#/definitions/Type" } ]
    $pattern = '"allOf":\s*\[\s*\{\s*"\$ref":\s*"(#/definitions/[^"]+)"\s*\}\s*\]'
    
    # Perform the replacement
    $modifiedContent = [regex]::Replace($content, $pattern, {
        param($match)
        $refPath = $match.Groups[1].Value
        return "`"`$ref`": `"$refPath`""
    })
    
    # Count new references
    $newRefCount = ([regex]::Matches($modifiedContent, '"\$ref"')).Count
    $replacedCount = $newRefCount - $originalRefCount
    
    # Write the modified content back to the file
    Set-Content -Path $swaggerFile -Value $modifiedContent -NoNewline
    
    Write-Host "Replaced $replacedCount allOf patterns with direct `$ref references" -ForegroundColor Green
    Write-Host "Total `$ref count: $newRefCount" -ForegroundColor Cyan
    
    # Clean up backup
    Remove-Item $backupFile -Force
    
    Write-Host "Processed $swaggerFile" -ForegroundColor Green
    Write-Host "Done! The swagger.json file has been updated." -ForegroundColor Green
}
catch {
    Write-Host "Error: Failed to process the file: $_" -ForegroundColor Red
    # Restore the backup
    if (Test-Path $backupFile) {
        Copy-Item $backupFile $swaggerFile -Force
        Write-Host "Restored from backup" -ForegroundColor Yellow
    }
    exit 1
}
