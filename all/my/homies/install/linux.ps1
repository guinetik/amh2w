function linux {
    [CmdletBinding()]
    param (
        [string]$DistroName = "Ubuntu-22.04"
    )

    # Elevate if needed
    if (-not (Test-IsAdmin)) {
        Invoke-Elevate -Command "all my homies install linux '$DistroName'" -Description "Install Linux WSL Distro" -Prompt $true
        return
    }

    # Use the pipeline to run steps
    Invoke-Pipeline -Steps @(
        {
            $feature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
            if ($feature.State -ne "Enabled") {
                Log-Info "Hyper-V is not enabled. Enabling now..."
                all my config hyperv
            } else {
                Log-Info "Hyper-V already enabled."
            }
        }
        {
            $feature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
            if ($feature.State -ne "Enabled") {
                Log-Info "WSL is not enabled. Enabling now..."
                all my config enable_wsl
            } else {
                Log-Info "WSL already enabled."
            }
        }
        {
            Log-Info "Installing WSL distro: $DistroName"
            all my homies install distro "$DistroName"
        }
        {
            # ask user for a restart
            Log-Info "Do you want to restart your computer? (Y/N)"
            $confirm = Read-Host
            if ($confirm -in @("Y", "y")) {
                Log-Info "Restarting your computer..."
                Restart-Computer
            }
        }
    ) -PipelineName "Linux WSL Setup"
}
