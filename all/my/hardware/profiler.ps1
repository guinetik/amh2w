function profiler {
    & all my homies hate windows version
    Invoke-HardwareProfile
}
function Measure-ExecutionTime {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock
    )

    $startTime = Get-Date
    Invoke-Command -ScriptBlock $ScriptBlock
    $endTime = Get-Date
    return $endTime - $startTime
}

function Test-CPU {
    [CmdletBinding()]
    param(
        [int]$CoresToTest = $env:NUMBER_OF_PROCESSORS,
        [int]$TestDurationSeconds = 10,
        [int]$MatrixSize = 100,
        [int]$Cycles = 3  # Number of full test cycles to run
    )
    & all my hardware cpu
    Write-Host "Performing intensive CPU stress test on $CoresToTest core(s) for $Cycles cycles..." -ForegroundColor Magenta

    function Get-CPUTemperature {
        $cpuTemp = $null
        try {
            $thermalInfo = Get-WmiObject -Namespace "root/CIMV2" -Query "SELECT * FROM Win32_PerfFormattedData_Counters_ThermalZoneInformation" -ErrorAction Stop
            foreach ($item in $thermalInfo) {
                if ($item.HighPrecisionTemperature) {
                    $cpuTemp = [math]::Round($item.HighPrecisionTemperature / 10.0 - 273.15, 1)
                    break
                }
            }
        } catch { }
        return $cpuTemp
    }

    # Store temperature history
    $tempHistory = @()
    $initialTemp = Get-CPUTemperature
    $tempHistory += @{
        Cycle = 0
        Temperature = $initialTemp
        TimeStamp = Get-Date
    }
    Write-Host "`nInitial CPU Temperature: $(if ($initialTemp) { "$initialTemp°C" } else { "N/A" })" -ForegroundColor Cyan

    $allResults = @()
    $totalStartTime = Get-Date

    for ($cycle = 1; $cycle -le $Cycles; $cycle++) {
        Write-Host "`nStarting Cycle $cycle of $Cycles..." -ForegroundColor Yellow

        # Create a runspace for monitoring CPU usage during this cycle
        $monitoringRunspace = [runspacefactory]::CreateRunspace()
        $monitoringRunspace.Open()
        $monitoringPowerShell = [powershell]::Create().AddScript({
            param($TestDurationSeconds)
            $startTime = Get-Date
            $endTime = $startTime.AddSeconds($TestDurationSeconds + 2)

            while ((Get-Date) -lt $endTime) {
                $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
                $usageBar = "["
                $usagePercentage = [math]::Round($cpuUsage)
                $barLength = 20
                $filledBars = [math]::Round(($usagePercentage / 100) * $barLength)
                $usageBar += "=" * $filledBars
                $usageBar += " " * ($barLength - $filledBars)
                $usageBar += "]"

                Write-Host "`rCycle $using:cycle - CPU Usage: $usageBar $usagePercentage% " -NoNewline
                Start-Sleep -Milliseconds 500
            }
            Write-Host "" # New line at end
        }).AddArgument($TestDurationSeconds)

        $monitoringPowerShell.Runspace = $monitoringRunspace
        $monitoringHandle = $monitoringPowerShell.BeginInvoke()

        $ScriptBlockToStressCPU = {
            param($JobId, $MatrixSize)
            
            function Get-MatrixMultiplication {
                param($size)
                # Process matrices in chunks for better operation counting
                $chunkSize = 20  # Process 20x20 chunks at a time
                $matrix1 = New-Object 'double[,]' $size,$size
                $matrix2 = New-Object 'double[,]' $size,$size
                $result = New-Object 'double[,]' $size,$size
                
                # Initialize matrices with complex values
                for ($i = 0; $i -lt $size; $i++) {
                    for ($j = 0; $j -lt $size; $j++) {
                        $matrix1[$i,$j] = [math]::Sin($i * $j) * [math]::Cos($i + $j)
                        $matrix2[$i,$j] = [math]::Exp(-[math]::Sqrt($i * $j))
                    }
                }
                
                $opsCount = 0
                # Process matrix multiplication in chunks
                for ($i = 0; $i -lt $size; $i += $chunkSize) {
                    $iMax = [Math]::Min($i + $chunkSize, $size)
                    for ($j = 0; $j -lt $size; $j += $chunkSize) {
                        $jMax = [Math]::Min($j + $chunkSize, $size)
                        for ($k = 0; $k -lt $size; $k += $chunkSize) {
                            $kMax = [Math]::Min($k + $chunkSize, $size)
                            
                            # Process this chunk
                            for ($ii = $i; $ii -lt $iMax; $ii++) {
                                for ($jj = $j; $jj -lt $jMax; $jj++) {
                                    $sum = 0
                                    for ($kk = $k; $kk -lt $kMax; $kk++) {
                                        $val = $matrix1[$ii,$kk] * $matrix2[$kk,$jj]
                                        $sum += $val
                                        $opsCount++
                                    }
                                    $result[$ii,$jj] += $sum
                                }
                            }
                        }
                    }
                }
                
                return $opsCount
            }

            function Get-IntensiveMathOperation {
                $opsCount = 0
                $x = 1.0
                
                # Do operations in smaller batches
                for ($batch = 0; $batch -lt 10; $batch++) {
                    for ($i = 0; $i -lt 100; $i++) {
                        $x = [Math]::Sqrt([Math]::Pow($x + [Math]::PI, 2) + [Math]::E)
                        $x = [Math]::Sin($x) * [Math]::Cos($x) + [Math]::Tan($x)
                        $x = [Math]::Log($x + [Math]::E) + [Math]::Pow($x, 1/3)
                        $x = [Math]::Sinh($x) + [Math]::Cosh($x)
                        $x = [Math]::Atan2($x, $x + 1) * [Math]::PI
                        
                        if ($x -gt 1e308) { $x = 1.0 }
                        $opsCount += 5  # Count each complex math operation
                    }
                }
                return $opsCount
            }

            function Test-PrimeNumber {
                param($max = 25000)  # Reduced range but will count more operations
                $opsCount = 0
                for ($num = 2; $num -lt $max; $num++) {
                    $sqrt = [math]::Sqrt($num)
                    for ($i = 2; $i -le $sqrt; $i++) {
                        $opsCount++  # Count each division check
                        if ($num % $i -eq 0) {
                            break
                        }
                    }
                }
                return $opsCount
            }

            $startTime = Get-Date
            $endTime = $startTime.AddSeconds($using:TestDurationSeconds)
            $totalOpsCount = 0
            
            while ((Get-Date) -lt $endTime) {
                # Run operations and accumulate their operation counts
                $matrixOps = Get-MatrixMultiplication -size $using:MatrixSize
                $mathOps = Get-IntensiveMathOperation
                $primeOps = Test-PrimeNumber
                
                $totalOpsCount += ($matrixOps + $mathOps + $primeOps)
            }
            
            $duration = (Get-Date) - $startTime
            $opsPerSecond = $totalOpsCount / $duration.TotalSeconds
            
            return @{
                JobId = $JobId
                OperationsCompleted = $totalOpsCount
                OperationsPerSecond = $opsPerSecond
                Duration = $duration.TotalSeconds
            }
        }

        $jobs = @()
        $results = @()
    
        try {
            Write-Host "Starting $CoresToTest intensive computation job(s)..."
            foreach ($coreNumber in 1..$CoresToTest) {
                $jobs += Start-Job -ScriptBlock $ScriptBlockToStressCPU -ArgumentList $coreNumber,$MatrixSize
            }

            if ($jobs.Count -gt 0) {
                $jobs | Wait-Job | Out-Null
                
                foreach ($job in $jobs) {
                    $jobResult = Receive-Job $job
                    $results += $jobResult
                }
                
                $totalOps = ($results | Measure-Object -Property OperationsCompleted -Sum).Sum
                $avgOpsPerSecond = ($results | Measure-Object -Property OperationsPerSecond -Average).Average

                # Store results for this cycle
                $allResults += @{
                    Cycle = $cycle
                    TotalOps = $totalOps
                    AverageOpsPerSecond = $avgOpsPerSecond
                }

                # Get temperature after this cycle
                $currentTemp = Get-CPUTemperature
                $tempHistory += @{
                    Cycle = $cycle
                    Temperature = $currentTemp
                    TimeStamp = Get-Date
                }

                Write-Host "`nCycle $cycle Results:" -ForegroundColor Yellow
                Write-Host "------------------------"
                Write-Host "Total Operations Completed : $([math]::Round($totalOps/1000000, 2)) million"
                Write-Host "Average MOps/Second per Core: $([math]::Round($avgOpsPerSecond/1000000, 2))"
                Write-Host "Total MOps/Second (all cores): $([math]::Round($avgOpsPerSecond * $CoresToTest/1000000, 2))"
                Write-Host "CPU Temperature: $(if ($currentTemp) { "$currentTemp°C" } else { "N/A" })"
            }
        } finally {
            if ($jobs.Count -gt 0) {
                $jobs | Remove-Job -Force
            }
            
            # Clean up monitoring runspace
            $monitoringPowerShell.EndInvoke($monitoringHandle)
            $monitoringPowerShell.Dispose()
            $monitoringRunspace.Dispose()
        }

        # If not the last cycle, add a small cooldown period
        if ($cycle -lt $Cycles) {
            Write-Host "`nCooldown period between cycles (5 seconds)..." -ForegroundColor Cyan
            Start-Sleep -Seconds 5
        }
    }

    $totalDuration = (Get-Date) - $totalStartTime
    $finalTemp = Get-CPUTemperature

    # Calculate temperature statistics
    $temps = $tempHistory.Temperature | Where-Object { $null -ne $_ }
    if ($temps) {
        $maxTemp = ($temps | Measure-Object -Maximum).Maximum
        $minTemp = ($temps | Measure-Object -Minimum).Minimum
        $tempIncrease = if ($initialTemp -and $finalTemp) { $finalTemp - $initialTemp } else { $null }
    }

    # Calculate average performance across all cycles
    $avgTotalOps = ($allResults | Measure-Object -Property TotalOps -Average).Average
    $avgOpsPerSecond = ($allResults | Measure-Object -Property AverageOpsPerSecond -Average).Average
    $benchmarkScore = [math]::Round(($avgOpsPerSecond * $CoresToTest) / 10000)

    Write-Host "`nFinal CPU Performance Summary:" -ForegroundColor Green
    Write-Host "=============================" -ForegroundColor Green
    Write-Host "Total Test Duration        : $([math]::Round($totalDuration.TotalSeconds, 2)) seconds"
    Write-Host "Cycles Completed          : $Cycles"
    Write-Host "Average MOps/Second       : $([math]::Round($avgOpsPerSecond * $CoresToTest/1000000, 2))"
    Write-Host "Benchmark Score           : $benchmarkScore"
    Write-Host "`nTemperature Analysis:" -ForegroundColor Yellow
    Write-Host "Initial Temperature      : $(if ($initialTemp) { "$initialTemp°C" } else { "N/A" })"
    Write-Host "Final Temperature        : $(if ($finalTemp) { "$finalTemp°C" } else { "N/A" })"
    if ($temps) {
        Write-Host "Maximum Temperature      : ${maxTemp}°C"
        Write-Host "Minimum Temperature      : ${minTemp}°C"
        if ($null -ne $tempIncrease) {
            Write-Host "Total Temperature Change: $(if ($tempIncrease -ge 0){"+"})${tempIncrease}°C"
        }
    }

    Write-Host "`nCPU stress test completed." -ForegroundColor Magenta
    
    return @{
        BenchmarkScore = $benchmarkScore
        AverageOperationsPerSecond = $avgOpsPerSecond * $CoresToTest
        CoresUsed = $CoresToTest
        Cycles = $Cycles
        TotalDuration = $totalDuration.TotalSeconds
        TemperatureData = @{
            Initial = $initialTemp
            Final = $finalTemp
            Maximum = $maxTemp
            Minimum = $minTemp
            Change = $tempIncrease
            History = $tempHistory
        }
        CycleResults = $allResults
    }
}

