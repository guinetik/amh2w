# shell.ps1
# Opens a PowerShell terminal at the specified location

function shell {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location)
    )
    
    # Validate the path
    if (-not (Test-Path -Path $Path)) {
        Write-Host "Error: The path '$Path' does not exist." -ForegroundColor Red
        return $false
    }
    
    # Resolve to absolute path if relative
    $resolvedPath = Resolve-Path $Path
    
    Write-Host "Opening new PowerShell terminal at: " -NoNewline -ForegroundColor Cyan
    Write-Host $resolvedPath -ForegroundColor Green
    
    try {
        # Start a new PowerShell process at the specified location
        Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "Set-Location -Path '$resolvedPath'"
        return $true
    }
    catch {
        Write-Host "Error opening PowerShell at '$resolvedPath': $_" -ForegroundColor Red
        return $false
    }
}
