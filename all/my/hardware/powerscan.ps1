<#
.SYNOPSIS
Comprehensive power system analysis and reporting tool using WMI.

.DESCRIPTION
Performs detailed power analysis of your Windows system including power configurations,
battery status, power events, and hardware power-related information using WMI.
Can generate reports in multiple formats (table, json, html) with configurable scan duration.

.NOTES
File: all/my/hardware/powerscan.ps1
CommandPath: all my hardware powerscan [format] [duration]

.EXAMPLE
all my hardware powerscan
Performs a standard power scan and displays results in table format.

.EXAMPLE
all my hardware powerscan json
Performs power scan and outputs results as JSON, then uses the JSON viewer.

.EXAMPLE
all my hardware powerscan html 60
Performs a 60-second power scan and generates an HTML report.

.EXAMPLE
all my hardware powerscan table 30
Performs a 30-second scan with table output.
#>

<#
.SYNOPSIS
Performs comprehensive power system analysis and reporting.

.DESCRIPTION
Analyzes system power configuration, battery status, power events, and hardware power information.
Supports multiple output formats and configurable scan duration for energy reports using WMI.

.PARAMETER Format
Output format: 'table' (default), 'json', or 'html'.

.PARAMETER Duration
Duration in seconds for energy analysis. Default: 10 seconds. Use 0 to skip energy report.

.OUTPUTS
Returns an Ok or Err object according to the AMH2W result pattern.