function Analyze-FurMarkResults {
    param(
        [string]$FurMarkDir
    )

    $scores = Import-Csv -Path (Join-Path $FurMarkDir "_scores.csv")
    $maxTimeScores = Import-Csv -Path (Join-Path $FurMarkDir "_scores_maxtime.csv")
    
    # Get the latest results from each file
    $latestScore = $scores | Select-Object -Last 1
    $latestMaxTime = $maxTimeScores | Select-Object -Last 1
    
    # Extract GPU info
    $gpuInfo = @{
        Vendor = $latestScore.vendor
        Model = $latestScore.renderer -replace '/PCIe/SSE2', ''
        API = $latestScore.api_version
    }
    
    # Analyze temperature
    $maxTemp = [int]$latestScore.max_gpu_temp
    $tempAnalysis = switch ($maxTemp) {
        {$_ -lt 70} { "Excellent thermal performance" }
        {$_ -lt 80} { "Good thermal performance" }
        {$_ -lt 85} { "Acceptable thermal performance, but consider improving cooling" }
        default { "High temperatures detected. GPU might be thermal throttling" }
    }
    
    # Analyze FPS stability
    $avgFPS = [double]$latestScore.avg_fps
    $minFPS = [double]$latestScore.min_fps
    $maxFPS = [double]$latestScore.max_fps
    $fpsVariance = $maxFPS - $minFPS
    $fpsStability = switch ($fpsVariance) {
        {$_ -lt 5} { "Excellent FPS stability" }
        {$_ -lt 10} { "Good FPS stability" }
        {$_ -lt 15} { "Acceptable FPS stability" }
        default { "High FPS variance detected" }
    }
    
    # Performance rating based on average FPS in FurMark (these thresholds are for 1080p)
    $performanceRating = switch ($avgFPS) {
        {$_ -gt 100} { "Exceptional performance - High-end GPU" }
        {$_ -gt 60} { "Very good performance - Suitable for demanding gaming" }
        {$_ -gt 45} { "Good performance - Capable of smooth 1080p gaming" }
        {$_ -gt 30} { "Moderate performance - May struggle with demanding titles" }
        default { "Limited performance - May have difficulty with modern games" }
    }

    Write-Host "`nGPU Test Analysis:" -ForegroundColor Green
    Write-Host "=================" -ForegroundColor Green
    Write-Host "`nHardware Information:" -ForegroundColor Cyan
    Write-Host "  GPU: $($gpuInfo.Model)"
    Write-Host "  Vendor: $($gpuInfo.Vendor)"
    Write-Host "  Graphics API: $($gpuInfo.API)"
    
    Write-Host "`nPerformance Metrics:" -ForegroundColor Cyan
    Write-Host "  Average FPS: $avgFPS"
    Write-Host "  Minimum FPS: $minFPS"
    Write-Host "  Maximum FPS: $maxFPS"
    Write-Host "  FPS Variance: $fpsVariance"
    Write-Host "  Maximum Temperature: ${maxTemp}°C"
    
    Write-Host "`nAnalysis:" -ForegroundColor Yellow
    Write-Host "  Performance Rating: $performanceRating"
    Write-Host "  Temperature: $tempAnalysis"
    Write-Host "  Stability: $fpsStability"
    
    # Recommendations based on analysis
    Write-Host "`nRecommendations:" -ForegroundColor Magenta
    if ($maxTemp -gt 80) {
        Write-Host "  • Consider improving system cooling or GPU fan curve"
        Write-Host "  • Check if GPU thermal paste needs replacement"
    }
    if ($fpsVariance -gt 15) {
        Write-Host "  • Performance inconsistency detected - check for background processes"
        Write-Host "  • Monitor GPU power delivery and clock speeds"
    }
    if ($avgFPS -lt 30) {
        Write-Host "  • GPU might need upgrade for modern gaming"
        Write-Host "  • Consider lowering graphics settings in games"
    }

    return @{
        GPU = $gpuInfo
        Performance = @{
            AverageFPS = $avgFPS
            MinimumFPS = $minFPS
            MaximumFPS = $maxFPS
            FPSVariance = $fpsVariance
            MaxTemperature = $maxTemp
        }
        Analysis = @{
            PerformanceRating = $performanceRating
            ThermalAnalysis = $tempAnalysis
            StabilityAnalysis = $fpsStability
        }
    }
}

