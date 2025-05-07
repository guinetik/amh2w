# fix-encoding.ps1
# Script to convert all PS1 files to UTF-8 with BOM encoding

$projectRoot = $PSScriptRoot

Write-Host "Converting all PS1 files to UTF-8 with BOM encoding..." -ForegroundColor Cyan
Write-Host "Project root: $projectRoot" -ForegroundColor Cyan
Write-Host ""

# Get all PS1 files in the project
$psFiles = Get-ChildItem -Path $projectRoot -Filter "*.ps1" -Recurse

$convertedCount = 0
$alreadyCorrectCount = 0
$errorCount = 0

foreach ($file in $psFiles) {
    try {
        # Read the file content as bytes to check encoding
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191
        
        if (-not $hasBom) {
            # File doesn't have BOM, need to convert
            Write-Host "Converting: $($file.FullName)" -ForegroundColor Yellow
            
            # Read content
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
            
            # Create UTF8 encoding with BOM
            $utf8Encoding = New-Object System.Text.UTF8Encoding $true
            
            # Write content with BOM
            [System.IO.File]::WriteAllText($file.FullName, $content, $utf8Encoding)
            
            $convertedCount++
        } else {
            # File already has correct encoding
            Write-Host "Already correct: $($file.FullName)" -ForegroundColor DarkGray
            $alreadyCorrectCount++
        }
    } catch {
        Write-Host "Error converting $($file.FullName): $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""
Write-Host "Encoding conversion complete:" -ForegroundColor Green
Write-Host "  - Files converted: $convertedCount" -ForegroundColor White
Write-Host "  - Files already correct: $alreadyCorrectCount" -ForegroundColor White
Write-Host "  - Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "White" })
