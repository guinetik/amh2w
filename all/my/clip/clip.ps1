<#
.SYNOPSIS
Namespace entry point for clip-related functionality.

.DESCRIPTION
This function serves as the namespace entry point for all clipboard-related functionality in AMH2W.
It enables the command chain "all my clip" to access child commands like "copi", "paste", and "clipboard".

.PARAMETER Arguments
Additional arguments to pass to child commands.

.EXAMPLE
all my clip
# Shows available commands in the clip namespace

.EXAMPLE
all my clip copi "text to copy"
# Copies text to clipboard

.NOTES
File: all/my/clip/clip.ps1
Command: all my clip
#>
function clip {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    return namespace "clip" "all my clip" 
}