function Test-GPU {
    [CmdletBinding()]
    param(
        [int]$VRAMTestGB = 4,
        [int]$VRAMTestDurationSeconds = 60,
        [int]$BenchmarkDurationSeconds = 60
    )

    & all my hardware gpu
    Write-Host "Starting GPU stress test with FurMark..." -ForegroundColor Magenta
    
    try {
        # Create temp directory for FurMark
        $tempDir = Join-Path $env:TEMP "FurMarkTest"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir | Out-Null
        }
        
        # Download FurMark
        $furmarkUrl = "https://geeks3d.com/dl/get/803"
        $zipPath = Join-Path $tempDir "FurMark.zip"
        Write-Host "Downloading FurMark..." -ForegroundColor Yellow
        
        # Use .NET WebClient for download
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($furmarkUrl, $zipPath)
        
        # Extract the zip
        Write-Host "Extracting FurMark..." -ForegroundColor Yellow
        Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
        
        # Find FurMark executable
        $furmarkExe = Get-ChildItem -Path $tempDir -Recurse -Filter "FurMark.exe" | Select-Object -First 1
        
        if ($null -eq $furmarkExe) {
            throw "FurMark.exe not found in extracted files"
        }

        # Step 1: VRAM Test
        Write-Host "`nStarting VRAM Test ($VRAMTestGB GB for $VRAMTestDurationSeconds seconds)..." -ForegroundColor Yellow
        $vramArgs = @(
            "--demo", "furmark-gl",
            "--width", "1920",
            "--height", "1080",
            "--furmark-vram-test-gb", "$VRAMTestGB"
        )
        
        Write-Host "Running VRAM test with command: $($furmarkExe.Name) $($vramArgs -join ' ')" -ForegroundColor Cyan
        $vramProcess = Start-Process -FilePath $furmarkExe.FullName -ArgumentList $vramArgs -NoNewWindow -PassThru
        
        # Wait for specified duration then kill the process
        Write-Host "Waiting for VRAM test to complete..."
        Start-Sleep -Seconds $VRAMTestDurationSeconds
        if (-not $vramProcess.HasExited) {
            Stop-Process -Id $vramProcess.Id -Force
        }
        
        # Give system a moment to recover
        Start-Sleep -Seconds 10
        
        # Step 2: Benchmark Test
        Write-Host "`nStarting Benchmark Test..." -ForegroundColor Yellow
        $benchmarkArgs = @(
            "--demo", "furmark-gl",
            "--benchmark",
            "--width", "1920",
            "--height", "1080",
            "--no-score-box",
            "--max-time", "$BenchmarkDurationSeconds"
        )
        
        Write-Host "Running benchmark with command: $($furmarkExe.Name) $($benchmarkArgs -join ' ')" -ForegroundColor Cyan
        $benchmarkProcess = Start-Process -FilePath $furmarkExe.FullName -ArgumentList $benchmarkArgs -NoNewWindow -PassThru -Wait
        
        if ($benchmarkProcess.ExitCode -ne 0) {
            Write-Warning "FurMark benchmark exited with code: $($benchmarkProcess.ExitCode)"
        }

        # Analyze results
        $results = Analyze-FurMarkResults -FurMarkDir $furmarkExe.DirectoryName
        
        # Cleanup
        Write-Host "`nCleaning up temporary files..." -ForegroundColor Yellow
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "GPU stress test completed." -ForegroundColor Magenta

        return $results
    }
    catch {
        Write-Error "GPU stress test failed: $_"
        throw
    }
}

