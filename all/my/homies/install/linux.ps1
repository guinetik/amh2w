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
            try {
                $feature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
                if ($feature.State -ne "Enabled") {
                    Log-Info "Hyper-V is not enabled. Enabling now..."
                    all my config hyperv
                }
                else {
                    Log-Info "Hyper-V already enabled."
                }
                return Ok "Hyper-V enabled"
            }
            catch {
                $msg = "Failed to enable Hyper-V: $_"
                $stack = Get-StackTrace
                return Err $msg -Stack $stack
            }
        }
        {
            try {
                $feature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
                if ($feature.State -ne "Enabled") {
                    Log-Info "WSL is not enabled. Enabling now..."
                    all my config wslconfig enable
                }
                else {
                    Log-Info "WSL already enabled."
                }
                return Ok "WSL enabled"
            }
            catch {
                $msg = "Failed to enable WSL: $_"
                $stack = Get-StackTrace
                return Err $msg -Stack $stack
            }
        }
        {
            try {
                Log-Info "Installing WSL distro: $DistroName"
                all my homies install distro "$DistroName"
                return Ok "WSL distro installed"
            }
            catch {
                $msg = "Failed to install WSL distro: $_"
                $stack = Get-StackTrace
                return Err $msg -Stack $stack
            }
        }
        {
            # ask user for a restart
            Log-Info "Do you want to restart your computer? (Y/N)"
            $confirm = Read-Host
            if ($confirm -in @("Y", "y")) {
                Log-Info "Restarting your computer..."
                Restart-Computer
                return Ok "Restarting computer"
            }
            return Ok "No restart needed"
        }
    ) -PipelineName "Linux WSL Setup"
}
