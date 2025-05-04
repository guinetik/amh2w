# Example usage of the nerdfonts command

# Load the AMH2W module
$modulePath = Join-Path (Split-Path $PSScriptRoot) "loader.ps1"
. $modulePath

Write-Host "`n=== Nerd Fonts Command Examples ===" -ForegroundColor Cyan

# Example 1: List all available fonts
Write-Host "`nExample 1: Listing all available Nerd Fonts..." -ForegroundColor Yellow
all my homies install nerdfonts list

# Wait for user input
Write-Host "`nPress Enter to continue..." -ForegroundColor DarkGray
$null = Read-Host

# Example 2: Search for specific fonts
Write-Host "`nExample 2: Searching for 'Mono' fonts..." -ForegroundColor Yellow
all my homies install nerdfonts search "Mono"

# Wait for user input
Write-Host "`nPress Enter to continue..." -ForegroundColor DarkGray
$null = Read-Host

# Example 3: Get release information
Write-Host "`nExample 3: Getting release information..." -ForegroundColor Yellow
all my homies install nerdfonts info

# Wait for user input
Write-Host "`nPress Enter to continue..." -ForegroundColor DarkGray
$null = Read-Host

# Example 4: Get information about a specific font
Write-Host "`nExample 4: Getting information about 'JetBrainsMono'..." -ForegroundColor Yellow
all my homies install nerdfonts info "JetBrainsMono"

# Example 5: Install a font (commented out to avoid elevation prompt)
Write-Host "`nExample 5: To install a font, use:" -ForegroundColor Yellow
Write-Host "all my homies install nerdfonts install <FontName>" -ForegroundColor Cyan
Write-Host "For example: " -ForegroundColor Yellow
Write-Host "all my homies install nerdfonts install FiraCode" -ForegroundColor Cyan
Write-Host "`nNote: Installation requires administrator privileges." -ForegroundColor DarkGray

# Example 6: Force refresh the cache
Write-Host "`nExample 6: To force refresh the cache, use:" -ForegroundColor Yellow
Write-Host "all my homies install nerdfonts list -ForceRefresh" -ForegroundColor Cyan

Write-Host "`nAll examples completed!" -ForegroundColor Green