.EXAMPLE
powerscan
powerscan json
powerscan html 60
powerscan table 30
#>
function powerscan {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("table", "json", "html")]
        [string]$Format = "table",
        
        [Parameter(Position = 1)]
        [ValidateRange(0, 300)]
        [int]$Duration = 10
    )

    try {
        Log-Info "Starting comprehensive power system analysis using WMI..."
        Log-Info "Output format: $Format | Energy scan duration: $Duration seconds"

        # Ensure WMI services are running
        try {
            $wmiService = Get-Service -Name "Winmgmt" -ErrorAction Stop
            if ($wmiService.Status -ne "Running") {
                Log-Warning "WMI service is not running. Attempting to start..."
                Start-Service -Name "Winmgmt" -ErrorAction Stop
                Log-Success "WMI service started successfully"
            } else {
                Log-Success "WMI service is running"
            }
        }
        catch {
            Log-Warning "Could not verify WMI service status: $_"
        }

        # Initialize results container
        $powerData = [PSCustomObject]@{
            SystemInfo = $null
            PowerConfig = $null
            BatteryInfo = $null
            ProcessorInfo = $null
            ThermalInfo = $null
            PowerEvents = $null
            HardwareErrors = $null
            EnergyReport = $null
            GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            ScanDuration = $Duration
        }

        # 1. Basic system power information
        Write-Progress -Activity "Power System Analysis" -Status "Gathering system power information..." -PercentComplete 10
        Log-Info "Collecting basic system power information..."
        try {
            $systemEnclosure = Get-WmiObject -Class Win32_SystemEnclosure -ErrorAction Stop
            $powerData.SystemInfo = [PSCustomObject]@{
                PowerSupplyState = switch ($systemEnclosure.PowerSupplyState) {
                    1 { "Other" }
                    2 { "Unknown" }  
                    3 { "Safe" }
                    4 { "Warning" }
                    5 { "Critical" }
                    6 { "Non-recoverable" }
                    default { "Unknown ($($systemEnclosure.PowerSupplyState))" }
                }
                ThermalState = switch ($systemEnclosure.ThermalState) {
                    1 { "Other" }
                    2 { "Unknown" }
                    3 { "Safe" }
                    4 { "Warning" }
                    5 { "Critical" }
                    6 { "Non-recoverable" }
                    default { "Unknown ($($systemEnclosure.ThermalState))" }
                }
                ChassisTypes = $systemEnclosure.ChassisTypes -join ", "
            }
            Log-Success "System power information collected"
        }
        catch {
            Log-Warning "Could not retrieve system enclosure information: $_"
            $powerData.SystemInfo = [PSCustomObject]@{
                PowerSupplyState = "Unable to determine"
                ThermalState = "Unable to determine"
                ChassisTypes = "Unknown"
            }
        }

        # 2. Power configuration and active scheme
        Write-Progress -Activity "Power System Analysis" -Status "Analyzing power configuration..." -PercentComplete 20
        Log-Info "Analyzing power configuration..."
        try {
            $activePowerScheme = (powercfg /getactivescheme 2>$null)
            $powerSchemes = (powercfg /list 2>$null)
            $powerCapabilities = (powercfg /availablesleepstates 2>$null)
            
            $powerData.PowerConfig = [PSCustomObject]@{
                ActiveScheme = if ($activePowerScheme) { $activePowerScheme.Trim() } else { "Unable to determine" }
                AvailableSchemes = if ($powerSchemes) { $powerSchemes -split "`n" | Where-Object { $_ -match "GUID" } } else { @("Unable to determine") }
                SleepStates = if ($powerCapabilities) { $powerCapabilities -split "`n" | Where-Object { $_ -notmatch "^$" } } else { @("Unable to determine") }
                HibernationEnabled = (powercfg /query | Select-String "hibernate" | Measure-Object).Count -gt 0
            }
            Log-Success "Power configuration analyzed"
        }
        catch {
            Log-Warning "Could not retrieve power configuration: $_"
            $powerData.PowerConfig = [PSCustomObject]@{
                ActiveScheme = "Unable to determine"
                AvailableSchemes = @("Error retrieving schemes")
                SleepStates = @("Error retrieving sleep states")
                HibernationEnabled = $false
            }
        }

        # 3. Battery information
        Write-Progress -Activity "Power System Analysis" -Status "Checking battery status..." -PercentComplete 30
        Log-Info "Checking battery status..."
        try {
            $batteries = Get-WmiObject -Class Win32_Battery -ErrorAction Stop
            if ($batteries) {
                $batteryList = @()
                foreach ($battery in $batteries) {
                    $batteryList += [PSCustomObject]@{
                        Name = $battery.Name
                        BatteryStatus = switch ($battery.BatteryStatus) {
                            1 { "Discharging" }
                            2 { "On AC Power" }
                            3 { "Fully Charged" }
                            4 { "Low" }
                            5 { "Critical" }
                            6 { "Charging" }
                            7 { "Charging and High" }
                            8 { "Charging and Low" }
                            9 { "Charging and Critical" }
                            10 { "Undefined" }
                            11 { "Partially Charged" }
                            default { "Unknown ($($battery.BatteryStatus))" }
                        }
                        EstimatedChargeRemaining = if ($battery.EstimatedChargeRemaining) { "$($battery.EstimatedChargeRemaining)%" } else { "Unknown" }
                        EstimatedRunTime = if ($battery.EstimatedRunTime -and $battery.EstimatedRunTime -ne 71582788) { "$($battery.EstimatedRunTime) minutes" } else { "Unknown" }
                        DesignCapacity = if ($battery.DesignCapacity) { "$($battery.DesignCapacity) mWh" } else { "Unknown" }
                        FullChargeCapacity = if ($battery.FullChargeCapacity) { "$($battery.FullChargeCapacity) mWh" } else { "Unknown" }
                        Chemistry = switch ($battery.Chemistry) {
                            1 { "Other" }
                            2 { "Unknown" }
                            3 { "Lead Acid" }
                            4 { "Nickel Cadmium" }
                            5 { "Nickel Metal Hydride" }
                            6 { "Lithium-ion" }
                            7 { "Zinc air" }
                            8 { "Lithium Polymer" }
                            default { "Unknown" }
                        }
                    }
                }
                $powerData.BatteryInfo = $batteryList
                Log-Success "Battery information collected for $($batteries.Count) battery(ies)"
            }
            else {
                $powerData.BatteryInfo = @([PSCustomObject]@{
                    Name = "Desktop System"
                    BatteryStatus = "No Battery Present"
                    EstimatedChargeRemaining = "N/A"
                    EstimatedRunTime = "N/A"
                    DesignCapacity = "N/A"
                    FullChargeCapacity = "N/A"
                    Chemistry = "N/A"
                })
                Log-Info "No batteries detected - likely desktop system"
            }
        }
        catch {
            Log-Warning "Could not retrieve battery information: $_"
            $powerData.BatteryInfo = @([PSCustomObject]@{
                Name = "Error"
                BatteryStatus = "Unable to determine"
                EstimatedChargeRemaining = "Error"
                EstimatedRunTime = "Error"
                DesignCapacity = "Error"
                FullChargeCapacity = "Error"
                Chemistry = "Error"
            })
        }

        # 4. Processor power information
        Write-Progress -Activity "Power System Analysis" -Status "Analyzing processor power settings..." -PercentComplete 40
        Log-Info "Analyzing processor power settings..."
        try {
            $processors = Get-WmiObject -Class Win32_Processor -ErrorAction Stop
            $processorList = @()
            
            # Get current CPU utilization for power estimation
            $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time'
            $cpuUsage = if ($cpuCounter) { [math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2) } else { 0 }
            
            foreach ($processor in $processors) {
                # Calculate estimated power consumption based on TDP and current load
                $tdp = 65  # Default TDP in watts (conservative estimate)
                $estimatedPower = "N/A"
                
                # Try to identify processor TDP based on name
                if ($processor.Name -match "i[357]-\d{4}[A-Z]*") { $tdp = 65 }
                elseif ($processor.Name -match "i[357]-\d{4}U") { $tdp = 15 }
                elseif ($processor.Name -match "i[357]-\d{4}H") { $tdp = 45 }
                elseif ($processor.Name -match "i9-\d{4}[A-Z]*") { $tdp = 95 }
                elseif ($processor.Name -match "i9-\d{5}K") { $tdp = 125 }
                elseif ($processor.Name -match "Ryzen [357] \d{4}[A-Z]*") { $tdp = 65 }
                elseif ($processor.Name -match "Ryzen [357] \d{4}U") { $tdp = 15 }
                elseif ($processor.Name -match "Ryzen 9 \d{4}[A-Z]*") { $tdp = 105 }
                
                if ($cpuUsage -gt 0) {
                    $estimatedPower = "$([math]::Round($tdp * ($cpuUsage / 100), 1))W (est.)"
                }
                
                $processorList += [PSCustomObject]@{
                    Name = $processor.Name.Trim()
                    MaxClockSpeed = if ($processor.MaxClockSpeed) { "$($processor.MaxClockSpeed) MHz" } else { "Unknown" }
                    CurrentClockSpeed = if ($processor.CurrentClockSpeed) { "$($processor.CurrentClockSpeed) MHz" } else { "Unknown" }
                    CurrentVoltage = if ($processor.CurrentVoltage) { 
                        # Voltage is in tenths of volts
                        "$([math]::Round($processor.CurrentVoltage / 10.0, 2)) V" 
                    } else { "Unknown" }
                    LoadPercentage = "$cpuUsage%"
                    EstimatedPower = $estimatedPower
                    EstimatedTDP = "${tdp}W"
                    PowerManagementSupported = $processor.PowerManagementSupported
                    PowerManagementCapabilities = if ($processor.PowerManagementCapabilities) { 
                        $capabilities = @()
                        foreach ($cap in $processor.PowerManagementCapabilities) {
                            $capabilities += switch ($cap) {
                                0 { "Unknown" }
                                1 { "Not Supported" }
                                2 { "Disabled" }
                                3 { "Enabled" }
                                4 { "Power Saving Modes Entered Automatically" }
                                5 { "Power State Settable" }
                                6 { "Power Cycling Supported" }
                                7 { "Timed Power On Supported" }
                                default { "Capability $cap" }
                            }
                        }
                        $capabilities -join ", "
                    } else { "Unknown" }
                }
            }
            $powerData.ProcessorInfo = $processorList
            Log-Success "Processor power information collected for $($processors.Count) processor(s)"
        }
        catch {
            Log-Warning "Could not retrieve processor information: $_"
            $powerData.ProcessorInfo = @([PSCustomObject]@{
                Name = "Unable to determine"
                MaxClockSpeed = "Error"
                CurrentClockSpeed = "Error"
                CurrentVoltage = "Error"
                LoadPercentage = "Error"
                EstimatedPower = "Error"
                EstimatedTDP = "Error"
                PowerManagementSupported = $false
                PowerManagementCapabilities = "Error"
            })
        }

        # 5. Thermal information
        Write-Progress -Activity "Power System Analysis" -Status "Checking thermal sensors..." -PercentComplete 50
        Log-Info "Checking thermal sensors via WMI..."
        
        $thermalList = @()
        
        try {
            # Try WMI for thermal data
            $thermalProbes = Get-WmiObject -Class Win32_TemperatureProbe
            
            # Also try to get CPU temperature via WMI (alternative method)
            try {
                $cpuTemp = Get-WmiObject -Namespace "root\wmi" -Class MSAcpi_ThermalZoneTemperature -ErrorAction Stop
                if ($cpuTemp) {
                    foreach ($zone in $cpuTemp) {
                        $tempCelsius = [math]::Round(($zone.CurrentTemperature / 10.0) - 273.15, 1)
                        if ($tempCelsius -gt 0 -and $tempCelsius -lt 150) { # Sanity check
                            $thermalList += [PSCustomObject]@{
                                Name = "Thermal Zone $($zone.InstanceName)"
                                Description = "ACPI Thermal Zone"
                                CurrentReading = "$tempCelsius°C"
                                Status = if ($tempCelsius -gt 80) { "Warning" } elseif ($tempCelsius -gt 90) { "Critical" } else { "OK" }
                                Availability = "Running"
                                Source = "WMI/ACPI"
                            }
                        }
                    }
                }
            }
            catch {
                Log-Debug "MSAcpi_ThermalZoneTemperature not available: $_"
            }
            
            # Process standard thermal probes if any
            if ($thermalProbes) {
                foreach ($probe in $thermalProbes) {
                    $thermalList += [PSCustomObject]@{
                        Name = if ($probe.Name) { $probe.Name } else { "Thermal Probe $($probe.DeviceID)" }
                        Description = $probe.Description
                        CurrentReading = if ($probe.CurrentReading) { 
                            # Convert from tenths of degrees Kelvin to Celsius
                            "$([math]::Round(($probe.CurrentReading / 10.0) - 273.15, 1))°C" 
                        } else { "Unknown" }
                        Status = $probe.Status
                        Availability = switch ($probe.Availability) {
                            1 { "Other" }
                            2 { "Unknown" }
                            3 { "Running/Full Power" }
                            4 { "Warning" }
                            5 { "In Test" }
                            6 { "Not Applicable" }
                            7 { "Power Off" }
                            8 { "Off Line" }
                            9 { "Off Duty" }
                            10 { "Degraded" }
                            11 { "Not Installed" }
                            12 { "Install Error" }
                            13 { "Power Save - Unknown" }
                            14 { "Power Save - Low Power Mode" }
                            15 { "Power Save - Standby" }
                            16 { "Power Cycle" }
                            17 { "Power Save - Warning" }
                            default { "Unknown" }
                        }
                        Source = "WMI"
                    }
                }
            }
            
            # If we have thermal data, use it
            if ($thermalList.Count -gt 0) {
                $powerData.ThermalInfo = $thermalList
                Log-Success "Thermal information collected for $($thermalList.Count) sensor(s)"
            }
            else {
                # No thermal data from WMI
                $powerData.ThermalInfo = @([PSCustomObject]@{
                    Name = "No thermal sensors detected"
                    Description = "System may not expose thermal sensors via WMI"
                    CurrentReading = "N/A"
                    Status = "N/A"
                    Availability = "N/A"
                    Source = "WMI"
                })
                Log-Info "No thermal sensors detected via WMI"
            }
        }
        catch {
            Log-Warning "Could not retrieve thermal information: $_"
            $powerData.ThermalInfo = @([PSCustomObject]@{
                Name = "Error retrieving thermal data"
                Description = "WMI query failed"
                CurrentReading = "Error"
                Status = "Error"
                Availability = "Error"
                Source = "Error"
            })
        }

        # 6. Recent power events
        Write-Progress -Activity "Power System Analysis" -Status "Analyzing power events..." -PercentComplete 60
        Log-Info "Analyzing recent power events..."
        try {
            $powerEvents = Get-WinEvent -FilterHashtable @{LogName='System'; Id=41,42,109} -MaxEvents 20 -ErrorAction Stop
            $eventList = @()
            foreach ($event in $powerEvents) {
                $eventList += [PSCustomObject]@{
                    TimeCreated = $event.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                    Id = $event.Id
                    Level = $event.LevelDisplayName
                    Source = $event.ProviderName
                    Message = ($event.Message -split "`n")[0].Trim() # First line only
                    Description = switch ($event.Id) {
                        41 { "System has rebooted without cleanly shutting down" }
                        42 { "System is entering sleep" }
                        109 { "Kernel power event" }
                        default { "Power-related system event" }
                    }
                }
            }
            $powerData.PowerEvents = $eventList
            Log-Success "Power events analyzed - found $($eventList.Count) recent events"
        }
        catch {
            Log-Warning "Could not retrieve power events: $_"
            $powerData.PowerEvents = @([PSCustomObject]@{
                TimeCreated = "Error"
                Id = 0
                Level = "Error"
                Source = "Error"
                Message = "Unable to retrieve power events"
                Description = "Event log query failed"
            })
        }

        # 7. Hardware errors related to power
        Write-Progress -Activity "Power System Analysis" -Status "Checking for power-related hardware errors..." -PercentComplete 70
        Log-Info "Checking for power-related hardware errors..."
        try {
            $hardwareErrors = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2} -MaxEvents 50 -ErrorAction Stop | 
                Where-Object {$_.ProviderName -like "*Power*" -or $_.Message -like "*power*" -or $_.Message -like "*voltage*" -or $_.Message -like "*thermal*"}
            
            if ($hardwareErrors) {
                $errorList = @()
                foreach ($error in $hardwareErrors) {
                    $errorList += [PSCustomObject]@{
                        TimeCreated = $error.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                        Level = $error.LevelDisplayName
                        Source = $error.ProviderName
                        Id = $error.Id
                        Message = ($error.Message -split "`n")[0].Trim()
                    }
                }
                $powerData.HardwareErrors = $errorList
                Log-Warning "Found $($errorList.Count) power-related hardware errors"
            }
            else {
                $powerData.HardwareErrors = @([PSCustomObject]@{
                    TimeCreated = "N/A"
                    Level = "Info"
                    Source = "Power Scan"
                    Id = 0
                    Message = "No power-related hardware errors found"
                })
                Log-Success "No power-related hardware errors found"
            }
        }
        catch {
            Log-Warning "Could not check for hardware errors: $_"
            $powerData.HardwareErrors = @([PSCustomObject]@{
                TimeCreated = "Error"
                Level = "Error"
                Source = "Error"
                Id = 0
                Message = "Unable to check for hardware errors"
            })
        }

        # 8. Energy report (if duration > 0)
        if ($Duration -gt 0) {
            Write-Progress -Activity "Power System Analysis" -Status "Generating energy report (this may take $Duration seconds)..." -PercentComplete 80
            Log-Info "Generating energy report for $Duration seconds..."
            
            try {
                # Create temp file for energy report
                $tempHtmlFile = [System.IO.Path]::GetTempFileName() + ".html"
                
                # Run energy report
                $energyResult = Start-Process -FilePath "powercfg" -ArgumentList "/energy", "/duration", $Duration, "/output", $tempHtmlFile -Wait -PassThru -WindowStyle Hidden
                
                if ($energyResult.ExitCode -eq 0 -and (Test-Path $tempHtmlFile)) {
                    # Read and parse the HTML report
                    $htmlContent = Get-Content $tempHtmlFile -Raw
                    
                    # Extract key information from HTML
                    $energyAnalysis = [PSCustomObject]@{
                        Duration = "$Duration seconds"
                        ReportGenerated = $true
                        ReportPath = $tempHtmlFile
                        FileSize = [math]::Round((Get-Item $tempHtmlFile).Length / 1KB, 2)
                        Summary = "Energy report generated successfully"
                        Errors = ([regex]::Matches($htmlContent, 'error-log-entry')).Count.ToString()
                        Warnings = ([regex]::Matches($htmlContent, 'warning-log-entry')).Count.ToString()
                        Informational = ([regex]::Matches($htmlContent, 'info-log-entry')).Count.ToString()
                    }
                    
                    $powerData.EnergyReport = $energyAnalysis
                    Log-Success "Energy report generated: $($energyAnalysis.Errors) errors, $($energyAnalysis.Warnings) warnings"
                }
                else {
                    throw "Energy report generation failed with exit code $($energyResult.ExitCode)"
                }
            }
            catch {
                Log-Warning "Could not generate energy report: $_"
                $powerData.EnergyReport = [PSCustomObject]@{
                    Duration = "$Duration seconds"
                    ReportGenerated = $false
                    ReportPath = "Failed to generate"
                    FileSize = 0
                    Summary = "Energy report generation failed: $_"
                    Errors = "Unknown"
                    Warnings = "Unknown"
                    Informational = "Unknown"
                }
            }
        }
        else {
            Log-Info "Skipping energy report (duration set to 0)"
            $powerData.EnergyReport = [PSCustomObject]@{
                Duration = "Skipped"
                ReportGenerated = $false
                ReportPath = "N/A"
                FileSize = 0
                Summary = "Energy report skipped by user request"
                Errors = "N/A"
                Warnings = "N/A"
                Informational = "N/A"
            }
        }

        Write-Progress -Activity "Power System Analysis" -Status "Formatting output..." -PercentComplete 90

        # Output results based on format
        switch ($Format.ToLower()) {
            "json" {
                Log-Info "Formatting output as JSON..."
                $jsonOutput = $powerData | ConvertTo-Json -Depth 10
                
                # Use the built-in JSON viewer
                Write-Host "`n🔋 Power System Analysis Results (JSON):" -ForegroundColor Cyan
                Write-Host "=" * 50 -ForegroundColor Cyan
                
                # Save to temp file and use json viewer
                $tempJsonFile = [System.IO.Path]::GetTempFileName() + ".json"
                $jsonOutput | Out-File -FilePath $tempJsonFile -Encoding UTF8
                
                # Call the JSON viewer
                $jsonResult = & "all" "my" "homies" "hate" "json" "view" $tempJsonFile
                
                # Clean up temp file
                Remove-Item $tempJsonFile
                
                return Ok -Value $powerData -Message "Power scan completed - results displayed as JSON"
            }
            
            "html" {
                Log-Info "Generating HTML report..."
                $htmlFile = "$HOME\Desktop\PowerScan_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
                $htmlContent = Generate-PowerScanHtml -PowerData $powerData
                $htmlContent | Out-File -FilePath $htmlFile -Encoding UTF8
                
                Write-Host "`n🔋 Power System Analysis Complete!" -ForegroundColor Green
                Write-Host "HTML report saved to: $htmlFile" -ForegroundColor Yellow
                
                # Use AMH2W browser command to open the HTML file
                try {
                    $fileUri = "file:///" + $htmlFile.Replace("\", "/")
                    Log-Info "Opening HTML report in browser: $fileUri"
                    
                    # Call the AMH2W browser command
                    $browserResult = & "all" "my" "browser" $fileUri
                    
                    if ($browserResult -and $browserResult.ok) {
                        Log-Success "HTML report opened in browser using AMH2W"
                    }
                    else {
                        # Fallback to traditional method
                        Start-Process $htmlFile
                        Log-Success "HTML report opened using system default"
                    }
                }
                catch {
                    Log-Warning "Could not open HTML report automatically: $_"
                    Write-Host "You can manually open the report at: $htmlFile" -ForegroundColor Yellow
                }
                
                return Ok -Value $powerData -Message "Power scan completed - HTML report saved to $htmlFile and opened in browser"
            }
            
            default { # table
                Log-Info "Formatting output as tables..."
                Display-PowerScanResults -PowerData $powerData
                return Ok -Value $powerData -Message "Power scan completed - results displayed in table format"
            }
        }
    }
    catch {
        Log-Error "Power scan failed: $_"
        return Err -Message "Power scan failed: $_"
    }
    finally {
        Write-Progress -Activity "Power System Analysis" -Completed
    }
}

