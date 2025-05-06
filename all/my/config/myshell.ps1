function myshell {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("setup", "info")]
        [string]$Action = "",
        
        [Parameter()]
        [switch]$Force = $false
    )

    switch ($Action) {
        "setup" { return Invoke-ShellSetup -Force:$Force }
        "info" { return Get-ShellInfo }
        default { return Invoke-ShellSetup -Force:$Force }
    }
}

function Get-ShellInfo {
    [CmdletBinding()]
    param()

    try {
        $psInfo = (psconfig -NoPrint).value
        $info = @{
            "PowerShell Core Installed" = $psInfo.CoreInstalled
            "Current PowerShell Edition" = $PSVersionTable.PSEdition
            "Profile Path" = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        }
        
        return Ok -Value $info -Message "PowerShell configuration information"
    }
    catch {
        Log-Error "Error getting shell information: $_"
        return Err -Message "Error getting shell information: $_" -Optional $true
    }
}

function Invoke-ShellSetup {
    [CmdletBinding()]
    param(
        [switch]$Force = $false
    )

    try {
        Log-Info "Starting PowerShell configuration"

        $psInfo = (psconfig -NoPrint).value

        if (-not $psInfo.CoreInstalled) {
            return Install-PowerShellCore -Force:$Force
        } else {
            Log-Info "PowerShell Core already installed — skipping installation"
        }

        # Suggest switching if we're not already using pwsh
        if ($PSVersionTable.PSEdition -ne "Core" -and $psInfo.CoreInstalled) {
            Log-Warning "You're running Windows PowerShell. Consider switching to PowerShell Core (`pwsh`) for a better experience."
        }

        # Prompt before profile overwrite
        Log-Warning "This will overwrite your PowerShell profile for Core at:"
        Write-Host "`n$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`n" -ForegroundColor Yellow
        if (-not $Force) {
            $confirm = Read-Host "Do you want to continue? (Y/N)"
            if ($confirm -notin @("Y", "y")) {
                return Err "Aborted by user"
            }
        }

        # Install modules
        $modulesResult = Invoke-Pipeline -Steps @(
            { Install-PSModule -ModuleName "PSReadLine" }
            { Install-PSModule -ModuleName "Terminal-Icons" }
        ) -PipelineName "PowerShell Module Installation"

        if (-not $modulesResult.ok) {
            return $modulesResult
        }

        # Configure profile
        return Set-PowerShellProfile
    }
    catch {
        Log-Error "Error in PowerShell configuration: $_"
        return Err "Error in PowerShell configuration: $_"
    }
}

function Install-PowerShellCore {
    [CmdletBinding()]
    param(
        [switch]$Force = $false
    )

    Log-Warning "PowerShell Core not found — will attempt to install"

    if (-not (Test-IsAdmin)) {
        Log-Warning "Admin privileges needed for PowerShell Core installation"

        $cmd = if ($Force) { "all my config shell setup -Force" } else { "all my config shell setup" }
        Invoke-Elevate -Command $cmd -Prompt (-not $Force) -Description "Installing PowerShell Core requires administrator privileges"
        return Ok -Value $true -Message "PowerShell configuration command executed with elevation"
    }

    Log-Info "Installing PowerShell Core using winget..."
    $installResult = winget install --id Microsoft.Powershell --source winget 2>&1
    if ($installResult -match "already installed" -or $LASTEXITCODE -eq 0) {
        Log-Success "PowerShell Core installed successfully"
        return Ok -Value $true -Message "PowerShell Core installed successfully"
    } else {
        Log-Error "Failed to install PowerShell Core: $installResult"
        return Err -Message "PowerShell Core installation failed" -Optional $true
    }
}

# Inner functions for reusable components
function Install-PSModule {
    param(
        [string]$ModuleName,
        [string]$Repository = "PSGallery"
    )
    
    Log-Info "Checking for module: $ModuleName..."
    
    if (Get-Module -Name $ModuleName -ListAvailable) {
        Log-Success "$ModuleName module is already installed"
        return Ok -Value $true -Message "$ModuleName is already installed"
    }
    
    try {
        Log-Info "Installing $ModuleName module..."
        Install-Module -Name $ModuleName -Repository $Repository -Force -Scope CurrentUser
        Log-Success "$ModuleName module installed successfully"
        return Ok -Value $true -Message "$ModuleName module installed successfully"
    }
    catch {
        Log-Error "Failed to install $ModuleName module: $_"
        return Err -Message "Failed to install $ModuleName module: $_" -Optional $true
    }
}

function Set-PowerShellProfile {
    Log-Info "Configuring PowerShell profile..."
    
    try {
        # Get the profile path
        $profilePath = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        $profileDir = Split-Path -Parent $profilePath
        
        # Ensure the directory exists
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        
        # Profile content
        $profileContent = @"
# PowerShell Profile configured by AMH2W on $(Get-Date)

# PSReadLine configuration
if (`$host.Name -eq 'ConsoleHost') {
Import-Module PSReadLine
}

# Winget tab completion
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
param(`$wordToComplete, `$commandAst, `$cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = `$OutputEncoding = [System.Text.Utf8Encoding]::new()
    `$Local:word = `$wordToComplete.Replace('"', '""')
    `$Local:ast = `$commandAst.ToString().Replace('"', '""')
    winget complete --word="`$Local:word" --commandline "`$Local:ast" --position `$cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(`$_, `$_, 'ParameterValue', `$_)
    }
}

# Terminal Icons for file display
Import-Module -Name Terminal-Icons
"@
        
        # Write the profile
        Set-Content -Path $profilePath -Value $profileContent -Force
        
        Log-Success "PowerShell profile configured successfully at $profilePath"
        return Ok -Value $profilePath -Message "PowerShell profile configured successfully"
    }
    catch {
        Log-Error "Failed to configure PowerShell profile: $_"
        return Err -Message "Failed to configure PowerShell profile: $_" -Optional $true
    }
}