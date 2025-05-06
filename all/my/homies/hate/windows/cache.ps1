function cache {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    # Check if running as admin
    if (-not (Test-IsAdmin)) {
        Log-Warning "Cache clearing requires administrator privileges"
        
        # Construct the original command to elevate
        $originalCommand = "all my homies hate windows cache"
        if ($Arguments.Count -gt 0) {
            $originalCommand += " $($Arguments -join ' ')"
        }
        
        # Elevate with prompt and keep the window open
        Invoke-Elevate -Command $originalCommand -Prompt $true -Description "Cache clearing requires administrator privileges to modify system files" -KeepOpen $true
        
        # Exit the current non-elevated instance
        return Ok "Elevation requested"
    }

    try {
        Log-Info "Clearing cache..."
        
        # Clear Windows Prefetch
        Log-Info "Clearing Windows Prefetch..."
        Remove-Item -Path "$env:SystemRoot\Prefetch" -Force -ErrorAction SilentlyContinue -Recurse  
        
        # Clear Windows Temp
        Log-Info "Clearing Windows Temp..."
        Remove-Item -Path "$env:SystemRoot\Temp" -Force -ErrorAction SilentlyContinue -Recurse
        
        # Clear User Temp
        Log-Info "Clearing User Temp..."
        Remove-Item -Path "$env:TEMP" -Force -ErrorAction SilentlyContinue -Recurse
        
        # Clear Internet Explorer Cache
        Log-Info "Clearing Internet Explorer Cache..."
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache" -Force -ErrorAction SilentlyContinue -Recurse
        
        Log-Success "Cache clearing completed"
        return Ok "Cache cleared successfully"
    }
    catch {
        $errorMessage = $_.Exception.Message
        Log-Error "Error clearing cache: $errorMessage"
        return Err "Cache clearing failed: $errorMessage"
    }
}