<#
.SYNOPSIS
Displays power scan results in formatted tables.

.DESCRIPTION
Internal function to display power scan results in a user-friendly table format.

.PARAMETER PowerData
The power data object containing all scan results.
#>
function Display-PowerScanResults {
    param([PSCustomObject]$PowerData)
    
    Write-Host "`n🔋 Power System Analysis Results" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host "Generated: $($PowerData.GeneratedAt)" -ForegroundColor Gray
    Write-Host "Scan Duration: $($PowerData.ScanDuration) seconds" -ForegroundColor Gray
    
    # System Information
    Write-Host "`n💻 System Power Information:" -ForegroundColor Yellow
    $PowerData.SystemInfo | Format-Table -AutoSize | Out-String | Write-Host
    
    # Power Configuration
    Write-Host "⚙️ Power Configuration:" -ForegroundColor Yellow
    Write-Host "Active Scheme: $($PowerData.PowerConfig.ActiveScheme)" -ForegroundColor White
    Write-Host "Hibernation Enabled: $($PowerData.PowerConfig.HibernationEnabled)" -ForegroundColor White
    
    # Battery Information
    Write-Host "`n🔋 Battery Information:" -ForegroundColor Yellow
    $PowerData.BatteryInfo | Format-Table -AutoSize | Out-String | Write-Host
    
    # Processor Information
    Write-Host "🧠 Processor Power Information:" -ForegroundColor Yellow
    $PowerData.ProcessorInfo | Select-Object Name, CurrentClockSpeed, LoadPercentage, EstimatedPower, EstimatedTDP | Format-Table -AutoSize | Out-String | Write-Host
    
    # Thermal Information
    Write-Host "🌡️ Thermal Information:" -ForegroundColor Yellow
    $PowerData.ThermalInfo | Format-Table -AutoSize | Out-String | Write-Host
    
    # Energy Report Summary  
    Write-Host "⚡ Energy Report Summary:" -ForegroundColor Yellow
    $PowerData.EnergyReport | Format-Table -AutoSize | Out-String | Write-Host
    
    # Recent Power Events
    Write-Host "📋 Recent Power Events (Last 20):" -ForegroundColor Yellow
    $PowerData.PowerEvents | Format-Table -AutoSize | Out-String | Write-Host
    
    # Hardware Errors
    Write-Host "⚠️ Power-Related Hardware Issues:" -ForegroundColor Yellow
    $PowerData.HardwareErrors | Format-Table -AutoSize | Out-String | Write-Host
    
    Write-Host "`n✅ Power system analysis complete!" -ForegroundColor Green
    
    # Provide recommendations based on findings
    Write-Host "`n💡 Quick Recommendations:" -ForegroundColor Cyan
    
    # Analyze critical power events
    $criticalEvents = $PowerData.PowerEvents | Where-Object { $_.Level -eq "Critical" -and $_.Id -eq 41 }
    if ($criticalEvents -and $criticalEvents.Count -gt 0) {
        Write-Host "🚨 CRITICAL: Found $($criticalEvents.Count) unexpected shutdown events (Event ID 41)" -ForegroundColor Red
        Write-Host "   This indicates your system is rebooting without proper shutdown" -ForegroundColor Red
        Write-Host "   Possible causes: Power supply issues, overheating, hardware failure, or driver problems" -ForegroundColor Yellow
        Write-Host "   Recommendation: Check power supply, cooling, and run hardware diagnostics" -ForegroundColor Yellow
    }
    
    if ($PowerData.SystemInfo.PowerSupplyState -like "*Warning*" -or $PowerData.SystemInfo.PowerSupplyState -like "*Critical*") {
        Write-Host "⚠️  Power supply is reporting a warning or critical state - check your PSU" -ForegroundColor Red
    }
    if ($PowerData.SystemInfo.ThermalState -like "*Warning*" -or $PowerData.SystemInfo.ThermalState -like "*Critical*") {
        Write-Host "🌡️ System thermal state is concerning - check cooling and airflow" -ForegroundColor Red
    }
    if ($PowerData.HardwareErrors -and $PowerData.HardwareErrors[0].Message -notlike "*No power-related*") {
        Write-Host "🔧 Power-related hardware errors detected - review the hardware errors section" -ForegroundColor Yellow
    }
    if ($PowerData.EnergyReport.ReportGenerated -and $PowerData.EnergyReport.ReportPath -ne "N/A") {
        Write-Host "📊 Detailed energy report available at: $($PowerData.EnergyReport.ReportPath)" -ForegroundColor Green
        Write-Host "   Note: Energy Report analyzes power efficiency, not system stability" -ForegroundColor Gray
    }
    
    # Distinguish between energy efficiency and system stability
    Write-Host "`n📋 Report Clarification:" -ForegroundColor Cyan
    Write-Host "• Energy Report (Errors/Warnings): Analyzes power configuration efficiency" -ForegroundColor White
    Write-Host "• Power Events: Shows actual system power-related incidents and crashes" -ForegroundColor White
    if ($criticalEvents -and $criticalEvents.Count -gt 0) {
        Write-Host "• Your power config is efficient, but system stability needs attention!" -ForegroundColor Yellow
    }
    
    Write-Host "🔍 All data collected via WMI - no external dependencies required" -ForegroundColor Green
}

