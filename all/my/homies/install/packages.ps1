function Install-Scoop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$Force,

        [Parameter(Mandatory = $false)]
        [string]$ScoopInstall
    )
    if ($ScoopInstall) {
        try {
            Add-EnvVar -Name "SCOOP" -Value $ScoopInstall
            Log-Info "Added SCOOP to environment variables"
        }
        catch {
            return Err -Message "Failed to add SCOOP to environment variables: $_"
        }
    }
    # Check if scoop is already installed unless force is specified
    if (-not $Force -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
        return Ok -Message "Scoop is already installed"
    }
    # Launch the scoop installer
    try {
        Log-Warning "⏳ Installing Scoop...This may take a while."
        $cmd = 'iwr https://get.scoop.sh | iex'
        Invoke-Powershell $cmd "-NoExit"
        Write-Host "📎 After the installer is done, remember to restart your PowerShell session." -ForegroundColor DarkYellow
        return Ok "Scoop installer launched in new PowerShell window."
    }
    catch {
        return Err "Failed to launch scoop installer: $_"
    }
}

function Install-Chocolatey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$ChocolateyInstall,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$ChocolateyToolsLocation,

        [Parameter(Mandatory = $false, Position = 2)]
        [bool]$Force
    )

    # Check if choco is already installed unless force is specified
    if (-not $Force -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        return Ok -Message "Chocolatey is already installed"
    }

    # Check if running as admin
    if (-not (Test-IsAdmin)) {
        Log-Warning "Installing Chocolatey requires administrator privileges"
        Invoke-Elevate -Command "all my homies install packages choco $ChocolateyInstall $ChocolateyToolsLocation $Force" -Prompt $true -Description "Installing Chocolatey requires administrator privileges" -KeepOpen $true
        return Ok -Message "Elevation requested"
    }

    # Set custom installation paths if provided
    if ($ChocolateyInstall) {
        try {
            Add-EnvVar -Name "ChocolateyInstall" -Value $ChocolateyInstall
            Log-Info "ChocolateyInstall added to environment variables"
        }
        catch {
            return Err -Message "Failed to add ChocolateyInstall to environment variables: $_"
        }
    }

    if ($ChocolateyToolsLocation) {
        try {
            Add-EnvVar -Name "ChocolateyToolsLocation" -Value $ChocolateyToolsLocation
            Log-Info "ChocolateyToolsLocation added to environment variables"
        }
        catch {
            return Err -Message "Failed to add ChocolateyToolsLocation to environment variables: $_"
        }
    }

    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            return Ok -Message "Chocolatey installed successfully"
        }
        else {
            return Err -Message "Chocolatey installation failed"
        }
    }
    catch {
        return Err -Message "Failed to install Chocolatey: $_"
    }
}

function Install-Winget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$Force
    )

    # Check if winget is already installed unless force is specified
    if (-not $Force -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        return Ok -Message "Winget is already installed"
    }

    # Winget comes with Windows 10/11, so we just need to check if it's available
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        return Ok -Message "Winget is available"
    }
    else {
        return Err -Message "Winget is not available. Please ensure you're running Windows 10 version 1809 or later"
    }
}

function packages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('scoop', 'choco', 'winget')]
        [string]$Flavour,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$InstallLocation,

        [Parameter(Mandatory = $false, Position = 2)]
        [string]$ToolsLocation,

        [Parameter(Mandatory = $false, Position = 3)]
        [object]$Force,
        
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Arguments
    )

    $Force = Truthy $Force

    $result = switch ($Flavour) {
        'scoop' { 
            Install-Scoop -Force:$Force -ScoopInstall $InstallLocation
        }
        'choco' { 
            Install-Chocolatey -Force:$Force -ChocolateyInstall $InstallLocation -ChocolateyToolsLocation $ToolsLocation
        }
        'winget' { 
            Install-Winget -Force:$Force
        }
    }

    return $result
}
