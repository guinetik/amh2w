function profile {
    Write-Host "Refreshing environment..." -ForegroundColor Cyan
    refreshenv
    Write-Host "Reloading profile..." -ForegroundColor Cyan
    . $profile
}
