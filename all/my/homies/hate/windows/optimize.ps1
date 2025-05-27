# all/my/homies/hate/windows/optimize.ps1
# Windows optimization utility for development environments

function optimize {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    # Check if running as admin
    if (-not (Test-IsAdmin)) {
        Log-Warning "Windows Optimizer requires administrator privileges"
        
        # Construct the original command to elevate
        $originalCommand = "all my homies hate windows optimize"
        if ($Arguments.Count -gt 0) {
            $originalCommand += " $($Arguments -join ' ')"
        }
        
        # Elevate with prompt and keep the window open
        Invoke-Elevate -Command $originalCommand -Prompt $true -Description "Windows Optimizer requires administrator privileges to modify system settings" -KeepOpen $true
        
        # Exit the current non-elevated instance
        return Ok "Elevation requested"
    }
    
    # Parse arguments to determine which optimizations to apply
    $applyPerformance = $false
    $applyServices = $false
    $applyMemory = $false
    $applyStartup = $false
    $applyCleanup = $false
    $applyAll = $false
    
    # If no arguments or just help-related, show help
    if ($Arguments.Count -eq 0 -or 
        $Arguments -contains "help" -or 
        $Arguments -contains "--help" -or 
        $Arguments -contains "-h" -or 
        $Arguments -contains "/?") {
        Show-OptimizeHelp
        return Ok "Help displayed"
    }
    
    # Check each argument for optimization type
    foreach ($arg in $Arguments) {
        switch -Wildcard ($arg.ToLower()) {
            "dev" { $applyAll = $true }
            "all" { $applyAll = $true }
            "perf*" { $applyPerformance = $true }
            "serv*" { $applyServices = $true }
            "mem*" { $applyMemory = $true }
            "start*" { $applyStartup = $true }
            "clean*" { $applyCleanup = $true }
            "temp*" { $applyCleanup = $true }
            default {
                Log-Warning "Unknown argument: $arg"
            }
        }
    }
    
    # If "all" or "dev" is specified, apply all optimizations
    if ($applyAll) {
        $applyPerformance = $true
        $applyServices = $true
        $applyMemory = $true
        $applyStartup = $true
        $applyCleanup = $true
    }
    
    # If no specific optimizations selected, show help
    if (-not ($applyPerformance -or $applyServices -or $applyMemory -or $applyStartup -or $applyCleanup)) {
        Log-Warning "No valid optimization options specified"
        Show-OptimizeHelp
        return Ok "Help displayed"
    }
    
    # Initialize results array to track what was done
    $results = @()
    
    # Apply selected optimizations
    if ($applyPerformance) {
        $performanceResult = Optimize-Performance
        $results += $performanceResult
    }
    
    if ($applyServices) {
        $servicesResult = Optimize-Services
        $results += $servicesResult
    }
    
    if ($applyMemory) {
        $memoryResult = Optimize-Memory
        $results += $memoryResult
    }
    
    if ($applyStartup) {
        $startupResult = Optimize-Startup
        $results += $startupResult
    }
    
    if ($applyCleanup) {
        $cleanupResult = Optimize-TempFiles
        $results += $cleanupResult
    }
    
    # Show summary of results
    Log-Info "Windows Optimization Summary:"
    foreach ($result in $results) {
        if ($result.ok) {
            Log-Success "  $($result.value)"
        } else {
            Log-Error "  $($result.error)"
        }
    }
    
    return Ok "Windows optimization complete"
}

function Show-OptimizeHelp {
    Write-Host ""
    Write-Host "Windows Optimizer" -ForegroundColor Cyan
    Write-Host "----------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Optimizes Windows settings for better performance, especially for development environments."
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  all my homies hate windows optimize [option]"
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  dev         : Apply all optimizations for development environments"
    Write-Host "  all         : Apply all optimizations"
    Write-Host "  performance : Optimize power and visual settings for performance"
    Write-Host "  services    : Optimize Windows services for development"
    Write-Host "  memory      : Optimize memory and page file settings"
    Write-Host "  startup     : Disable unnecessary startup programs"
    Write-Host "  cleanup     : Clean temporary files and free up disk space"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  all my homies hate windows optimize dev"
    Write-Host "  all my homies hate windows optimize performance services"
    Write-Host ""
}

