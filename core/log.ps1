function Log {
    param(
        [ValidateSet('info', 'success', 'error', 'warn')]
        [string]$Level,
        [string]$Message,
        [hashtable]$Context
    )
    
    if (-not $Context.verbose -and $Level -eq 'info') {
        return
    }
    
    $color = $Context.logColors[$Level]
    
    $prefix = switch ($Level) {
        'info'    { "ℹ️ " }
        'success' { "✅ " }
        'error'   { "❌ " }
        'warn'    { "⚠️ " }
    }
    
    Write-Host -ForegroundColor $color "$prefix $Message"
}