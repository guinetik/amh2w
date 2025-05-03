function npp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Path
    )

    try {
        if ($Path) {
            Start-Process "C:\Program Files\Notepad++\notepad++.exe" -ArgumentList $Path
        }
        else {
            Start-Process "C:\Program Files\Notepad++\notepad++.exe"
        }
        return Ok
    }
    catch {
        Write-Host "Error: Command function '$arg' failed: $_" -ForegroundColor Red
        return Err -Message "Failed to start Notepad++"
    }
}

