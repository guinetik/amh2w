# Test script for nerdfonts command
Write-Host "`n=== Testing nerdfonts command ===" -ForegroundColor Cyan

# Test 1: List all fonts
Write-Host "`nTest 1: Listing all Nerd Fonts..." -ForegroundColor Yellow
$result = all my homies install nerdfonts list
if ($result.ok) {
    Write-Host "✓ List command succeeded" -ForegroundColor Green
} else {
    Write-Host "✗ List command failed: $($result.error)" -ForegroundColor Red
}

# Test 2: Search for a specific font
Write-Host "`nTest 2: Searching for 'Cascadia' fonts..." -ForegroundColor Yellow
$result = all my homies install nerdfonts search "Cascadia"
if ($result.ok) {
    Write-Host "✓ Search command succeeded" -ForegroundColor Green
} else {
    Write-Host "✗ Search command failed: $($result.error)" -ForegroundColor Red
}

# Test 3: Get info about the release
Write-Host "`nTest 3: Getting release information..." -ForegroundColor Yellow
$result = all my homies install nerdfonts info
if ($result.ok) {
    Write-Host "✓ Info command succeeded" -ForegroundColor Green
} else {
    Write-Host "✗ Info command failed: $($result.error)" -ForegroundColor Red
}

# Test 4: Get info about a specific font
Write-Host "`nTest 4: Getting info about 'CascadiaCode' font..." -ForegroundColor Yellow
$result = all my homies install nerdfonts info "CascadiaCode"
if ($result.ok) {
    Write-Host "✓ Font info command succeeded" -ForegroundColor Green
} else {
    Write-Host "✗ Font info command failed: $($result.error)" -ForegroundColor Red
}

# Test 5: Test install command (without admin)
Write-Host "`nTest 5: Testing install command (should request elevation)..." -ForegroundColor Yellow
Write-Host "Note: This will request elevation if not running as admin" -ForegroundColor DarkGray
$result = all my homies install nerdfonts install "CascadiaCode"
if ($result.ok) {
    Write-Host "✓ Install command succeeded" -ForegroundColor Green
} else {
    Write-Host "✗ Install command failed: $($result.error)" -ForegroundColor Red
}

Write-Host "`nAll tests completed!" -ForegroundColor Cyan
