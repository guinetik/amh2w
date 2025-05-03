function hyperv {
    [CmdletBinding()]
    param()

    # Elevate if needed
    if (-not (Test-IsAdmin)) {
        Invoke-Elevate -Command "all my homies config hyperv" -Description "Enable Hyper-V" -Prompt $true
        return
    }

    Log-Info "Enabling Hyper-V platform..."

    try {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart -ErrorAction Stop | Out-Null

        Log-Info "✅ Hyper-V feature enabled successfully."
        return Ok "Hyper-V enabled successfully."
    }
    catch {
        Log-Error "❌ Hyper-V enable failed: $_"
        # trying the hacky way
        Log-Info "Trying the hacky way..."
        try {
            Install-HyperV-Not-For-The-Faint-Of-Heart
            Log-Info "✅ Hyper-V feature enabled successfully."
            return Ok "Hyper-V enabled successfully."
        }
        catch {
            Log-Error "❌ Hyper-V enable failed: $_"
            return Err "Hyper-V enable failed: $_"
        }
    }
}

function Install-HyperV-Not-For-The-Faint-Of-Heart {
    Write-Host "🔄 Trying with DISM..."
    try {
        DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V
    }
    catch {
        Log-Error "❌ Hyper-V enable failed: $_"
    }
    Write-Host "🔄 Trying the hacky way..."
    try {
        Get-ChildItem $Env:SystemRoot\servicing\Packages\*Hyper-V*.mum | ForEach-Object { 
            dism /online /norestart /add-package:"$($_.FullName)"
        }
        dism /online /enable-feature /featurename:Microsoft-Hyper-V -All /LimitAccess /All
    }
    catch {
        Log-Error "❌ Hyper-V enable failed: $_"
    }
    return Err "yeah bro we tried but theres nothing else we can do ask gpt or something 🥲"
}
