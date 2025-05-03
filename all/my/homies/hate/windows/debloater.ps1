# debloater.ps1
# Windows debloater utility

function debloater {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    # Check if running as admin
    if (-not (Test-IsAdmin)) {
        Log-Warning "Windows Debloater requires administrator privileges"
        
        # Elevate with prompt and keep the window open
        Invoke-Elevate -Command "all my homies hate windows debloater" -Prompt $true -Description "Windows Debloater requires administrator privileges to remove bloatware and optimize system settings" -KeepOpen $true
        
        # Exit the current non-elevated instance
        return Ok("Elevation requested")
    }
    
    # If we get here, we're running with admin privileges
    Log-Info "Running Windows Debloater..."
    
    try {
        # Run the debloater script from the web
        Log-Info "Running debloater script from https://debloat.raphi.re/"
        & ([scriptblock]::Create((Invoke-RestMethod "https://debloat.raphi.re/")))
        
        Log-Success "Windows Debloater completed successfully!"
        return Ok("Windows Debloater completed successfully")
    }
    catch {
        $errorMessage = $_.Exception.Message
        Log-Error "An error occurred during debloating: $errorMessage"
        return Err("Debloater error: $errorMessage")
    }
}
