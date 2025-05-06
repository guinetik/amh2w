# Global variable to store clipboard history
if (-not (Test-Path variable:global:AMH2W_CLIPBOARD_HISTORY)) {
    $global:AMH2W_CLIPBOARD_HISTORY = @()
    $global:AMH2W_CLIPBOARD_MAX_HISTORY = 50  # Maximum items to keep in history
}

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
