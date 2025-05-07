function updatepackages {
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet('check', 'update', 'help')]
        [string]$action = 'check',
        
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$updateFlags = ""
    )

    switch ($action) {
        'check' {
            # Check for available updates across package managers and collect flags
            $updateFlags = Invoke-SystemUpdateCheck
            
            # Prompt to install updates if there are any
            if ($updateFlags -ne "") {
                $answer = Read-Host "💡 Would you like to install the listed updates? (y/n)"
                if ($answer -eq "y") {
                    if (-not (Test-IsAdmin)) {            
                        $cmd = "all my config sysupdate update '$updateFlags'"
                        Invoke-Elevate -Command $cmd $true "Installing updates requires administrator privileges"
                        return Ok $true -Message "Elevation requested."
                    }
                    else {
                        # Run the update command with flags
                        Update-SelectedPackages $updateFlags
                    }
                }
            }
            else {
                Write-Host "`n✅ Your system is up to date! No updates available." -ForegroundColor Green
            }
        }
        'update' {
            # Run system updates with admin check
            if (-not (Test-IsAdmin)) {
                $cmd = "all my config sysupdate update '$updateFlags'"
                Invoke-Elevate -Command $cmd $true "Installing updates requires administrator privileges"
                return Ok $true -Message "Elevation requested."
            }
            else {
                # Run updates directly with the provided flags
                Update-SelectedPackages $updateFlags
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
    
    return Ok "Update operation completed" -Message "System update operation completed successfully"
}

function Invoke-SystemUpdateCheck {
    [OutputType([string])]
    param()
    
    $flags = ""
    
    # Check WinGet updates (Microsoft Store)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "`n⏳ Querying Microsoft Store updates..." -ForegroundColor Green
        $msstoreOutput = winget upgrade --include-unknown --source=msstore | Out-String
        Write-Host $msstoreOutput
        # Check if Microsoft Store has updates
        if (-not (Test-NoUpdatesPattern -Output $msstoreOutput -Pattern "No installed package found matching input criteria.")) {
            $flags += "M"
        }
        
        Write-Host "`n⏳ Querying WinGet updates..." -ForegroundColor Green
        $wingetOutput = winget upgrade --include-unknown --source=winget | Out-String
        Write-Host $wingetOutput
        # Check if WinGet has updates
        if (-not (Test-NoUpdatesPattern -Output $wingetOutput -Pattern "No installed package found matching input criteria.")) {
            # Extract number of available updates using regex
            $upgradesMatch = [regex]::Match($wingetOutput, '(\d+) upgrades available')
            if ($upgradesMatch.Success -and $upgradesMatch.Groups[1].Value -ne "0") {
                $flags += "W"
            }
        }
    }
    
    # Check Chocolatey updates
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "`n⏳ Querying Chocolatey updates..." -ForegroundColor Green
        $rawOutput = choco outdated
        $chocoOutput = $rawOutput | Out-String
        # Check if Chocolatey has updates
        if (-not (Test-NoUpdatesPattern -Output $chocoOutput -Pattern "Chocolatey has determined 0 package\(s\) are outdated")) {
            $flags += "C"
            
            # Parse and display the updates
            $updates = $rawOutput | Select-Object -Skip 2 | Where-Object { $_ -match '\w+\|' } | ForEach-Object {
                $package, $current, $available, $pinned = $_ -split '\|'   
                [PSCustomObject]@{
                    Package   = $package.Trim()
                    Current   = $current.Trim()
                    Available = $available.Trim()
                    Pinned    = $pinned.Trim()
                }
            }
            
            # Use JSON table function to display the updates
            if ($updates -and $updates.Count -gt 0) {
                $updatesJson = $updates | ConvertTo-Json
                all my homies hate json table $updatesJson
            }
        }
        else {
            Write-Host "No Chocolatey updates available." -ForegroundColor Green
        }
    }
    
    # Check Scoop updates
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "`n⏳ Querying Scoop updates..." -ForegroundColor Green
        $scoopOutput = scoop status | Out-String
        Write-Host $scoopOutput
        # Check if Scoop has updates
        if (-not (Test-NoUpdatesPattern -Output $scoopOutput -Pattern "Everything is ok!")) {
            $flags += "S"
        }
    }
    
    Write-Host ""
    Write-Host "Update flags: $flags" -ForegroundColor DarkGray
    return $flags
}

function Test-NoUpdatesPattern {
    param (
        [string]$Output,
        [string]$Pattern
    )
    
    return $Output -match $Pattern
}

function Update-SelectedPackages {
    param (
        [Parameter(Position = 0)]
        [string]$updateFlags
    )
    
    Write-Host "Update flags received: $updateFlags" -ForegroundColor DarkGray
    
    if ([string]::IsNullOrEmpty($updateFlags)) {
        Write-Host "`n✅ No updates to process." -ForegroundColor Green
        return
    }
    
    $totalSteps = $updateFlags.Length
    $currentStep = 1
    
    # Update Microsoft Store apps if needed
    if ($updateFlags.Contains("M")) {
        Write-Host "⏳ ($currentStep/$totalSteps) Updating Microsoft Store apps..." -ForegroundColor Cyan
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            & winget upgrade --all --source=msstore --include-unknown | Out-Host
        }
        $currentStep++
    }
    
    # Update WinGet apps if needed
    if ($updateFlags.Contains("W")) {
        Write-Host "`n⏳ ($currentStep/$totalSteps) Updating WinGet Store apps..." -ForegroundColor Cyan
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade --all --source=winget --include-unknown | Out-Host
        }
        $currentStep++
    }
    
    # Update Chocolatey packages if needed
    if ($updateFlags.Contains("C")) {
        Write-Host "`n⏳ ($currentStep/$totalSteps) Updating Chocolatey packages..." -ForegroundColor Cyan
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade all -y | Out-Host
        }
        $currentStep++
    }
    
    # Update Scoop packages if needed
    if ($updateFlags.Contains("S")) {
        Write-Host "`n⏳ ($currentStep/$totalSteps) Updating Scoop packages..." -ForegroundColor Cyan
        if (Get-Command scoop -ErrorAction SilentlyContinue) {
            scoop update * | Out-Host
        }
    }
    
    Write-Host "`n✅ All selected system updates completed!" -ForegroundColor Green
}