function Get-SystemPerformance {
    [CmdletBinding()]
    param()

    Write-Host "Gathering system performance data..." -ForegroundColor Magenta

    # Get CPU Temperature (from cpu.ps1 logic)
    $cpuTemp = $null
    try {
        $thermalInfo = Get-WmiObject -Namespace "root/CIMV2" -Query "SELECT * FROM Win32_PerfFormattedData_Counters_ThermalZoneInformation" -ErrorAction Stop
        foreach ($item in $thermalInfo) {
            if ($item.HighPrecisionTemperature) {
                $cpuTemp = [math]::Round($item.HighPrecisionTemperature / 10.0 - 273.15, 1) # Convert from Kelvin to Celsius
                break
            }
        }
    } catch {
        Log-Warning "Could not retrieve CPU temperature: $_" # Assuming Log-Warning is available in the framework
    }

    # Get CPU Usage
    $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue
    $cpuUsageFormatted = "{0:N2}%" -f $cpuUsage

    # Get GPU Temperature and Usage (NVIDIA example, AMD/Intel will differ or might not be available via WMI directly)
    # This part is highly dependent on the GPU vendor and installed drivers.
    # For NVIDIA, temperature might be available via: Get-WmiObject -Namespace "root\cimv2\nv" -Query "SELECT * FROM NV_ThermalInformation"
    # Usage is even harder to get reliably via WMI for all vendors.
    $gpuTemp = $null
    $gpuUsage = $null
    try {
        # Attempt to get NVIDIA GPU temperature
        $nvidiaThermal = Get-WmiObject -Namespace "root\CIMV2\NV" -Query "SELECT * FROM NV_ThermalSensor" -ErrorAction SilentlyContinue
        if ($nvidiaThermal) {
            $gpuTemp = $nvidiaThermal[0].CurrentTemp
        }
    } catch {
        # Silently ignore if NVIDIA WMI classes are not found or query fails
    }
    
    # If you have OpenHardwareMonitor or similar running with its WMI interface enabled, you could query that:
    # try {
    #     $ohmSensor = Get-WmiObject -Namespace root\OpenHardwareMonitor -Class Sensor -Filter "SensorType='Temperature' AND Name LIKE '%GPU Core%'"
    #     if ($ohmSensor) { $gpuTemp = $ohmSensor[0].Value }
    #     $ohmSensorLoad = Get-WmiObject -Namespace root\OpenHardwareMonitor -Class Sensor -Filter "SensorType='Load' AND Name LIKE '%GPU Core%'"
    #     if ($ohmSensorLoad) { $gpuUsage = $ohmSensorLoad[0].Value }
    # } catch {
    #     # Silently ignore if OpenHardwareMonitor WMI is not available
    # }


    Write-Host "CPU Temperature: $(if ($cpuTemp) { "$cpuTemp °C" } else { "N/A" })" -ForegroundColor Yellow
    Write-Host "CPU Usage      : $cpuUsageFormatted" -ForegroundColor Yellow
    Write-Host "GPU Temperature: $(if ($gpuTemp) { "$gpuTemp °C" } else { "N/A (Vendor specific)" })" -ForegroundColor Yellow
    Write-Host "GPU Usage      : $(if ($gpuUsage) { "$gpuUsage %" } else { "N/A (Vendor specific)" })" -ForegroundColor Yellow

    Write-Host "System performance data gathering finished." -ForegroundColor Magenta
    
    return [PSCustomObject]@{
        CPUTemperature = $cpuTemp
        CPUUsage = $cpuUsage
        GPUTemperature = $gpuTemp
        GPUUsage = $gpuUsage
    }
}

