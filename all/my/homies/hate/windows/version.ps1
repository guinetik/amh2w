# version.ps1
# Displays Windows version information

function version {
    [CmdletBinding()]
    param()
    
    Write-Host "Windows Version Information:" -ForegroundColor Cyan
    Write-Host "----------------------------" -ForegroundColor Cyan
    
    try {
        $os = Get-WmiObject -Class Win32_OperatingSystem
        
        Write-Host "OS Name:           " -NoNewline -ForegroundColor White
        Write-Host $os.Caption -ForegroundColor Yellow
        
        Write-Host "Version:           " -NoNewline -ForegroundColor White
        Write-Host $os.Version -ForegroundColor Yellow
        
        Write-Host "Build Number:      " -NoNewline -ForegroundColor White
        Write-Host $os.BuildNumber -ForegroundColor Yellow
        
        Write-Host "Architecture:      " -NoNewline -ForegroundColor White
        Write-Host $os.OSArchitecture -ForegroundColor Yellow
        
        Write-Host "Service Pack:      " -NoNewline -ForegroundColor White
        Write-Host $os.ServicePackMajorVersion -ForegroundColor Yellow
        
        Write-Host "Install Date:      " -NoNewline -ForegroundColor White
        Write-Host $os.ConvertToDateTime($os.InstallDate) -ForegroundColor Yellow
        
        Write-Host "Last Boot Time:    " -NoNewline -ForegroundColor White
        Write-Host $os.ConvertToDateTime($os.LastBootUpTime) -ForegroundColor Yellow
        
        Write-Host "System Directory:  " -NoNewline -ForegroundColor White
        Write-Host $os.SystemDirectory -ForegroundColor Yellow
        
        Write-Host "Windows Directory: " -NoNewline -ForegroundColor White
        Write-Host $os.WindowsDirectory -ForegroundColor Yellow
        
        return $os
    }
    catch {
        Write-Host "Error getting Windows version information: $_" -ForegroundColor Red
        return $null
    }
}
