# Constants for magic values
$script:PROFILE_TEMPLATE_PATH = "$PSScriptRoot\dotfiles\profile.ps1"
$script:STARSHIP_TEMPLATE_PATH = "$PSScriptRoot\dotfiles\starship.toml"
$script:WINGET_PACKAGE_ID = "Microsoft.Powershell"
$script:WINGET_SOURCE = "winget"
$script:DEFAULT_REPOSITORY = "PSGallery"

function myshell {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("setup", "profile", "starship", "info")]
        [string]$Action = "",
        
        [Parameter()]
        [switch]$Force = $false,
        
        [Parameter()]
        [switch]$Yolo = $false
    )

    switch ($Action) {
        "setup" { return Invoke-ShellSetup -Force:$Force }
        "profile" { return Invoke-ProfileSetup -Force:$Force -Yolo:$Yolo }
        "starship" { return Invoke-StarshipSetup -Force:$Force }
        "info" { return Get-ShellInfo }
        default { 
            Write-Host "Available actions:" -ForegroundColor Yellow
            Write-Host "  setup    - Install PowerShell Core and required modules" -ForegroundColor Cyan
            Write-Host "  profile  - Configure PowerShell profile with PSReadLine features" -ForegroundColor Cyan
            Write-Host "  starship - Install Starship prompt configuration" -ForegroundColor Cyan
            Write-Host "  info     - Display current PowerShell configuration information" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Usage: myshell <action> [-Force] [-Yolo]" -ForegroundColor Gray
            return Ok -Message "Usage information displayed"
        }
    }
}