function Test-RAM {
    [CmdletBinding()]
    param(
        [int]$Cycles = 2,
        [int]$FillSleepSeconds = 11,
        [int]$CleanupSleepSeconds = 9
    )
    & all my hardware ram
    Write-Host "Starting RAM stress test for $Cycles cycles..." -ForegroundColor Magenta
    
    try {
        # Create temp directory for TestLimit
        $tempDir = Join-Path $env:TEMP "TestLimitTest"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir | Out-Null
        }
        
        # Download TestLimit
        $testLimitUrl = "https://download.sysinternals.com/files/Testlimit.zip"
        $zipPath = Join-Path $tempDir "TestLimit.zip"
        Write-Host "Downloading TestLimit..." -ForegroundColor Yellow
        
        # Use .NET WebClient for download
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($testLimitUrl, $zipPath)
        
        # Extract the zip
        Write-Host "Extracting TestLimit..." -ForegroundColor Yellow
        Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
        
        # Find TestLimit executable (prefer 64-bit version)
        $testLimitExe = Get-ChildItem -Path $tempDir -Recurse -Filter "testlimit64.exe" | Select-Object -First 1
        if ($null -eq $testLimitExe) {
            $testLimitExe = Get-ChildItem -Path $tempDir -Recurse -Filter "testlimit.exe" | Select-Object -First 1
        }
        
        if ($null -eq $testLimitExe) {
            throw "TestLimit executable not found in extracted files"
        }

        # Store metrics for each cycle
        $metrics = @()
        
        for ($cycle = 1; $cycle -le $Cycles; $cycle++) {
            Write-Host "`nStarting Cycle $cycle of $Cycles..." -ForegroundColor Yellow
            
            # Get initial memory stats
            $initialMemory = Get-Counter '\Memory\Available MBytes' -ErrorAction SilentlyContinue
            $initialAvailableMB = $initialMemory.CounterSamples[0].CookedValue
            
            # Start TestLimit without opening a new window
            $startTime = Get-Date
            $testLimitProcess = Start-Process -FilePath $testLimitExe.FullName -ArgumentList "-d" -NoNewWindow -PassThru
            
            Write-Host "Waiting for memory to fill ($FillSleepSeconds seconds)..." -ForegroundColor Yellow
            Start-Sleep -Seconds $FillSleepSeconds
            
            # Get peak memory usage
            $peakMemory = Get-Counter '\Memory\Available MBytes' -ErrorAction SilentlyContinue
            $peakAvailableMB = $peakMemory.CounterSamples[0].CookedValue
            
            # Stop TestLimit
            if ($null -ne $testLimitProcess) {
                Stop-Process -Id $testLimitProcess.Id -Force
            }
            
            Write-Host "Waiting for memory cleanup ($CleanupSleepSeconds seconds)..." -ForegroundColor Yellow
            Start-Sleep -Seconds $CleanupSleepSeconds
            
            # Get final memory stats
            $endTime = Get-Date
            $finalMemory = Get-Counter '\Memory\Available MBytes' -ErrorAction SilentlyContinue
            $finalAvailableMB = $finalMemory.CounterSamples[0].CookedValue
            
            # Calculate metrics
            $cycleMetrics = @{
                Cycle = $cycle
                StartTime = $startTime
                EndTime = $endTime
                Duration = ($endTime - $startTime).TotalSeconds
                InitialAvailableMemoryMB = $initialAvailableMB
                PeakAvailableMemoryMB = $peakAvailableMB
                FinalAvailableMemoryMB = $finalAvailableMB
                MemoryUsedMB = $initialAvailableMB - $peakAvailableMB
            }
            
            $metrics += $cycleMetrics
            
            Write-Host "Cycle $cycle Metrics:" -ForegroundColor Cyan
            Write-Host "  Duration: $([math]::Round($cycleMetrics.Duration, 2)) seconds"
            Write-Host "  Initial Available Memory: $([math]::Round($cycleMetrics.InitialAvailableMemoryMB, 2)) MB"
            Write-Host "  Peak Memory Usage: $([math]::Round($cycleMetrics.MemoryUsedMB, 2)) MB"
            Write-Host "  Final Available Memory: $([math]::Round($cycleMetrics.FinalAvailableMemoryMB, 2)) MB"
        }
        
        # Calculate overall statistics
        $avgMemoryUsed = ($metrics | Measure-Object -Property MemoryUsedMB -Average).Average
        $maxMemoryUsed = ($metrics | Measure-Object -Property MemoryUsedMB -Maximum).Maximum
        
        Write-Host "`nOverall RAM Test Statistics:" -ForegroundColor Green
        Write-Host "------------------------"
        Write-Host "Average Memory Used: $([math]::Round($avgMemoryUsed, 2)) MB"
        Write-Host "Maximum Memory Used: $([math]::Round($maxMemoryUsed, 2)) MB"
        Write-Host "Total Test Duration: $([math]::Round(($metrics[-1].EndTime - $metrics[0].StartTime).TotalSeconds, 2)) seconds"
        
        # Cleanup
        Write-Host "`nCleaning up temporary files..." -ForegroundColor Yellow
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "RAM stress test completed." -ForegroundColor Magenta
        
        return @{
            Metrics = $metrics
            Statistics = @{
                AverageMemoryUsedMB = $avgMemoryUsed
                MaxMemoryUsedMB = $maxMemoryUsed
                TotalDuration = ($metrics[-1].EndTime - $metrics[0].StartTime).TotalSeconds
            }
        }
    }
    catch {
        Write-Error "RAM stress test failed: $_"
        throw
    }
}

