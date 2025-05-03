# Get PowerShell version information

function psconfig {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [switch]$NoPrint = $false,
        
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    try {
        $result = @{
            Core = $null
            Windows = $null
            Current = $null
            CoreInstalled = $false
            WindowsInstalled = $false
        }
        
        # Check for PowerShell Core (pwsh)
        if (Get-Command -Name pwsh -ErrorAction SilentlyContinue) {
            try {
                $coreVersion = & pwsh -Command { $PSVersionTable.PSVersion.ToString() }
                $result.Core = $coreVersion
                $result.CoreInstalled = $true
            } catch {
                Log-Warning "Found pwsh command but couldn't get version: $_"
            }
        }
        
        # Check for Windows PowerShell
        if (Get-Command -Name powershell -ErrorAction SilentlyContinue) {
            try {
                # Run in a separate process to get Windows PowerShell version
                $winVersion = & "$env:WINDIR\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
                $result.Windows = $winVersion
                $result.WindowsInstalled = $true
            } catch {
                Log-Warning "Found powershell command but couldn't get version: $_"
            }
        }
        
        # Current PowerShell version
        $result.Current = $PSVersionTable.PSVersion.ToString()
        
        # Always print information
        Write-Host "PowerShell Information" -ForegroundColor Cyan
        Write-Host "=====================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "Current Session: " -NoNewline
        Write-Host $result.Current -ForegroundColor Green
        
        Write-Host "Edition: " -NoNewline
        Write-Host $PSVersionTable.PSEdition -ForegroundColor Green
        
        Write-Host "Execution Policy: " -NoNewline
        Write-Host (Get-ExecutionPolicy) -ForegroundColor Green
        
        Write-Host ""
        Write-Host "Available PowerShell Versions:" -ForegroundColor Cyan
        
        if ($result.CoreInstalled) {
            Write-Host "  • PowerShell Core: " -NoNewline
            Write-Host $result.Core -ForegroundColor Green
        } else {
            Write-Host "  • PowerShell Core: " -NoNewline
            Write-Host "Not installed" -ForegroundColor Yellow
        }
        
        if ($result.WindowsInstalled) {
            Write-Host "  • Windows PowerShell: " -NoNewline
            Write-Host $result.Windows -ForegroundColor Green
        } else {
            Write-Host "  • Windows PowerShell: " -NoNewline
            Write-Host "Not installed" -ForegroundColor Yellow
        }
        
        return Ok -Value $result -Message "PowerShell version check completed successfully"
    } 
    catch {
        Log-Error "Failed to determine PowerShell version: $_"
        return Err "Failed to determine PowerShell version: $_"
    }
}

