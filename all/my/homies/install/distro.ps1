function distro {
    [CmdletBinding()]
    param (
        [string]$DistroName = "Ubuntu-22.04"
    )

    # Elevate if needed
    if (-not (Test-IsAdmin)) {
        Invoke-Elevate -Command "all my homies install distro '$DistroName'" -Description "Install Linux Distro into WSL" -Prompt $true
        return
    }

    # Check if WSL is installed
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    if ($wslFeature.State -ne "Enabled") {
        Log-Warning "⚠️ WSL is not enabled. Please run: all my homies config enable_wsl"
        return Err "WSL not installed. Aborting Linux installation."
    }

    Log-Info "Installing $DistroName..."

    try {
        wsl --install -d $DistroName | Out-Null

        Start-Sleep -Seconds 5

        wsl --set-version $DistroName 2 | Out-Null
        wsl --set-default $DistroName | Out-Null

        Log-Info "✅ $DistroName installed and set as default under WSL 2."
        return Ok "$DistroName is ready to go."
    }
    catch {
        Log-Error "❌ $DistroName installation failed: $_"
        return Err "$DistroName installation failed: $_"
    }
}
