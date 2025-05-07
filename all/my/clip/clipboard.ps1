<#
.SYNOPSIS
Provides clipboard history management functionality.

.DESCRIPTION
This module implements a clipboard history system that allows users to view, retrieve,
and manage their clipboard history. It maintains the last 50 clipboard items by default.

.NOTES
File: all/my/clip/clipboard.ps1
Command: all my clip clipboard
#>

# Global variable to store clipboard history
if (-not (Test-Path variable:global:AMH2W_CLIPBOARD_HISTORY)) {
    $global:AMH2W_CLIPBOARD_HISTORY = @()
    $global:AMH2W_CLIPBOARD_MAX_HISTORY = 50  # Maximum items to keep in history
}

<#
.SYNOPSIS
Adds an item to the clipboard history.

.DESCRIPTION
Adds a new item to the clipboard history, maintaining the maximum history size.
Items are added to the beginning of the history (newest first).

.PARAMETER Content
The content to add to the clipboard history.

.NOTES
This is an internal helper function used by the clipboard commands.
#>
function Add-ClipboardHistory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    # Add to beginning of history
    $global:AMH2W_CLIPBOARD_HISTORY = @($Content) + $global:AMH2W_CLIPBOARD_HISTORY
    
    # Keep only the last N items
    if ($global:AMH2W_CLIPBOARD_HISTORY.Count -gt $global:AMH2W_CLIPBOARD_MAX_HISTORY) {
        $global:AMH2W_CLIPBOARD_HISTORY = $global:AMH2W_CLIPBOARD_HISTORY[0..($global:AMH2W_CLIPBOARD_MAX_HISTORY - 1)]
    }
}

<#
.SYNOPSIS
Manages and displays clipboard history.

.DESCRIPTION
Provides access to clipboard history, allowing users to view, retrieve, and clear
their clipboard history. Without arguments, it displays the current clipboard history.

.PARAMETER Arguments
Command arguments that specify the action to perform.
Supported actions: clear, get, count

.OUTPUTS
An Ok or Err result object containing the operation result.

.EXAMPLE
all my clip clipboard
# Displays the current clipboard history

.EXAMPLE
all my clip clipboard clear
# Clears the clipboard history

.EXAMPLE
all my clip clipboard get 2
# Retrieves the second item from clipboard history and copies it to the clipboard

.EXAMPLE
all my clip clipboard count
# Shows the number of items in the clipboard history
#>
function clipboard {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    # Default action: show clipboard history
    if ($Arguments.Count -eq 0) {
        if ($global:AMH2W_CLIPBOARD_HISTORY.Count -eq 0) {
            Log-Info "📋 Clipboard history is empty"
            return Ok -Value @() -Message "Clipboard history is empty"
        }
        
        Log-Info "📋 Clipboard History (newest first):"
        for ($i = 0; $i -lt $global:AMH2W_CLIPBOARD_HISTORY.Count; $i++) {
            $item = $global:AMH2W_CLIPBOARD_HISTORY[$i]
            $preview = if ($item.Length -gt 50) { "$($item.Substring(0, 47))..." } else { $item }
            Write-Host "$($i + 1). $preview" -ForegroundColor Cyan
        }
        
        return Ok -Value $global:AMH2W_CLIPBOARD_HISTORY -Message "Displayed clipboard history"
    }
    
    # Handle actions
    switch ($Arguments[0]) {
        "clear" {
            $global:AMH2W_CLIPBOARD_HISTORY = @()
            Log-Info "🧹 Clipboard history cleared"
            return Ok -Value $null -Message "Clipboard history cleared"
        }
        
        "get" {
            if ($Arguments.Count -lt 2) {
                return Err "Please specify an index: all my clip clipboard get <index>"
            }
            
            $index = [int]$Arguments[1] - 1
            if ($index -lt 0 -or $index -ge $global:AMH2W_CLIPBOARD_HISTORY.Count) {
                return Err "Invalid index. Please use a number between 1 and $($global:AMH2W_CLIPBOARD_HISTORY.Count)"
            }
            
            $item = $global:AMH2W_CLIPBOARD_HISTORY[$index]
            Set-Clipboard -Value $item
            Log-Info "📋 Copied history item $($index + 1) to clipboard"
            return Ok -Value $item -Message "Copied history item to clipboard"
        }
        
        "count" {
            Log-Info "📊 Clipboard history contains $($global:AMH2W_CLIPBOARD_HISTORY.Count) items"
            return Ok -Value $global:AMH2W_CLIPBOARD_HISTORY.Count -Message "Clipboard history count"
        }
        
        default {
            $actions = @(
                "clear  - Clear clipboard history"
                "get    - Copy history item to clipboard (usage: get <index>)"
                "count  - Show number of items in history"
            )
            
            Write-Host "Available clipboard actions:" -ForegroundColor Yellow
            $actions | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }
            
            return Ok -Value $actions -Message "Available clipboard actions"
        }
    }
}