function Get-ShellInfo {
    [CmdletBinding()]
    param()

    try {
        $psInfo = (psconfig -NoPrint).value
        $currentProfilePath = Get-CurrentProfilePath
        $configPath = Get-ProfileConfigPath
        $starshipConfigPath = Get-StarshipConfigPath
        
        $info = @{
            "PowerShell Core Installed" = $psInfo.CoreInstalled
            "Current PowerShell Edition" = $PSVersionTable.PSEdition
            "Current Profile Path" = $currentProfilePath
            "Profile Template Path" = $script:PROFILE_TEMPLATE_PATH
            "Profile Exists" = (Test-Path $currentProfilePath)
            "Config File Path" = $configPath
            "Config File Exists" = (Test-Path $configPath)
            "Starship Config Path" = $starshipConfigPath
            "Starship Config Exists" = (Test-Path $starshipConfigPath)
            "Starship Template Path" = $script:STARSHIP_TEMPLATE_PATH
            "Starship Installed" = $null -ne (Get-Command starship -ErrorAction SilentlyContinue)
        }
        
        # Show current config if it exists
        if (Test-Path $configPath) {
            try {
                $config = Get-Content $configPath -Raw | ConvertFrom-Json
                $info["Current Configuration"] = $config
            }
            catch {
                $info["Current Configuration"] = "Error reading config file"
            }
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
        Log-Info "Starting PowerShell Core setup"

        $psInfo = (psconfig -NoPrint).value

        if (-not $psInfo.CoreInstalled) {
            $installResult = Install-PowerShellCore -Force:$Force
            if (-not $installResult.ok) {
                return $installResult
            }
        } else {
            Log-Info "PowerShell Core already installed — skipping installation"
        }

        # Suggest switching if we're not already using pwsh
        if ($PSVersionTable.PSEdition -ne "Core" -and $psInfo.CoreInstalled) {
            Log-Warning "You're running Windows PowerShell. Consider switching to PowerShell Core (`pwsh`) for a better experience."
        }

        # Install required modules
        $modulesResult = Invoke-Pipeline -Steps @(
            { Install-PSModule -ModuleName "PSReadLine" }
            { Install-PSModule -ModuleName "Terminal-Icons" }
        ) -PipelineName "PowerShell Module Installation"

        if (-not $modulesResult.ok) {
            return $modulesResult
        }

        Log-Success "PowerShell Core setup completed successfully"
        Log-Info "To configure your profile, run: myshell profile"
        
        return Ok -Value $true -Message "PowerShell Core setup completed successfully"
    }
    catch {
        Log-Error "Error in PowerShell setup: $_"
        return Err "Error in PowerShell setup: $_"
    }
}

function Invoke-ProfileSetup {
    [CmdletBinding()]
    param(
        [switch]$Force = $false,
        [switch]$Yolo = $false
    )

    try {
        Log-Info "Starting PowerShell profile configuration"
        
        $currentProfilePath = Get-CurrentProfilePath
        $configPath = Get-ProfileConfigPath
        
        # Get user preferences for PSReadLine features
        if ($Yolo) {
            Log-Info "Yolo mode enabled - enabling all PSReadLine features"
            $config = @{
                HistorySearch = $true
                PredictiveIntelliSense = $true
                EnhancedKeybindings = $true
                VisualEnhancements = $true
                SmartQuotes = $true
                AdvancedHistory = $true
            }
        }
        else {
            $config = Get-PSReadLineFeatureChoices
        }
        
        # Save configuration to JSON file
        $configResult = Save-ProfileConfig -Config $config -ConfigPath $configPath
        if (-not $configResult.ok) {
            return $configResult
        }
        
        # Prompt before profile overwrite (unless Force or Yolo)
        if (-not $Force -and -not $Yolo) {
            Log-Warning "This will update your PowerShell profile at:"
            Write-Host "`n$currentProfilePath`n" -ForegroundColor Yellow
            $confirm = Read-Host "Do you want to continue? (Y/N)"
            if ($confirm -notin @("Y", "y")) {
                return Err "Aborted by user"
            }
        }

        # Install the profile template
        return Install-ProfileTemplate -ProfilePath $currentProfilePath
    }
    catch {
        Log-Error "Error in profile configuration: $_"
        return Err "Error in profile configuration: $_"
    }
}

function Get-CurrentProfilePath {
    [CmdletBinding()]
    param()
    
    # Use PowerShell's built-in $PROFILE variable to get the current profile path
    # This respects user customizations and PowerShell version differences
    if ($PROFILE) {
        return $PROFILE
    }
    
    # Fallback for edge cases where $PROFILE might not be set
    if ($PSVersionTable.PSEdition -eq "Core") {
        return "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    } else {
        return "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    }
}

function Get-ProfileConfigPath {
    [CmdletBinding()]
    param()
    
    $profileDir = Split-Path (Get-CurrentProfilePath)
    return Join-Path $profileDir "AMH2W-Profile-Config.json"
}

function Get-PSReadLineFeatureChoices {
    [CmdletBinding()]
    param()
    
    $availableFeatures = @(
        @{ Key = "HistorySearch"; Description = "Enhanced history search with Up/Down arrows" }
        @{ Key = "PredictiveIntelliSense"; Description = "Predictive IntelliSense with history and plugins" }
        @{ Key = "EnhancedKeybindings"; Description = "Enhanced key bindings (Ctrl+D, Ctrl+W, etc.)" }
        @{ Key = "VisualEnhancements"; Description = "Syntax highlighting with custom colors" }
        @{ Key = "SmartQuotes"; Description = "Smart quote and bracket insertion" }
        @{ Key = "AdvancedHistory"; Description = "Advanced history configuration" }
    )
    
    $config = @{}
    
    Log-Info "PSReadLine Feature Configuration"
    Write-Host "Tab completion is enabled by default. Choose additional features:" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($feature in $availableFeatures) {
        $options = @("Enable", "Skip")
        $choice = Get-SelectionFromUser -Options $options -Prompt "[$($feature.Key)] $($feature.Description)"
        
        $config[$feature.Key] = ($choice -eq "Enable")
    }
    
    return $config
}

function Save-ProfileConfig {
    [CmdletBinding()]
    param(
        [hashtable]$Config,
        [string]$ConfigPath
    )
    
    try {
        # Ensure the directory exists
        $configDir = Split-Path -Parent $ConfigPath
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        # Convert to JSON and save
        $json = $Config | ConvertTo-Json -Depth 10
        Set-Content -Path $ConfigPath -Value $json -Force
        
        Log-Success "Configuration saved to: $ConfigPath"
        
        # Show what was configured
        $enabledFeatures = $Config.GetEnumerator() | Where-Object { $_.Value -eq $true } | ForEach-Object { $_.Key }
        if ($enabledFeatures.Count -gt 0) {
            Log-Info "Enabled features: $($enabledFeatures -join ', ')"
        } else {
            Log-Info "Only default tab completion will be enabled"
        }
        
        return Ok -Value $ConfigPath -Message "Configuration saved successfully"
    }
    catch {
        Log-Error "Failed to save configuration: $_"
        return Err -Message "Failed to save configuration: $_" -Optional $true
    }
}

function Install-ProfileTemplate {
    [CmdletBinding()]
    param(
        [string]$ProfilePath
    )
    
    try {
        # Ensure the directory exists
        $profileDir = Split-Path -Parent $ProfilePath
        if (-not (Test-Path $profileDir)) {
            Log-Info "Creating profile directory: $profileDir"
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        
        # Create backup of existing profile
        if (Test-Path $ProfilePath) {
            $backupPath = "$ProfilePath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Log-Info "Creating backup of existing profile at: $backupPath"
            Copy-Item -Path $ProfilePath -Destination $backupPath -Force
        }
        
        # Check if template exists
        if (-not (Test-Path $script:PROFILE_TEMPLATE_PATH)) {
            Log-Error "Profile template not found at: $script:PROFILE_TEMPLATE_PATH"
            return Err -Message "Profile template file not found" -Optional $true
        }
        
        # Copy template to profile location
        Copy-Item -Path $script:PROFILE_TEMPLATE_PATH -Destination $ProfilePath -Force
        
        # Update the date placeholder in the copied profile
        $profileContent = Get-Content -Path $ProfilePath -Raw
        $profileContent = $profileContent -replace '\$\(Get-Date\)', (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        Set-Content -Path $ProfilePath -Value $profileContent -Force
        
        Log-Success "PowerShell profile installed successfully at: $ProfilePath"
        Log-Info "Restart your PowerShell session to apply the new profile configuration"
        
        return Ok -Value $ProfilePath -Message "PowerShell profile installed successfully"
    }
    catch {
        Log-Error "Failed to install profile template: $_"
        return Err -Message "Failed to install profile template: $_" -Optional $true
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
    $installResult = winget install --id $script:WINGET_PACKAGE_ID --source $script:WINGET_SOURCE 2>&1
    if ($installResult -match "already installed" -or $LASTEXITCODE -eq 0) {
        Log-Success "PowerShell Core installed successfully"
        return Ok -Value $true -Message "PowerShell Core installed successfully"
    } else {
        Log-Error "Failed to install PowerShell Core: $installResult"
        return Err -Message "PowerShell Core installation failed" -Optional $true
    }
}

function Install-PSModule {
    param(
        [string]$ModuleName,
        [string]$Repository = $script:DEFAULT_REPOSITORY
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

function Invoke-StarshipSetup {
    [CmdletBinding()]
    param(
        [switch]$Force = $false
    )

    try {
        Log-Info "Starting Starship prompt configuration"
        
        # Check if starship is installed
        if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
            Log-Warning "Starship is not installed. Install it first using:"
            Write-Host "winget install starship" -ForegroundColor Yellow
            Write-Host "or visit: https://starship.rs/guide/#🚀-installation" -ForegroundColor Cyan
            return Err -Message "Starship is not installed" -Optional $true
        }
        
        $starshipConfigPath = Get-StarshipConfigPath
        
        # Prompt before config overwrite (unless Force)
        if (-not $Force) {
            Log-Warning "This will install the AMH2W Starship configuration at:"
            Write-Host "`n$starshipConfigPath`n" -ForegroundColor Yellow
            
            if (Test-Path $starshipConfigPath) {
                Write-Host "This will overwrite your existing Starship configuration." -ForegroundColor Red
            }
            
            $confirm = Read-Host "Do you want to continue? (Y/N)"
            if ($confirm -notin @("Y", "y")) {
                return Err "Aborted by user"
            }
        }

        # Install the starship configuration
        return Install-StarshipConfig -ConfigPath $starshipConfigPath
    }
    catch {
        Log-Error "Error in starship configuration: $_"
        return Err "Error in starship configuration: $_"
    }
}

function Get-StarshipConfigPath {
    [CmdletBinding()]
    param()
    
    # Starship config location on Windows
    $configDir = Join-Path $env:USERPROFILE ".config"
    return Join-Path $configDir "starship.toml"
}

function Install-StarshipConfig {
    [CmdletBinding()]
    param(
        [string]$ConfigPath
    )
    
    try {
        # Ensure the .config directory exists
        $configDir = Split-Path -Parent $ConfigPath
        if (-not (Test-Path $configDir)) {
            Log-Info "Creating config directory: $configDir"
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        # Create backup of existing config
        if (Test-Path $ConfigPath) {
            $backupPath = "$ConfigPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Log-Info "Creating backup of existing starship config at: $backupPath"
            Copy-Item -Path $ConfigPath -Destination $backupPath -Force
        }
        
        # Check if template exists
        if (-not (Test-Path $script:STARSHIP_TEMPLATE_PATH)) {
            Log-Error "Starship template not found at: $script:STARSHIP_TEMPLATE_PATH"
            return Err -Message "Starship template file not found" -Optional $true
        }
        
        # Copy template to config location
        Copy-Item -Path $script:STARSHIP_TEMPLATE_PATH -Destination $ConfigPath -Force
        
        Log-Success "Starship configuration installed successfully at: $ConfigPath"
        Log-Info "Restart your PowerShell session to see the new prompt"
        Log-Info "The configuration includes:"
        Write-Host "  • Tokyo Night color scheme" -ForegroundColor Cyan
        Write-Host "  • Git status integration" -ForegroundColor Cyan
        Write-Host "  • Language/runtime detection (Node.js, Python, Java, etc.)" -ForegroundColor Cyan
        Write-Host "  • Command duration display" -ForegroundColor Cyan
        Write-Host "  • Beautiful Unicode prompt styling" -ForegroundColor Cyan
        
        return Ok -Value $ConfigPath -Message "Starship configuration installed successfully"
    }
    catch {
        Log-Error "Failed to install starship configuration: $_"
        return Err -Message "Failed to install starship configuration: $_" -Optional $true
    }
}