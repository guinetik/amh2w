function paste {
    [CmdletBinding()]
    param()
    
    # This function breaks the pattern by directly outputting and exiting
    # as requested in the instructions
    
    try {
        $clipboardContent = Get-Clipboard
        
        if ($null -eq $clipboardContent) {
            Write-Host ""
        }
        
        # Output the clipboard content directly
        Write-Output $clipboardContent
    }
    catch {
        Write-Error "Failed to get clipboard content: $_"
        exit 1
    }
}