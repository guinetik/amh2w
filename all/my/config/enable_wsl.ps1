function enable_wsl {
    [CmdletBinding()]
    param()

    # Elevate if needed
    if (-not (Test-IsAdmin)) {
        Invoke-Elevate -Command "all my homies config enable_wsl" -Description "Enable WSL" -Prompt $true
        return
    }

    Log-Info "Enabling WSL and VirtualMachinePlatform..."

    try {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -ErrorAction Stop | Out-Null
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -ErrorAction Stop | Out-Null

        Log-Info "WSL and VirtualMachinePlatform features enabled successfully."
        Write-Host "✅ WSL enabled successfully." -ForegroundColor Green
        return Ok "WSL enabled successfully."
    }
    catch {
        Write-Host "❌ WSL enable failed: $_" -ForegroundColor Red
        return Err "WSL enable failed: $_"
    }
}
