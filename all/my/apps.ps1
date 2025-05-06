function apps {
    param(
        [string]$Search
    )
    
    try {
        Log-Info "📋 Retrieving installed applications..."
        
        # Locations where all entries for installed software are stored
        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        )
        
        # Get all installed applications
        $installedApps = $registryPaths | ForEach-Object {
            if (Test-Path $_) {
                Get-ChildItem -Path $_ | Get-ItemProperty | Where-Object {
                    $_.DisplayName -and $_.UninstallString
                } | Select-Object -Property DisplayName, Publisher, UninstallString, InstallLocation, InstallDate
            }
        }
        
        # Filter by search term if provided
        if ($Search) {
            Log-Info "🔍 Searching for apps matching '$Search'..."
            $installedApps = $installedApps | Where-Object { 
                $_.DisplayName -like "*$Search*" 
            }
        }
        
        # Sort by display name
        $installedApps = $installedApps | Sort-Object DisplayName
        
        if (-not $installedApps) {
            if ($Search) {
                Log-Warning "No applications found matching '$Search'"
                return Ok "No applications found matching '$Search'"
            } else {
                Log-Warning "No installed applications found"
                return Ok "No installed applications found"
            }
        }
        
        # Display apps in a nice format
        Write-Host "`n🖥️ Installed Applications:" -ForegroundColor Cyan
        Write-Host "=========================" -ForegroundColor Cyan
        
        $installedApps | ForEach-Object {
            Write-Host "`n📦 $($_.DisplayName)" -ForegroundColor Green
            
            if ($_.Publisher) {
                Write-Host "   Publisher: $($_.Publisher)" -ForegroundColor Gray
            }
            
            if ($_.InstallDate) {
                # Format install date if it's in YYYYMMDD format
                if ($_.InstallDate -match '^\d{8}$') {
                    $dateStr = $_.InstallDate
                    $formattedDate = "$($dateStr.Substring(0,4))-$($dateStr.Substring(4,2))-$($dateStr.Substring(6,2))"
                    Write-Host "   Installed: $formattedDate" -ForegroundColor Gray
                } else {
                    Write-Host "   Installed: $($_.InstallDate)" -ForegroundColor Gray
                }
            }
            
            if ($_.InstallLocation) {
                Write-Host "   Location: $($_.InstallLocation)" -ForegroundColor Gray
            }
        }
        
        Write-Host "`n" 
        
        $count = @($installedApps).Count
        if ($Search) {
            Log-Success "Found $count application(s) matching '$Search'"
            return Ok "Found $count application(s) matching '$Search'" -Value $installedApps
        } else {
            Log-Success "Retrieved $count installed application(s)"
            return Ok "Retrieved $count installed application(s)" -Value $installedApps
        }
        
    } catch {
        Log-Error "Failed to retrieve installed applications: $_"
        return Err "Failed to retrieve installed applications: $_"
    }
}