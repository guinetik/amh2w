function copi {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    # Handle different input scenarios
    if ($Arguments.Count -eq 0) {
        return Err "No content to copy. Usage: all my clip copi <content>"
    }
    
    # Combine all arguments into a single string
    $contentToCopy = $Arguments -join ' '
    
    try {
        # Check if we're receiving pipeline input
        if ($input) {
            # Handle pipeline input
            $pipelineContent = @()
            $input | ForEach-Object { $pipelineContent += $_ }
            $contentToCopy = $pipelineContent -join "`n"
        }
        
        # Set the clipboard content
        Set-Clipboard -Value $contentToCopy
        
        # Add to clipboard history
        Add-ClipboardHistory -Content $contentToCopy
        
        # Show preview of what was copied
        $preview = if ($contentToCopy.Length -gt 100) {
            "$($contentToCopy.Substring(0, 97))..."
        } else {
            $contentToCopy
        }
        
        Log-Info "📋 Copied to clipboard: $preview"
        
        return Ok -Value $contentToCopy -Message "Content copied to clipboard"
    }
    catch {
        Log-Error "❌ Failed to copy to clipboard: $_"
        return Err "Failed to copy to clipboard: $_"
    }
}
