function telnetc {
    param (
        [string]$Action="help"
    )
    if (-not (Test-IsAdmin)) {
        Invoke-Elevate -Command "all my homies hate windows telnetc $Action" -Description "Configure Telnet" -Prompt $true
        return Ok "Elevated"
    }
    if ($Action -eq "status") {
        Write-Host "🔍 Checking Telnet Client status..." -ForegroundColor Cyan
        $Results = Get-WindowsOptionalFeature -Online -FeatureName TelnetClient
        $Status = $Results.State -eq "Enabled" ? "Enabled" : "Disabled"
        Write-Host "📡 Telnet Client status:" $Status -ForegroundColor Cyan
        return Ok $Status - Message "Telnet Client is $Status"
    }
    elseif ($Action -eq "enable") {
        Write-Host "⚡ Enabling Telnet Client..."
        Enable-WindowsOptionalFeature -Online -FeatureName TelnetClient
        Write-Host "✅ Telnet Client enabled" -ForegroundColor Green
        return Ok "Telnet Client enabled"
    }
    elseif ($Action -eq "disable") {
        Write-Host "🛑 Disabling Telnet Client..."
        Disable-WindowsOptionalFeature -Online -FeatureName TelnetClient
        Write-Host "❌ Telnet Client disabled" -ForegroundColor Yellow
        return Ok "Telnet Client disabled"
    }
    else { 
        Write-Host "ℹ️ Usage: telnetc enable|disable"
        return Ok
    } 
}