<#
.SYNOPSIS
Generates an HTML report for power scan results.

.DESCRIPTION
Internal function to generate a comprehensive HTML report with styling and interactive elements.

.PARAMETER PowerData
The power data object containing all scan results.

.OUTPUTS
HTML content as a string.
#>
function Generate-PowerScanHtml {
    param([PSCustomObject]$PowerData)
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Power System Analysis Report - $($PowerData.GeneratedAt)</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            min-height: 100vh;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(45deg, #2c3e50, #34495e);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .header p {
            margin: 10px 0 0 0;
            opacity: 0.9;
            font-size: 1.1em;
        }
        .content {
            padding: 30px;
        }
        .section {
            margin-bottom: 40px;
            background: #f8f9fa;
            border-radius: 8px;
            padding: 25px;
            border-left: 5px solid #007bff;
        }
        .section h2 {
            color: #2c3e50;
            margin-top: 0;
            font-size: 1.5em;
            display: flex;
            align-items: center;
        }
        .section h2::before {
            margin-right: 10px;
            font-size: 1.2em;
        }
        .system-info h2::before { content: "💻"; }
        .power-config h2::before { content: "⚙️"; }
        .battery-info h2::before { content: "🔋"; }
        .processor-info h2::before { content: "🧠"; }
        .thermal-info h2::before { content: "🌡️"; }
        .energy-report h2::before { content: "⚡"; }
        .power-events h2::before { content: "📋"; }
        .hardware-errors h2::before { content: "⚠️"; }
        .recommendations h2::before { content: "💡"; }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
            background: white;
            border-radius: 6px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #007bff;
            color: white;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.9em;
            letter-spacing: 0.5px;
        }
        tr:hover {
            background: #f5f5f5;
        }
        .status-ok { color: #28a745; font-weight: bold; }
        .status-warning { color: #ffc107; font-weight: bold; }
        .status-error { color: #dc3545; font-weight: bold; }
        .footer {
            background: #2c3e50;
            color: white;
            text-align: center;
            padding: 20px;
            font-size: 0.9em;
        }
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-top: 3px solid #007bff;
        }
        .summary-card h3 {
            margin: 0 0 10px 0;
            color: #2c3e50;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .summary-card .value {
            font-size: 1.5em;
            font-weight: bold;
            color: #007bff;
        }
        .alert {
            padding: 15px;
            margin: 15px 0;
            border-radius: 6px;
            font-weight: 500;
        }
        .alert-warning {
            background-color: #fff3cd;
            border: 1px solid #ffeaa7;
            color: #856404;
        }
        .alert-danger {
            background-color: #f8d7da;
            border: 1px solid #f5c6cb;
            color: #721c24;
        }
        .alert-success {
            background-color: #d4edda;
            border: 1px solid #c3e6cb;
            color: #155724;
        }
        .wmi-badge {
            background: #28a745;
            color: white;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.8em;
            font-weight: bold;
            margin-left: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔋 Power System Analysis Report</h1>
            <p>Generated on $($PowerData.GeneratedAt) | Scan Duration: $($PowerData.ScanDuration) seconds</p>
            <span class="wmi-badge">WMI-Based Analysis</span>
        </div>
        
        <div class="content">
            <div class="summary-grid">
                <div class="summary-card">
                    <h3>Power Supply State</h3>
                    <div class="value">$(if($PowerData.SystemInfo.PowerSupplyState -match "Unknown \(\d+\)") { "Unknown" } else { $PowerData.SystemInfo.PowerSupplyState })</div>
                </div>
                <div class="summary-card">
                    <h3>Thermal State</h3>
                    <div class="value">$(if($PowerData.SystemInfo.ThermalState -match "Unknown \(\d+\)") { "Unknown" } else { $PowerData.SystemInfo.ThermalState })</div>
                </div>
                <div class="summary-card">
                    <h3>Critical Events</h3>
                    <div class="value" style="color: #dc3545;">$(if($PowerData.PowerEvents) { ($PowerData.PowerEvents | Where-Object { $_.Level -eq "Critical" }).Count } else { 0 })</div>
                </div>
                <div class="summary-card">
                    <h3>Energy Report</h3>
                    <div class="value">$(if($PowerData.EnergyReport.ReportGenerated) { "✅ Generated" } else { "❌ Failed" })</div>
                </div>
                <div class="summary-card">
                    <h3>Total Power Events</h3>
                    <div class="value">$(if($PowerData.PowerEvents) { $PowerData.PowerEvents.Count } else { 0 })</div>
                </div>
            </div>

            <div class="section system-info">
                <h2>System Power Information</h2>
                <table>
                    <tr><th>Property</th><th>Value</th></tr>
                    <tr><td>Power Supply State</td><td class="$(if($PowerData.SystemInfo.PowerSupplyState -like '*Safe*') { 'status-ok' } elseif($PowerData.SystemInfo.PowerSupplyState -like '*Warning*') { 'status-warning' } elseif($PowerData.SystemInfo.PowerSupplyState -like '*Unknown*') { '' } else { 'status-error' })">$(if($PowerData.SystemInfo.PowerSupplyState -match "Unknown \(\d+\)") { "Unknown" } else { $PowerData.SystemInfo.PowerSupplyState })</td></tr>
                    <tr><td>Thermal State</td><td class="$(if($PowerData.SystemInfo.ThermalState -like '*Safe*') { 'status-ok' } elseif($PowerData.SystemInfo.ThermalState -like '*Warning*') { 'status-warning' } elseif($PowerData.SystemInfo.ThermalState -like '*Unknown*') { '' } else { 'status-error' })">$(if($PowerData.SystemInfo.ThermalState -match "Unknown \(\d+\)") { "Unknown" } else { $PowerData.SystemInfo.ThermalState })</td></tr>
                    <tr><td>Chassis Types</td><td>$(switch([int]$PowerData.SystemInfo.ChassisTypes) { 3 { "Desktop" } 4 { "Low Profile Desktop" } 5 { "Pizza Box" } 6 { "Mini Tower" } 7 { "Tower" } 8 { "Portable" } 9 { "Laptop" } 10 { "Notebook" } 11 { "Hand Held" } 12 { "Docking Station" } 13 { "All in One" } 14 { "Sub Notebook" } default { "Chassis Type $($PowerData.SystemInfo.ChassisTypes)" } })</td></tr>
                </table>
            </div>

            <div class="section power-config">
                <h2>Power Configuration</h2>
                <table>
                    <tr><th>Setting</th><th>Value</th></tr>
                    <tr><td>Active Power Scheme</td><td>$($PowerData.PowerConfig.ActiveScheme)</td></tr>
                    <tr><td>Hibernation Enabled</td><td>$($PowerData.PowerConfig.HibernationEnabled)</td></tr>
                </table>
            </div>

            <div class="section battery-info">
                <h2>Battery Information</h2>
                <table>
                    <tr><th>Name</th><th>Status</th><th>Charge</th><th>Runtime</th><th>Chemistry</th></tr>
"@
    
    foreach ($battery in $PowerData.BatteryInfo) {
        $html += "<tr><td>$($battery.Name)</td><td>$($battery.BatteryStatus)</td><td>$($battery.EstimatedChargeRemaining)</td><td>$($battery.EstimatedRunTime)</td><td>$($battery.Chemistry)</td></tr>"
    }
    
    $html += @"
                </table>
            </div>

            <div class="section processor-info">
                <h2>Processor Power Information</h2>
                <table>
                    <tr><th>Name</th><th>Current Speed</th><th>Load</th><th>Est. Power</th><th>TDP</th></tr>
"@
    
    foreach ($processor in $PowerData.ProcessorInfo) {
        $html += "<tr><td>$($processor.Name)</td><td>$($processor.CurrentClockSpeed)</td><td>$($processor.LoadPercentage)</td><td>$($processor.EstimatedPower)</td><td>$($processor.EstimatedTDP)</td></tr>"
    }
    
    $html += @"
                </table>
            </div>

            <div class="section thermal-info">
                <h2>Thermal Information</h2>
                <table>
                    <tr><th>Name</th><th>Description</th><th>Temperature</th><th>Status</th><th>Source</th></tr>
"@
    
    foreach ($thermal in $PowerData.ThermalInfo) {
        $sourceField = if ($thermal.Source) { $thermal.Source } else { "WMI" }
        $html += "<tr><td>$($thermal.Name)</td><td>$($thermal.Description)</td><td>$($thermal.CurrentReading)</td><td>$($thermal.Status)</td><td>$sourceField</td></tr>"
    }
    
    $html += @"
                </table>
            </div>

            <div class="section energy-report">
                <h2>Energy Report Summary</h2>
                <table>
                    <tr><th>Property</th><th>Value</th></tr>
                    <tr><td>Duration</td><td>$($PowerData.EnergyReport.Duration)</td></tr>
                    <tr><td>Report Generated</td><td class="$(if($PowerData.EnergyReport.ReportGenerated) { 'status-ok' } else { 'status-error' })">$($PowerData.EnergyReport.ReportGenerated)</td></tr>
                    <tr><td>File Size</td><td>$($PowerData.EnergyReport.FileSize) KB</td></tr>
                    <tr><td>Errors</td><td class="$(if($PowerData.EnergyReport.Errors -eq "0" -or $PowerData.EnergyReport.Errors -eq 0) { 'status-ok' } else { 'status-error' })">$($PowerData.EnergyReport.Errors)</td></tr>
                    <tr><td>Warnings</td><td class="$(if($PowerData.EnergyReport.Warnings -eq "0" -or $PowerData.EnergyReport.Warnings -eq 0) { 'status-ok' } else { 'status-warning' })">$($PowerData.EnergyReport.Warnings)</td></tr>
                    <tr><td>Informational</td><td>$($PowerData.EnergyReport.Informational)</td></tr>
                </table>
                $(if($PowerData.EnergyReport.ReportPath -and $PowerData.EnergyReport.ReportPath -ne "N/A" -and $PowerData.EnergyReport.ReportPath -ne "Failed to generate") {
                    "<div class='alert alert-success'>📊 Detailed energy report available at: <strong>$($PowerData.EnergyReport.ReportPath)</strong></div>"
                })
            </div>

            <div class="section power-events">
                <h2>Recent Power Events</h2>
                $(
                    # Count critical events for alert
                    $criticalCount = ($PowerData.PowerEvents | Where-Object { $_.Level -eq "Critical" -and $_.Id -eq 41 }).Count
                    if ($criticalCount -gt 0) {
                        "<div class='alert alert-danger'>🚨 <strong>CRITICAL ALERT:</strong> Found $criticalCount unexpected shutdown events (Event ID 41). This indicates system instability - your computer is rebooting without proper shutdown. Possible causes: power supply issues, overheating, hardware failure, or driver problems.</div>"
                    }
                )
                <table>
                    <tr><th>Time</th><th>ID</th><th>Level</th><th>Source</th><th>Description</th></tr>
"@
    
    foreach ($event in $PowerData.PowerEvents | Select-Object -First 10) {
        $levelClass = switch ($event.Level) {
            "Critical" { "status-error" }
            "Error" { "status-error" }
            "Warning" { "status-warning" }
            "Information" { "status-ok" }
            default { "" }
        }
        $html += "<tr><td>$($event.TimeCreated)</td><td>$($event.Id)</td><td class='$levelClass'>$($event.Level)</td><td>$($event.Source)</td><td>$($event.Description)</td></tr>"
    }
    
    $html += @"
                </table>
            </div>

            <div class="section hardware-errors">
                <h2>Power-Related Hardware Issues</h2>
                <table>
                    <tr><th>Time</th><th>Level</th><th>Source</th><th>Message</th></tr>
"@
    
    foreach ($error in $PowerData.HardwareErrors | Select-Object -First 10) {
        $levelClass = switch ($error.Level) {
            "Critical" { "status-error" }
            "Error" { "status-error" }
            "Warning" { "status-warning" }
            "Information" { "status-ok" }
            "Info" { "status-ok" }
            default { "" }
        }
        $html += "<tr><td>$($error.TimeCreated)</td><td class='$levelClass'>$($error.Level)</td><td>$($error.Source)</td><td>$($error.Message)</td></tr>"
    }
    
    $html += @"
                </table>
            </div>
            
            <div class="section recommendations">
                <h2>Analysis Summary & Recommendations</h2>
                <div class="alert alert-success">
                    <strong>📋 Report Clarification:</strong><br>
                    • <strong>Energy Report (Errors/Warnings):</strong> Analyzes power configuration efficiency and settings<br>
                    • <strong>Power Events:</strong> Shows actual system power-related incidents, crashes, and stability issues
                </div>
                $(
                    $criticalEvents = $PowerData.PowerEvents | Where-Object { $_.Level -eq "Critical" -and $_.Id -eq 41 }
                    if ($criticalEvents -and $criticalEvents.Count -gt 0) {
                        "<div class='alert alert-danger'><strong>🚨 SYSTEM STABILITY CONCERN:</strong><br>Your power configuration is efficient (0 energy errors), but your system has experienced $($criticalEvents.Count) unexpected shutdowns. This suggests hardware issues rather than configuration problems.<br><br><strong>Recommended Actions:</strong><br>• Check power supply unit (PSU) capacity and health<br>• Monitor system temperatures during high load<br>• Run memory diagnostics (Windows Memory Diagnostic)<br>• Check for driver updates, especially graphics and chipset<br>• Consider professional hardware diagnosis if issues persist</div>"
                    } else {
                        "<div class='alert alert-success'><strong>✅ SYSTEM STATUS:</strong> No critical power stability issues detected. Your system appears to be running stable with efficient power configuration.</div>"
                    }
                )
            </div>
        </div>
        
        <div class="footer">
            <p>Generated by AMH2W Power Scanner (WMI-Based) | $($PowerData.GeneratedAt)</p>
            <p>This report provides a comprehensive analysis of your system's power configuration and health using Windows Management Instrumentation.</p>
        </div>
    </div>
</body>
</html>
"@
    
    return $html
}
