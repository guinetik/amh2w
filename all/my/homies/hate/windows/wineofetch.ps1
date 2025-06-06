﻿# Windows neofetch-style system information display
# Usage: all my homies hate windows wineofetch

function wineofetch {
    param(
        [Parameter()]
        [switch]$Help
    )
    
    if ($Help) {
        Write-Host "`nWindows Neofetch-style System Information"
        Write-Host "========================================="
        Write-Host "`nUsage:"
        Write-Host "  all my homies hate windows winneofetch"
        Write-Host "`nDescription:"
        Write-Host "  Displays system information in a neofetch-style format`n"
        return Ok
    }
    
    try {
        Log-Info "Gathering system information..."
        
        # Retrieve information
        [system.threading.thread]::currentThread.currentCulture = [system.globalization.cultureInfo]"en-US"
        $dt = [datetime]::Now
        $day = $dt.ToLongDateString().split(',')[1].trim()
        if ($day.EndsWith('1')) { $day += 'st' } 
        elseif ($day.EndsWith('2')) { $day += 'nd' } 
        elseif ($day.EndsWith('3')) { $day += 'rd' } 
        else { $day += 'th' }
        
        $CurrentTime = "$day, $($dt.Year) $($dt.Hour):$($dt.Minute)"
        $TimeZone = (Get-TimeZone).id
        $UserName = [Environment]::USERNAME
        $ComputerName = [System.Net.Dns]::GetHostName().ToLower()
        $OSName = "$((Get-WmiObject win32_operatingsystem).caption) Build: $([System.Environment]::OSVersion.Version.Build)"
        $Kernel = "NT $([System.Environment]::OSVersion.Version)"
        
        # Get uptime
        $BootTime = Get-WinEvent -ProviderName eventlog | Where-Object {$_.Id -eq 6005} | Select-Object TimeCreated -First 1
        $TimeSpan = New-TimeSpan -Start $BootTime.TimeCreated.Date -End (Get-Date)
        $Uptime = "$($TimeSpan.Days) days, $($TimeSpan.Hours) hours, $($TimeSpan.Minutes) minutes"
        
        $PowerShellVersion = $PSVersionTable.PSVersion
        $PowerShellEdition = $PSVersionTable.PSEdition
        
        $CPU_Info = $env:PROCESSOR_IDENTIFIER + ' Rev: ' + $env:PROCESSOR_REVISION
        $NumberOfProcesses = (Get-Process).Count
        $CurrentLoad = "{0}%" -f $(Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average)
        
        # Get memory info
        $OS = Get-CimInstance -ClassName Win32_OperatingSystem
        $Memory_Size = "{0}mb/{1}mb Used" -f `
            ([math]::round(($OS.TotalVisibleMemorySize - $OS.FreePhysicalMemory) / 1KB)), `
            ([math]::round($OS.TotalVisibleMemorySize / 1KB))
        
        # Disk info
        $DriveDetails = Get-PSDrive C
        $DiskSize = "{0}GB free of {1}GB" -f `
            ([math]::round($DriveDetails.Free / 1GB)), `
            ([math]::round(($DriveDetails.Used + $DriveDetails.Free) / 1GB))
        
        # Print results with ASCII art
        [Environment]::NewLine
        Write-Host " ,.=:^!^!t3Z3z., " -ForegroundColor Red
        Write-Host " :tt:::tt333EE3 " -ForegroundColor Red
        Write-Host " Et:::ztt33EEE " -ForegroundColor Red -NoNewline
        Write-Host " @Ee., ..,     " -ForegroundColor Green -NoNewline
        Write-Host "      Time: " -ForegroundColor DarkGray -NoNewline
        Write-Host "$CurrentTime" -ForegroundColor Cyan
        Write-Host " ;tt:::tt333EE7" -ForegroundColor Red -NoNewline
        Write-Host " ;EEEEEEttttt33# " -ForegroundColor Green -NoNewline
        Write-Host "    Timezone: " -ForegroundColor DarkGray -NoNewline
        Write-Host "$TimeZone" -ForegroundColor Cyan
        Write-Host " :Et:::zt333EEQ." -NoNewline -ForegroundColor Red
        Write-Host " SEEEEEttttt33QL " -NoNewline -ForegroundColor Green
        Write-Host "   User: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$UserName" -ForegroundColor Cyan
        Write-Host " it::::tt333EEF" -NoNewline -ForegroundColor Red
        Write-Host " @EEEEEEttttt33F " -NoNewline -ForegroundColor Green
        Write-Host "    Host: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$ComputerName" -ForegroundColor Cyan
        Write-Host " ;3=*^``````'*4EEV" -NoNewline -ForegroundColor Red
        Write-Host " :EEEEEEttttt33@. " -NoNewline -ForegroundColor Green
        Write-Host "   OS: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$OSName" -ForegroundColor Cyan
        Write-Host " ,.=::::it=., " -NoNewline -ForegroundColor Cyan
        Write-Host "``" -NoNewline -ForegroundColor Red
        Write-Host " @EEEEEEtttz33QF " -NoNewline -ForegroundColor Green
        Write-Host "    Kernel: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$Kernel" -ForegroundColor Cyan
        Write-Host " ;::::::::zt33) " -NoNewline -ForegroundColor Cyan
        Write-Host " '4EEEtttji3P* " -NoNewline -ForegroundColor Green
        Write-Host "     Uptime: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$Uptime" -ForegroundColor Cyan
        Write-Host " :t::::::::tt33." -NoNewline -ForegroundColor Cyan
        Write-Host ":Z3z.. " -NoNewline -ForegroundColor Yellow
        Write-Host " ````" -NoNewline -ForegroundColor Green
        Write-Host " ,..g. " -NoNewline -ForegroundColor Yellow
        Write-Host "   PowerShell: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$PowerShellVersion $PowerShellEdition" -ForegroundColor Cyan
        Write-Host " i::::::::zt33F" -NoNewline -ForegroundColor Cyan
        Write-Host " AEEEtttt::::ztF " -NoNewline -ForegroundColor Yellow
        Write-Host "    CPU: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$CPU_Info" -ForegroundColor Cyan
        Write-Host " ;:::::::::t33V" -NoNewline -ForegroundColor Cyan
        Write-Host " ;EEEttttt::::t3 " -NoNewline -ForegroundColor Yellow
        Write-Host "    Processes: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$NumberOfProcesses" -ForegroundColor Cyan
        Write-Host " E::::::::zt33L" -NoNewline -ForegroundColor Cyan
        Write-Host " @EEEtttt::::z3F " -NoNewline -ForegroundColor Yellow
        Write-Host "    Current Load: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$CurrentLoad" -ForegroundColor Cyan
        Write-Host " {3=*^``````'*4E3)" -NoNewline -ForegroundColor Cyan
        Write-Host " ;EEEtttt:::::tZ`` " -NoNewline -ForegroundColor Yellow
        Write-Host "   Memory: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$Memory_Size" -ForegroundColor Cyan
        Write-Host "              ``" -NoNewline -ForegroundColor Cyan
        Write-Host " :EEEEtttt::::z7 " -NoNewline -ForegroundColor Yellow
        Write-Host "    System Volume: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$DiskSize" -ForegroundColor Cyan
        Write-Host "                 'VEzjt:;;z>*`` " -ForegroundColor Yellow
        [Environment]::NewLine
        
        # Create a system info object to return
        $SystemInfo = @{
            Time = $CurrentTime
            TimeZone = $TimeZone
            User = $UserName
            Host = $ComputerName
            OS = $OSName
            Kernel = $Kernel
            Uptime = $Uptime
            PowerShell = "$PowerShellVersion $PowerShellEdition"
            CPU = $CPU_Info
            Processes = $NumberOfProcesses
            Load = $CurrentLoad
            Memory = $Memory_Size
            Disk = $DiskSize
        }
        
        return Ok -Value $SystemInfo -Message "System information displayed successfully"
    }
    catch {
        return Err "Failed to gather system information: $_"
    }
}
