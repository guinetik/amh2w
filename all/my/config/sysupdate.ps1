function sysupdate {
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('check', 'update', 'help')]
        [string]$action = 'check'
    )

    switch ($action) {
        'check' {
            # Check for available updates across package managers
            Check-SystemUpdates
            
            # Prompt to install updates
            $answer = Read-Host "💡 Would you like to install the listed updates? (y/n)"
            if ($answer -eq "y") {
                if (-not (Test-IsAdmin)) {            
                    $cmd = "all my config sysupdate update"
                    Invoke-Elevate -Command $cmd -Prompt -Description "Installing updates requires administrator privileges"
                    return Ok $true -Message "Elevation requested."
                } else {
                    # Run the update command
                    Update-AllPackages
                }
            }
        }
        'update' {
            # Run system updates with admin check
            if (-not (Test-IsAdmin)) {            
                $cmd = "all my config sysupdate update"
                Invoke-Elevate -Command $cmd -Prompt -Description "Installing updates requires administrator privileges"
                return Ok $true -Message "Elevation requested."
            } else {
                # Run updates directly
                Update-AllPackages
            }
        }
        'help' {
            Write-Host "`nSystem Update Commands:" -ForegroundColor Cyan
            Write-Host "  check  - Check for available updates (default)" -ForegroundColor White
            Write-Host "  update - Install all available updates" -ForegroundColor White
            Write-Host "  help   - Display this help message" -ForegroundColor White
            Write-Host "`nUsage:" -ForegroundColor Cyan
            Write-Host "  all my config sysupdate [check|update|help]" -ForegroundColor White
            Write-Host "`nExamples:" -ForegroundColor Cyan
            Write-Host "  all my config sysupdate" -ForegroundColor White
            Write-Host "  all my config sysupdate update" -ForegroundColor White
        }
    }
    
    return Ok "Update operation completed" -Message "System update completed successfully"
}

function Check-SystemUpdates {
    # Check WinGet updates (Microsoft Store)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "`n⏳ Querying Microsoft Store updates..." -ForegroundColor Green
        winget upgrade --include-unknown --source=msstore | Out-Host
        Write-Host "`n⏳ Querying WinGet updates..." -ForegroundColor Green
        winget upgrade --include-unknown --source=winget | Out-Host
    }
    
    # Check Chocolatey updates
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "`n⏳ Querying Chocolatey updates..." -ForegroundColor Green
        $rawOutput = choco outdated
        $updates = $rawOutput | Select-Object -Skip 2 | Where-Object { $_ -match '\w+\|' } | ForEach-Object {
            $package, $current, $available, $pinned = $_ -split '\|'   
            [PSCustomObject]@{
                Package = $package.Trim()
                Current = $current.Trim()
                Available = $available.Trim()
                Pinned = $pinned.Trim()
            }
        }
        
        # Use JSON table function to display the updates
        if ($updates -and $updates.Count -gt 0) {
            $updatesJson = $updates | ConvertTo-Json
            all my homies hate json table $updatesJson
        } else {
            Write-Host "No Chocolatey updates available." -ForegroundColor Green
        }
    }
    
    # Check Scoop updates
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "`n⏳ Querying Scoop updates..." -ForegroundColor Green
        scoop status | Out-Host
    }
    
    Write-Host ""
}

function Update-AllPackages {
    Write-Host "⏳ (1/4) Updating Microsoft Store apps..." -ForegroundColor Cyan
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget upgrade --all --source=msstore --include-unknown
    }
    
    Write-Host "`n⏳ (2/4) Updating WinGet Store apps..." -ForegroundColor Cyan
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget upgrade --all --source=winget --include-unknown
    }
    
    Write-Host "`n⏳ (3/4) Updating Chocolatey packages..." -ForegroundColor Cyan
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        choco upgrade all -y
    }
    
    Write-Host "`n⏳ (4/4) Updating Scoop packages..." -ForegroundColor Cyan
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        scoop update *
    }
    
    Write-Host "`n✅ All system updates completed!" -ForegroundColor Green
}
