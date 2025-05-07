function pagefile {
    [CmdletBinding()]
    param()

    try {
        Write-Host "💾 Applying Windows pagefile configuration..." -ForegroundColor Cyan
        # Elevate if needed
        if (-not (Test-IsAdmin)) {
            Invoke-Elevate -Command "all my homies hate windows pagesys" -Description "Change pagesys" -Prompt $true
            return Ok "Elevated"
        }

        Log-Info "Disabling automatic pagefile management"
        try {
            if ($PSVersionTable.PSVersion.Major -ge 6) {
                $cs = Get-CimInstance -ClassName Win32_ComputerSystem
                $cs | Set-CimInstance -Property @{AutomaticManagedPagefile = $false}
            }
            else {
                # Traditional Windows PowerShell approach using WMI
                $cs = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
                $cs.AutomaticManagedPagefile = $false
                $cs.Put() | Out-Null
            }
        } catch {
            Log-Error $_
            return Err "Failed to disable automatic pagefile management: $_"
        }

        Log-Info "Removing existing pagefile settings"
        try {
            if ($PSVersionTable.PSVersion.Major -ge 6) {
                
            }
            else {
                Get-WmiObject Win32_PageFileSetting | ForEach-Object { $_.Delete() | Out-Null }
            }
        } catch {
            Log-Error $_
            return Err "Failed to remove existing pagefile settings: $_"
        }

        $count = Read-Host "🔢 How many pagefiles do you want to configure?"
        $count = [int]$count

        $results = @()
        for ($i = 1; $i -le $count; $i++) {
            Write-Host "`n📄 Pagefile #$i setup"
            $drive = Read-Host "  Enter drive letter (e.g., C or D)"
            $min = Read-Host "  Minimum size in MB (leave blank for system-managed)"
            $max = Read-Host "  Maximum size in MB (leave blank for system-managed)"

            $drive = $drive.TrimEnd(':', '\') + ":"
            $path = "$drive\pagefile.sys"

            $pf = ([WMIClass]"Win32_PageFileSetting").CreateInstance()
            $pf.Name = $path

            if ($min -and $max) {
                $pf.InitialSize = [int]$min
                $pf.MaximumSize = [int]$max
                $results += [PSCustomObject]@{
                    Drive       = $drive
                    Path        = $path
                    InitialSize = $min
                    MaximumSize = $max
                    ManagedByOS = $false
                }
                Log-Success "Added fixed-size pagefile: $path ($min MB - $max MB)"
            }
            else {
                $pf.InitialSize = 0
                $pf.MaximumSize = 0
                $results += [PSCustomObject]@{
                    Drive       = $drive
                    Path        = $path
                    InitialSize = 0
                    MaximumSize = 0
                    ManagedByOS = $true
                }
                Log-Success "Added system-managed pagefile: $path"
            }

            $pf.Put() | Out-Null
        }

        Write-Host "`n💾 Final pagefile configuration:" -ForegroundColor Cyan
        Show-JsonTable $results

        $reboot = Read-Host "`n🔁 Restart now to apply changes? (Y/N)"
        if ($reboot -match '^[Yy]') {
            Restart-Computer
        }

        return Ok -Value $results -Message "$($results.Count) pagefile(s) configured"
    }
    catch {
        return Err -Message "Failed to configure pagefiles: $_"
    }
}