function Invoke-HardwareProfile {
    [CmdletBinding()]
    param()

    try {
        Write-Host "Starting hardware profiling..." -ForegroundColor Green
        # Get initial system performance
        Write-Host "`nGathering initial system state..." -ForegroundColor Cyan
        $initialPerformance = Get-SystemPerformance

        # RAM Test
        Write-Host "`nRunning RAM Test..." -ForegroundColor Cyan
        $ramTestTime = Measure-ExecutionTime -ScriptBlock {
            Test-RAM
        }
        Write-Host "RAM Test completed in: $($ramTestTime.TotalSeconds) seconds" -ForegroundColor Yellow

        # CPU Test
        Write-Host "`nRunning CPU Test..." -ForegroundColor Cyan
        $cpuTestTime = Measure-ExecutionTime -ScriptBlock {
            Test-CPU
        }
        Write-Host "CPU Test completed in: $($cpuTestTime.TotalSeconds) seconds" -ForegroundColor Yellow

        # GPU Test
        Write-Host "`nRunning GPU Test..." -ForegroundColor Cyan
        $gpuTestTime = Measure-ExecutionTime -ScriptBlock {
            Test-GPU
        }
        Write-Host "GPU Test completed in: $($gpuTestTime.TotalSeconds) seconds" -ForegroundColor Yellow

        # Get final system performance
        Write-Host "`nGathering final system state..." -ForegroundColor Cyan
        $finalPerformance = Get-SystemPerformance

        Write-Host "`nHardware Profiling Summary:" -ForegroundColor Green
        Write-Host "----------------------------" -ForegroundColor Green
        Write-Host "RAM Test Duration: $($ramTestTime.TotalSeconds) seconds"
        Write-Host "CPU Test Duration: $($cpuTestTime.TotalSeconds) seconds"
        Write-Host "GPU Test Duration: $($gpuTestTime.TotalSeconds) seconds"
        
        Write-Host "`nInitial State:" -ForegroundColor Yellow
        Write-Host "  CPU Temperature: $(if ($initialPerformance.CPUTemperature) { "$($initialPerformance.CPUTemperature) °C" } else { "N/A" })"
        Write-Host "  CPU Usage      : $(if ($initialPerformance.CPUUsage) { "{0:N2}%" -f $initialPerformance.CPUUsage } else { "N/A" })"
        Write-Host "  GPU Temperature: $(if ($initialPerformance.GPUTemperature) { "$($initialPerformance.GPUTemperature) °C" } else { "N/A (Vendor specific)" })"
        Write-Host "  GPU Usage      : $(if ($initialPerformance.GPUUsage) { "$($initialPerformance.GPUUsage)%" } else { "N/A (Vendor specific)" })"

        Write-Host "`nFinal State (after tests):" -ForegroundColor Yellow
        Write-Host "  CPU Temperature: $(if ($finalPerformance.CPUTemperature) { "$($finalPerformance.CPUTemperature) °C" } else { "N/A" })"
        Write-Host "  CPU Usage      : $(if ($finalPerformance.CPUUsage) { "{0:N2}%" -f $finalPerformance.CPUUsage } else { "N/A" })"
        Write-Host "  GPU Temperature: $(if ($finalPerformance.GPUTemperature) { "$($finalPerformance.GPUTemperature) °C" } else { "N/A (Vendor specific)" })"
        Write-Host "  GPU Usage      : $(if ($finalPerformance.GPUUsage) { "$($finalPerformance.GPUUsage)%" } else { "N/A (Vendor specific)" })"
        
        Write-Host "`nHardware profiling finished." -ForegroundColor Green

        return Ok -Value ([PSCustomObject]@{
            RAMTestDurationSeconds = $ramTestTime.TotalSeconds
            CPUTestDurationSeconds = $cpuTestTime.TotalSeconds
            GPUTestDurationSeconds = $gpuTestTime.TotalSeconds
            InitialPerformance = $initialPerformance
            FinalPerformance = $finalPerformance
        })
    } catch {
        Write-Error "Hardware profiling failed: $_"
        return Err -Message "Hardware profiling failed: $_"
    }
}

# Export the function if this is part of a module
# Export-ModuleMember -Function Invoke-HardwareProfile

# Example usage (remove or comment out in final script)
# Invoke-HardwareProfile 