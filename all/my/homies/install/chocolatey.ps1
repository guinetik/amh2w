# chocolatey.ps1
# Installs Chocolatey package manager

function chocolatey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$ChocolateyInstall,
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$ChocolateyToolsLocation,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    if ($ChocolateyToolsLocation) {
        Write-Host "Setting ChocolateyToolsLocation to $ChocolateyToolsLocation"
        Add-EnvVar -Name "ChocolateyToolsLocation" -Value $ChocolateyToolsLocation
    }

    if ($ChocolateyInstall) {
        Write-Host "Setting ChocolateyInstall to $ChocolateyInstall"
        Add-EnvVar -Name "ChocolateyInstall" -Value $ChocolateyInstall
    }
    
    # Simply check if choco command exists
    if (Get-Command -Name choco -ErrorAction SilentlyContinue) {
        Log-Success "Chocolatey is already installed!"
        return Ok("Chocolatey is already installed")
    }
    
    # Check if running as admin
    if (-not (Test-IsAdmin)) {
        Log-Warning "Installing Chocolatey requires administrator privileges"
        
        # Elevate with prompt and keep the window open
        Invoke-Elevate -Command "all my homies install choco" -Prompt $true -Description "Installing Chocolatey requires administrator privileges to setup system-wide package management" -KeepOpen $true
        
        # Exit the current non-elevated instance
        return Ok("Elevation requested")
    }
    
    # If we get here, we're running with admin privileges
    Log-Info "Installing chocolatey..."
    
    try {
        # Official Chocolatey installation command
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        if (Get-Command -Name choco -ErrorAction SilentlyContinue) {
            Log-Success "Chocolatey has been successfully installed!"
            return Ok("Chocolatey has been successfully installed")
        } else {
            Log-Error "Chocolatey installation failed"
            return Err("Chocolatey installation failed")
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Log-Error "An error occurred during Chocolatey installation: $errorMessage"
        return Err("Installation error: $errorMessage")
    }
}
