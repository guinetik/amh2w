function terminal {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Command,

        [Parameter(Position = 1)]
        [string]$Title = "AMH2W",

        [Parameter(Position = 2)]
        [Alias("Admin")]
        [object]$AsAdmin = $false
    )
    
    $admin = Truthy $AsAdmin

    try {
        $encoded = "`"$Command`""

        if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
            Write-Host "🚀 Opening Windows Terminal tab: $Title" -ForegroundColor Cyan

            if ($PSVersionTable.PSVersion.Major -ge 6) {
                # PowerShell Core (6.x+)
                $psExecutable = "pwsh"
            } else {
                # Windows PowerShell 5.x
                $psExecutable = "powershell"
            }

            $argsz = @(
                "-w", "0",
                "nt",
                "-p", $psExecutable,
                "--title", $Title,
                $psExecutable, "-NoExit", "-Command", $encoded
            )

            if ($admin) {
                Start-Process wt.exe -Verb RunAs -ArgumentList $argsz
            } else {
                Start-Process wt.exe -ArgumentList $argsz
            }

            return Ok -Message "Command launched in Windows Terminal"
        } else {
            Write-Host "📦 Falling back to PowerShell window..." -ForegroundColor Yellow
            $fallbackArgs = @("-NoExit", "-Command", $Command)

            if ($admin) {
                Start-Process powershell.exe -Verb RunAs -ArgumentList $fallbackArgs
            } else {
                Start-Process powershell.exe -ArgumentList $fallbackArgs
            }

            return Ok -Message "Command launched in new PowerShell window"
        }
    }
    catch {
        return Err -Message "Failed to open terminal: $_"
    }
}
