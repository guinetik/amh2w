<#
.SYNOPSIS
Copies text to the clipboard and records it in clipboard history.

.DESCRIPTION
Copies the provided text to the system clipboard and adds it to the AMH2W clipboard
history for later retrieval. Can handle both command-line arguments and pipeline input.

.PARAMETER Arguments
The text to copy to the clipboard. Multiple arguments are joined with spaces.

.OUTPUTS
An Ok result object with the copied content as the value, or an Err result object
if the operation fails.

.EXAMPLE
all my clip copi "Hello, world!"
# Copies "Hello, world!" to the clipboard

.EXAMPLE
all my clip copi This is a test
# Copies "This is a test" to the clipboard

.EXAMPLE
Get-Content file.txt | all my clip copi
# Copies the contents of file.txt to the clipboard

.NOTES
File: all/my/clip/copi.ps1
Command: all my clip copi
#>
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
