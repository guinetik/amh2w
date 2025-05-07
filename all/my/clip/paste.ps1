<#
.SYNOPSIS
Outputs the current clipboard contents directly to the console.

.DESCRIPTION
Retrieves and outputs the current contents of the system clipboard.
This function is designed to be used in pipelines or redirections,
and unlike most AMH2W commands, it outputs content directly rather
than returning a result object.

.OUTPUTS
The contents of the clipboard as raw output.

.EXAMPLE
all my clip paste
# Displays the current clipboard contents

.EXAMPLE
all my clip paste > file.txt
# Saves the clipboard contents to file.txt

.EXAMPLE
all my clip paste | Select-String "pattern"
# Pipes clipboard contents to Select-String for filtering

.NOTES
File: all/my/clip/paste.ps1
Command: all my clip paste

This function intentionally breaks the AMH2W pattern by directly
outputting content rather than returning a result object, making
it more useful in pipelines and redirections.
#>
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