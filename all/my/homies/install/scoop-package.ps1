function scoop-package {
    [CmdletBinding()]
    param()

    $cmd = 'iwr https://get.scoop.sh | iex'

    try {
        if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
            Write-Host "🚀 Launching new Windows Terminal tab for Scoop install..." -ForegroundColor Cyan

            Start-Process wt.exe -ArgumentList @(
                "-w", "0",
                "nt",
                "-p", "PowerShell",
                "powershell", "-NoExit", "-Command", $cmd
            )

            return Ok -Message "Scoop installer launched in Windows Terminal"
        } else {
            Write-Host "📦 Launching fallback PowerShell window..." -ForegroundColor Yellow

            Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", $cmd

            return Ok -Message "Scoop installer launched in new PowerShell window"
        }
    }
    catch {
        return Err -Message "Failed to launch scoop installer: $_"
    }
}
