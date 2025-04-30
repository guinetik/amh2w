# version.ps1
# Displays comprehensive system information similar to neofetch

# version.ps1
# Displays comprehensive system information similar to neofetch

function version {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$NoPrint = $false
    )
    
    # Convert string parameter to boolean
    $suppressOutput = $false
    if ($NoPrint -eq "-NoPrint" -or $NoPrint -eq "$true" -or $NoPrint -eq "true") {
        $suppressOutput = $true
    }
    
    try {
        # Collect system information
        $os = Get-WmiObject -Class Win32_OperatingSystem
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        $processor = Get-WmiObject -Class Win32_Processor
        $videoCard = Get-WmiObject -Class Win32_VideoController
        $bios = Get-WmiObject -Class Win32_BIOS
        $diskDrives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        $network = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        
        # Calculate RAM in GB
        $ramGB = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
        if ([string]::IsNullOrEmpty($ramGB)) {
            $ramGB = "Unknown"
        } else {
            $ramGB = "$ramGB GB"
        }
        
        # Calculate Video RAM in MB (handle potential null or array values)
        $videoRAM = "Unknown"
        if ($videoCard -and $videoCard.AdapterRAM) {
            # Handle if $videoCard is an array
            if ($videoCard.GetType().IsArray) {
                $vramValue = $videoCard[0].AdapterRAM
            } else {
                $vramValue = $videoCard.AdapterRAM
            }
            
            if ($vramValue) {
                $videoRAM = [math]::Round($vramValue / 1MB, 2).ToString() + " MB"
            }
        }
        
        # Create result object with comprehensive information
        $systemInfo = [PSCustomObject]@{
            ComputerName = $computerSystem.Name
            Manufacturer = $computerSystem.Manufacturer
            Model = $computerSystem.Model
            OSName = $os.Caption
            OSVersion = $os.Version
            BuildNumber = $os.BuildNumber
            Architecture = $os.OSArchitecture
            ServicePack = $os.ServicePackMajorVersion
            InstallDate = $os.ConvertToDateTime($os.InstallDate)
            LastBootTime = $os.ConvertToDateTime($os.LastBootUpTime)
            SystemDirectory = $os.SystemDirectory
            WindowsDirectory = $os.WindowsDirectory
            Processor = $processor.Name
            ProcessorCores = $processor.NumberOfCores
            ProcessorThreads = $processor.NumberOfLogicalProcessors
            ProcessorSpeed = "$($processor.MaxClockSpeed) MHz"
            RAM = $ramGB
            VideoCard = $videoCard.Name
            VideoRAM = $videoRAM
            BIOS = $bios.Manufacturer + " " + $bios.SMBIOSBIOSVersion
            Disks = $diskDrives | ForEach-Object { 
                $size = "Unknown"
                $free = "Unknown"
                
                if ($_.Size) {
                    $size = [math]::Round($_.Size / 1GB, 2).ToString() + " GB"
                }
                
                if ($_.FreeSpace) {
                    $free = [math]::Round($_.FreeSpace / 1GB, 2).ToString() + " GB"
                }
                
                [PSCustomObject]@{
                    Drive = $_.DeviceID
                    Size = $size
                    FreeSpace = $free
                }
            }
            Network = $network | ForEach-Object {
                $ip = "Unknown"
                if ($_.IPAddress -and $_.IPAddress.Count -gt 0) {
                    $ip = $_.IPAddress[0]
                }
                
                [PSCustomObject]@{
                    Adapter = $_.Description
                    IPAddress = $ip
                    MACAddress = $_.MACAddress
                }
            }
            Username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            Uptime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)
        }
        
        if (-not $suppressOutput) {
            # ASCII art logo (simple Windows logo)
            Write-Host "                     " -ForegroundColor Cyan
            Write-Host "       ████████      " -ForegroundColor Cyan
            Write-Host "       ██    ██      " -ForegroundColor Cyan
            Write-Host "       ████████      " -ForegroundColor Cyan
            Write-Host "       ██    ██      " -ForegroundColor Cyan
            Write-Host "       ██    ██      " -ForegroundColor Cyan
            Write-Host "                     " -ForegroundColor Cyan
            
            # Display user@hostname
            Write-Host "$($systemInfo.Username)@$($systemInfo.ComputerName)" -ForegroundColor Green
            Write-Host "------------------------" -ForegroundColor Green
            
            # OS Information
            Write-Host "OS:               " -NoNewline -ForegroundColor White
            Write-Host "$($systemInfo.OSName) ($($systemInfo.Architecture))" -ForegroundColor Yellow
            
            # Hardware Information
            Write-Host "Host:             " -NoNewline -ForegroundColor White
            Write-Host "$($systemInfo.Manufacturer) $($systemInfo.Model)" -ForegroundColor Yellow
            
            Write-Host "Kernel:           " -NoNewline -ForegroundColor White
            Write-Host "Windows $($systemInfo.OSVersion) Build $($systemInfo.BuildNumber)" -ForegroundColor Yellow
            
            Write-Host "Uptime:           " -NoNewline -ForegroundColor White
            Write-Host "$($systemInfo.Uptime.Days) days, $($systemInfo.Uptime.Hours) hours, $($systemInfo.Uptime.Minutes) minutes" -ForegroundColor Yellow
            
            Write-Host "Shell:            " -NoNewline -ForegroundColor White
            Write-Host "PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
            
            Write-Host "CPU:              " -NoNewline -ForegroundColor White
            Write-Host "$($systemInfo.Processor) ($($systemInfo.ProcessorCores) cores, $($systemInfo.ProcessorThreads) threads)" -ForegroundColor Yellow
            
            Write-Host "Memory:           " -NoNewline -ForegroundColor White
            Write-Host "$($systemInfo.RAM)" -ForegroundColor Yellow
            
            Write-Host "GPU:              " -NoNewline -ForegroundColor White
            Write-Host "$($systemInfo.VideoCard) ($($systemInfo.VideoRAM))" -ForegroundColor Yellow
            
            # Disk Information
            Write-Host "Disks:" -ForegroundColor White
            foreach ($disk in $systemInfo.Disks) {
                Write-Host "  $($disk.Drive)               " -NoNewline -ForegroundColor White
                Write-Host "$($disk.Size) ($($disk.FreeSpace) free)" -ForegroundColor Yellow
            }
            
            # Network Information
            Write-Host "Network:" -ForegroundColor White
            foreach ($adapter in $systemInfo.Network) {
                Write-Host "  $($adapter.Adapter)" -ForegroundColor Yellow
                Write-Host "    IP:              " -NoNewline -ForegroundColor White
                Write-Host "$($adapter.IPAddress)" -ForegroundColor Yellow
                Write-Host "    MAC:             " -NoNewline -ForegroundColor White
                Write-Host "$($adapter.MACAddress)" -ForegroundColor Yellow
            }
            
            # Fixed color blocks
            Write-Host "`n" -NoNewline
            $colors = @("Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")
            foreach ($color in $colors) {
                Write-Host "   " -NoNewline -BackgroundColor $color
            }
            Write-Host "`n"
        }
        
        # Return a proper Result object
        return Ok -Value $systemInfo -Message "Successfully retrieved system information"
    }
    catch {
        $errorMsg = "Error getting system information: $_"
        Log-Error $errorMsg
        return Err $errorMsg
    }
}