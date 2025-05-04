# Test script for download command

Write-Host "`n=== Testing download command ===" -ForegroundColor Cyan

# Test 1: Download a small file
Write-Host "`nTest 1: Downloading a small file..." -ForegroundColor Yellow
$result = all my homies download "https://raw.githubusercontent.com/PowerShell/PowerShell/master/README.md" "test-readme.md"
if ($result.ok) {
    Write-Host "✓ Download succeeded" -ForegroundColor Green
    Write-Host "  File: $($result.value.value.File)" -ForegroundColor Gray
    Write-Host "  Size: $($result.value.value.FileSizeFormatted)" -ForegroundColor Gray
    Write-Host "  Speed: $($result.value.value.DownloadSpeedFormatted)" -ForegroundColor Gray
    Write-Host "  Method: $($result.value.value.Method)" -ForegroundColor Gray
    
    # Clean up
    Remove-Item "test-readme.md" -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "✗ Download failed: $($result.error)" -ForegroundColor Red
}

# Test 2: Download with BITS
Write-Host "`nTest 2: Downloading with BITS..." -ForegroundColor Yellow
$result = all my homies download "https://raw.githubusercontent.com/PowerShell/PowerShell/master/README.md" "test-readme-bits.md"
if ($result.ok) {
    Write-Host "✓ BITS download succeeded" -ForegroundColor Green
    Write-Host "  File: $($result.value.value.File)" -ForegroundColor Gray
    Write-Host "  Size: $($result.value.value.FileSizeFormatted)" -ForegroundColor Gray
    Write-Host "  Speed: $($result.value.value.DownloadSpeedFormatted)" -ForegroundColor Gray
    Write-Host "  Method: $($result.value.value.Method)" -ForegroundColor Gray
    
    # Clean up
    Remove-Item "test-readme-bits.md" -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "✗ BITS download failed: $($result.error)" -ForegroundColor Red
}

# Test 3: Download without specifying output file
Write-Host "`nTest 3: Downloading without specifying output file..." -ForegroundColor Yellow
$result = all my homies download "https://raw.githubusercontent.com/PowerShell/PowerShell/master/LICENSE.txt"
if ($result.ok) {
    Write-Host "✓ Auto-named download succeeded" -ForegroundColor Green
    Write-Host "  File: $($result.value.value.File)" -ForegroundColor Gray
    Write-Host "  Size: $($result.value.value.FileSizeFormatted)" -ForegroundColor Gray
    
    # Clean up
    Remove-Item $result.value.value.File -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "✗ Auto-named download failed: $($result.error)" -ForegroundColor Red
}

Write-Host "`nAll tests completed!" -ForegroundColor Cyan