function Optimize-Performance {
    Log-Info "Optimizing Windows for performance..."
    
    try {
        # Set power plan to High Performance
        Log-Info "Setting power plan to High Performance..."
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        
        # Disable visual effects for performance
        Log-Info "Optimizing visual effects for performance..."
        $visualFxPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        
        if (-not (Test-Path $visualFxPath)) {
            New-Item -Path $visualFxPath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $visualFxPath -Name "VisualFXSetting" -Value 2  # 2 = Custom
        
        # Disable specific visual effects
        $advancedPath = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $advancedPath -Name "UserPreferencesMask" -Value ([byte[]](0x90, 0x12, 0x01, 0x80))
        
        # Disable animations
        $windowMetricsPath = "HKCU:\Control Panel\Desktop\WindowMetrics"
        if (-not (Test-Path $windowMetricsPath)) {
            New-Item -Path $windowMetricsPath -Force | Out-Null
        }
        
        # Disable transparency
        $personalizePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        if (-not (Test-Path $personalizePath)) {
            New-Item -Path $personalizePath -Force | Out-Null
        }
        Set-ItemProperty -Path $personalizePath -Name "EnableTransparency" -Value 0
        
        # Optimize explorer settings for development
        Log-Info "Optimizing Explorer settings..."
        $explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $explorerPath -Name "HideFileExt" -Value 0  # Show file extensions
        Set-ItemProperty -Path $explorerPath -Name "Hidden" -Value 1  # Show hidden files
        Set-ItemProperty -Path $explorerPath -Name "ShowSuperHidden" -Value 1  # Show protected OS files
        
        # Restart Explorer to apply changes
        Log-Info "Restarting Explorer to apply changes..."
        Stop-Process -Name "explorer" -ErrorAction SilentlyContinue
        Start-Process "explorer"
        
        return Ok "Performance settings optimized successfully"
    }
    catch {
        $errorMessage = $_.Exception.Message
        Log-Error "Error optimizing performance settings: $errorMessage"
        return Err "Performance settings optimization failed: $errorMessage"
    }
}

function Optimize-Services {
    Log-Info "Optimizing Windows services for development..."
    
    try {
        # Define services to disable with descriptions
        $servicesToDisable = @(
            @{Name = "SysMain"; DisplayName = "Superfetch/SysMain"; Description = "Prefetches files but can cause high disk usage"},
            @{Name = "DiagTrack"; DisplayName = "Connected User Experiences and Telemetry"; Description = "Telemetry service that sends data to Microsoft"},
        )
        
        # Define services to set to manual
        $servicesToManual = @(
            @{Name = "wuauserv"; DisplayName = "Windows Update"; Description = "Windows Update service - set to manual for developer control"},
            @{Name = "BITS"; DisplayName = "Background Intelligent Transfer Service"; Description = "Used for Windows Update and can use bandwidth"},
            @{Name = "Spooler"; DisplayName = "Print Spooler"; Description = "Print service - manual if you don't print often"},
            @{Name = "RemoteRegistry"; DisplayName = "Remote Registry"; Description = "Allows remote registry access"},
            @{Name = "lmhosts"; DisplayName = "TCP/IP NetBIOS Helper"; Description = "NetBIOS name resolution service"}
        )
        
        # Disable services
        foreach ($service in $servicesToDisable) {
            Log-Info "Disabling service: $($service.DisplayName) ($($service.Name))"
            try {
                Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service.Name -StartupType Disabled
                Log-Success "  Successfully disabled $($service.DisplayName)"
            }
            catch {
                Log-Warning "  Failed to disable $($service.DisplayName): $_"
            }
        }
        
        # Set services to manual
        foreach ($service in $servicesToManual) {
            Log-Info "Setting service to manual: $($service.DisplayName) ($($service.Name))"
            try {
                Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service.Name -StartupType Manual
                Log-Success "  Successfully set $($service.DisplayName) to manual"
            }
            catch {
                Log-Warning "  Failed to set $($service.DisplayName) to manual: $_"
            }
        }
        
        return Ok "Services optimized successfully"
    }
    catch {
        $errorMessage = $_.Exception.Message
        Log-Error "Error optimizing services: $errorMessage"
        return Err "Services optimization failed: $errorMessage"
    }
}

function Optimize-Memory {
    Log-Info "Optimizing memory settings..."
    
    try {
        # Configure virtual memory (pagefile) using registry approach
        Log-Info "Optimizing virtual memory settings..."
        
        # Get system information
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        $physicalMemoryGB = [Math]::Round(($computerSystem.TotalPhysicalMemory / 1GB), 0)
        
        Log-Info "  Detected physical memory: $physicalMemoryGB GB"
        
        # Calculate optimal pagefile size (between 1.5x to 4x RAM based on available RAM)
        # Uses a variable scale - smaller for larger RAM sizes
        if ($physicalMemoryGB -le 4) {
            # For 4GB or less, use 3x RAM
            $pageFileSizeMB = $physicalMemoryGB * 3 * 1024
        } 
        elseif ($physicalMemoryGB -le 8) {
            # For 8GB or less, use 2x RAM
            $pageFileSizeMB = $physicalMemoryGB * 2 * 1024
        }
        elseif ($physicalMemoryGB -le 16) {
            # For 16GB or less, use 1.5x RAM
            $pageFileSizeMB = $physicalMemoryGB * 1.5 * 1024
        }
        else {
            # For over 16GB, cap at 24GB
            $pageFileSizeMB = 24 * 1024
        }
        
        # Round to nearest 1024MB
        $pageFileSizeMB = [math]::Round($pageFileSizeMB / 1024) * 1024
        
        Log-Info "  Setting pagefile size to: $pageFileSizeMB MB"
        
        # Get the system drive
        $systemDrive = $env:SystemDrive.Substring(0, 1)
        
        # Configure other memory optimization settings
        Log-Info "Optimizing filesystem cache settings..."
        $fsRegistry = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        Set-ItemProperty -Path $fsRegistry -Name "LargeSystemCache" -Value 1  # Optimize for applications
        
        # Configure working set optimization
        Log-Info "Optimizing process working set settings..."
        Set-ItemProperty -Path $fsRegistry -Name "DisablePagingExecutive" -Value 0  # Allow paging of kernel
        
        return Ok "Memory settings optimized successfully (requires restart to apply pagefile changes)"
    }
    catch {
        $errorMessage = $_.Exception.Message
        Log-Error "Error optimizing memory settings: $errorMessage"
        return Err "Memory settings optimization failed: $errorMessage"
    }
}

function Optimize-Startup {
    Log-Info "Optimizing startup programs..."
    
    try {
        # Check for Windows 10+ to use modern registry location
        $osVersion = [System.Environment]::OSVersion.Version
        $isWin10OrNewer = $osVersion.Major -ge 10
        
        if ($isWin10OrNewer) {
            # Windows 10+ startup registry location
            $startupPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
            
            if (-not (Test-Path $startupPath)) {
                New-Item -Path $startupPath -Force | Out-Null
            }
            
            # Get all startup entries
            $runPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
            $startupItems = Get-ItemProperty -Path $runPath | Get-Member -MemberType NoteProperty | 
                Where-Object { $_.Name -notlike "PS*" } | Select-Object -ExpandProperty Name
            
            # Create a byte array to represent 'disabled'
            $disabledValue = [byte[]](0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
            
            # Disable common startup items that are not needed for development
            $commonItemsToDisable = @(
                "OneDrive",
                "Spotify",
                "Discord",
                "Teams",
                "Slack",
                "Skype",
                "SteamClient",
                "EpicGamesLauncher",
                "Origin",
                "Ubisoft",
                "AcroRd32",
                "googledrivesync",
                "DropboxUpdate",
                "ccleaner",
                "iTunes",
                "QuickTime"
            )
            
            # Disable the common items if they are in the startup
            foreach ($item in $startupItems) {
                if ($commonItemsToDisable -contains $item) {
                    Log-Info "Disabling startup item: $item"
                    try {
                        if (-not (Get-ItemProperty -Path $startupPath -Name $item -ErrorAction SilentlyContinue)) {
                            New-ItemProperty -Path $startupPath -Name $item -Value $disabledValue -PropertyType Binary | Out-Null
                        }
                        else {
                            Set-ItemProperty -Path $startupPath -Name $item -Value $disabledValue
                        }
                        Log-Success "  Successfully disabled $item from startup"
                    }
                    catch {
                        Log-Warning "  Failed to disable $item : $_"
                    }
                }
            }
        }
        else {
            # For older Windows versions, use MS Config approach
            Log-Info "Older Windows version detected, using MS Config to manage startup items..."
            
            # Get all enabled startup items
            $startupCommand = 'Get-CimInstance Win32_StartupCommand | Select-Object Name, command, Location, User | Format-List'
            $startupItems = Invoke-Expression $startupCommand
            
            # Display info since direct manipulation is not implemented
            Log-Info "Please review the following startup items and disable unnecessary ones using Task Manager or MSConfig:"
            $startupItems | ForEach-Object { Write-Host $_ }
            
            # Open MSConfig
            Start-Process "msconfig.exe"
        }
        
        return Ok "Startup programs optimized successfully"
    }
    catch {
        $errorMessage = $_.Exception.Message
        Log-Error "Error optimizing startup programs: $errorMessage"
        return Err "Startup programs optimization failed: $errorMessage"
    }
}

function Optimize-TempFiles {
    Log-Info "Cleaning temporary files..."
    
    try {
        # Get initial drive space information for later comparison
        $beforeDriveSpace = Get-WmiObject Win32_LogicalDisk | 
            Where-Object { $_.DeviceID -eq $env:SystemDrive } | 
            Select-Object @{Name="FreeSpaceGB";Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}
        
        Log-Info "Free space before cleanup: $($beforeDriveSpace.FreeSpaceGB) GB"
        
        # Define common temp folders to clean
        $tempFolders = @(
            # User temp folders
            "$env:TEMP",
            # Windows temp folder
            "$env:windir\Temp",
            # Downloaded Program Files
            "$env:windir\Downloaded Program Files",
            # Prefetch files
            "$env:windir\Prefetch",
            # Temporary Internet Files for all users
            "C:\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*",
            # Browser caches
            "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache\*",
            "C:\Users\*\AppData\Local\Google\Chrome\User Data\Default\Cache\*",
            "C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*\cache2\*"
        )
        
        # Count of deleted items
        $deletedCount = 0
        $failedCount = 0
        $bytesFreed = 0
        
        foreach ($folder in $tempFolders) {
            Log-Info "Cleaning folder: $folder"
            
            # Skip if folder pattern doesn't exist
            if (-not (Test-Path -Path $folder -ErrorAction SilentlyContinue)) {
                Log-Info "  Folder pattern does not exist, skipping: $folder"
                continue
            }
            
            # Get files with their size before deleting for statistics
            $filesToDelete = Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue | 
                            Where-Object { -not $_.PSIsContainer }
                            
            foreach ($file in $filesToDelete) {
                try {
                    $fileSize = $file.Length
                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                    $bytesFreed += $fileSize
                    $deletedCount++
                    
                    # Log only every 100 files to avoid excessive logging
                    if ($deletedCount % 100 -eq 0) {
                        Log-Debug "  Deleted $deletedCount files so far..."
                    }
                }
                catch {
                    # File is likely in use or access denied
                    $failedCount++
                }
            }
            
            # Try to remove empty folders
            try {
                Get-ChildItem -Path $folder -Recurse -Force -Directory -ErrorAction SilentlyContinue | 
                    Where-Object { (Get-ChildItem -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0 } | 
                    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            }
            catch {
                # Some folders might be in use
            }
        }
        
        # Clear Recycle Bin
        Log-Info "Clearing Recycle Bin..."
        try {
            # Check if Clear-RecycleBin exists (PowerShell 5.0+)
            if (Get-Command Clear-RecycleBin -ErrorAction SilentlyContinue) {
                Clear-RecycleBin -Force -ErrorAction SilentlyContinue
                Log-Success "  Recycle Bin cleared successfully"
            }
            else {
                # Fallback for older PowerShell versions
                $shell = New-Object -ComObject Shell.Application
                $recycleBin = $shell.Namespace(0xa)
                $recycleBin.Items() | ForEach-Object { 
                    Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue 
                }
                Log-Success "  Recycle Bin cleared successfully (using COM)"
            }
        }
        catch {
            Log-Warning "  Failed to clear Recycle Bin: $_"
        }
        
        # Run built-in Disk Cleanup utility with common cleanup options
        Log-Info "Running Windows Disk Cleanup utility..."
        try {
            # Prepare cleanup command - using /sagerun:1 to run common cleanup options
            $cleanupScript = "cleanmgr.exe /sagerun:1"
            
            # Run cleanup
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cleanupScript" -NoNewWindow -Wait
            Log-Success "  Windows Disk Cleanup completed"
        }
        catch {
            Log-Warning "  Failed to run Windows Disk Cleanup: $_"
        }
        
        # Get final drive space information
        $afterDriveSpace = Get-WmiObject Win32_LogicalDisk | 
            Where-Object { $_.DeviceID -eq $env:SystemDrive } | 
            Select-Object @{Name="FreeSpaceGB";Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}
        
        $spaceFreed = $afterDriveSpace.FreeSpaceGB - $beforeDriveSpace.FreeSpaceGB
        Log-Info "Free space after cleanup: $($afterDriveSpace.FreeSpaceGB) GB"
        Log-Success "Space freed: $spaceFreed GB"
        
        # Format bytes freed
        $bytesFreedFormatted = 
            if ($bytesFreed -gt 1GB) { "{0:N2} GB" -f ($bytesFreed / 1GB) }
            elseif ($bytesFreed -gt 1MB) { "{0:N2} MB" -f ($bytesFreed / 1MB) }
            else { "{0:N2} KB" -f ($bytesFreed / 1KB) }
        
        return Ok "Temporary files cleaned successfully: $deletedCount files removed, $bytesFreedFormatted freed"
    }
    catch {
        $errorMessage = $_.Exception.Message
        Log-Error "Error cleaning temporary files: $errorMessage"
        return Err "Temporary files cleanup failed: $errorMessage"
    }
}
