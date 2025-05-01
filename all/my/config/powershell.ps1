function powershell {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("setup", "info")]
        [string]$Action = "setup",
        
        [Parameter()]
        [switch]$Force = $false
    )
    # Main function
    try {
        Log-Info "Starting PowerShell configuration"
        
        # Check if we need admin rights
        if (-not (Test-IsAdmin)) {
            Log-Warning "Admin privileges needed for PowerShell Core installation"
            
            if ($Force) {
                # Auto-elevate with Force
                Invoke-Elevate -Command "all my config powershell setup -Force" -Description "Installing PowerShell Core requires administrator privileges"
                return Ok -Value $true -Message "PowerShell configuration command executed with elevation"
            } else {
                # Prompt for elevation
                Invoke-Elevate -Command "all my config powershell setup" -Prompt $true -Description "Installing PowerShell Core requires administrator privileges"
                return Ok -Value $true -Message "PowerShell configuration command executed with elevation"
            }
        }
        
        # Create a pipeline context
        $context = New-PipelineContext -PromptOnOptionalError (-not $Force) -ContinueOnError $Force
        
        # Execute the pipeline steps
        $result = Invoke-Pipeline -Steps @(
            # Step 1: Update winget and install PowerShell Core
            {
                Log-Info "Updating winget sources..."
                
                try {
                    $wingetResult = winget source update 2>&1
                    Log-Success "Winget sources updated successfully"
                    
                    Log-Info "Installing PowerShell Core with winget..."
                    $installResult = winget install --id Microsoft.Powershell --source winget 2>&1
                    
                    # Check if already installed
                    if ($installResult -match "already installed" -or $LASTEXITCODE -eq 0) {
                        Log-Success "PowerShell Core installed successfully"
                        return Ok -Value $true -Message "PowerShell Core installed successfully"
                    } else {
                        Log-Error "Failed to install PowerShell Core: $installResult"
                        return Err -Msg "Failed to install PowerShell Core" -Optional $true
                    }
                }
                catch {
                    Log-Error "Failed to install PowerShell Core: $_"
                    return Err -Msg "Failed to install PowerShell Core: $_" -Optional $true
                }
            },
            
            # Step 2: Install core modules (using our inner function)
            {
                # Install PSReadLine
                $readLineResult = Install-PSModule -ModuleName "PSReadLine"
                
                if (-not $readLineResult.ok) {
                    return $readLineResult
                }
                
                # Install Terminal-Icons
                $iconsResult = Install-PSModule -ModuleName "Terminal-Icons"
                
                if (-not $iconsResult.ok) {
                    return $iconsResult
                }
                
                return Ok -Value $true -Message "All PowerShell modules installed successfully"
            },
            
            # Step 3: Configure profile (using our inner function)
            {
                return Set-PowerShellProfile
            }
        ) -PipelineName "PowerShell Configuration"
        
        return $result
    }
    catch {
        Log-Error "Error in PowerShell configuration: $_"
        return Err "Error in PowerShell configuration: $_"
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
        return Err -Msg "Failed to install $ModuleName module: $_" -Optional $true
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
        return Err -Msg "Failed to configure PowerShell profile: $_" -Optional $true
    }
}