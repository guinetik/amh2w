# jabba.ps1
# Installs Jabba Java Version Manager

function jabba {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    # Simple check if jabba is in PATH
    $jabbaInPath = $null -ne (Get-Command -Name jabba -ErrorAction SilentlyContinue)
    
    # Check if already installed by looking for jabba in the user's home directory
    $jabbaPath = Join-Path $env:USERPROFILE ".jabba"
    $jabbaInstalled = Test-Path $jabbaPath
    
    if ($jabbaInPath -and $jabbaInstalled) {
        Log-Success "Jabba is already installed!"
        return Ok("Jabba is already installed")
    }
    
    # Check if running as admin
    if (-not (Test-IsAdmin)) {
        Log-Warning "Installing Jabba requires administrator privileges"
        
        # Elevate with prompt and keep the window open
        Invoke-Elevate -Command "all my homies install jabba" -Prompt $true -Description "Installing Jabba requires administrator privileges to setup Java version management" -KeepOpen $true
        
        # Exit the current non-elevated instance
        return Ok("Elevation requested")
    }
    
    # If we get here, we're running with admin privileges
    Log-Info "Installing Jabba..."
    
    try {
        # Set security protocol
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Download the installer script to a temporary file
        $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        $result = fetch "https://github.com/Jabba-Team/jabba/raw/main/install.ps1" -Out $tempFile
        
        if(-not $result.ok) {
            $errorMessage = $result.messsage
            Log-Error "Failed to download Jabba installer script: $errorMessage"
            return $result
        }

        # Execute the installer script
        Log-Info "Executing Jabba installer script..."
        & $tempFile
        
        # Check if installation was successful by looking for jabba directory
        if (Test-Path $jabbaPath) {
            # Update PATH for the current session
            $jabbaShimPath = Join-Path $env:USERPROFILE ".jabba\bin"
            if (Test-Path $jabbaShimPath) {
                $env:Path = "$jabbaShimPath;$env:Path"
            }
            
            Log-Success "Jabba has been successfully installed!"
            return Ok("Jabba has been successfully installed")
        } else {
            Log-Error "Jabba installation failed - directory not found"
            return Err("Jabba installation failed - directory not found")
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Log-Error "An error occurred during Jabba installation: $errorMessage"
        return Err("Installation error: $errorMessage")
    }
    finally {
        # Clean up temp file if it exists
        if ($tempFile -and (Test-Path $tempFile)) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}
