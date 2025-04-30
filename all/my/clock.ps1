# clock.ps1
# Provides timing functionality

function clock {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("start", "stop", "status")]
        [string]$Action = "status"
    )
    
    # Define the path to the temporary file that will store the start time
    $clockFile = Join-Path -Path $env:TEMP -ChildPath "amh2w_clock.txt"
    
    # Function to format time span
    function Format-TimeSpan {
        param(
            [TimeSpan]$TimeSpan
        )
        
        # Format with appropriate precision
        if ($TimeSpan.TotalHours -ge 1) {
            return "{0:0}h {1:0}m {2:0.0}s" -f $TimeSpan.Hours, $TimeSpan.Minutes, $TimeSpan.Seconds
        }
        elseif ($TimeSpan.TotalMinutes -ge 1) {
            return "{0:0}m {1:0.0}s" -f $TimeSpan.Minutes, $TimeSpan.Seconds
        }
        else {
            return "{0:0.00}s" -f $TimeSpan.TotalSeconds
        }
    }
    
    # Call the appropriate function based on the Action parameter
    switch ($Action) {
        "start" {
            # Check if clock is already running
            if (Test-Path $clockFile) {
                $startTime = Get-Content $clockFile
                Write-Host "⚠️ Clock is already running (started at $startTime)" -ForegroundColor Yellow
                return $false
            }
            
            # Start the clock
            $startTime = Get-Date
            $startTimeStr = $startTime.ToString("yyyy-MM-dd HH:mm:ss.fff")
            Set-Content -Path $clockFile -Value $startTimeStr
            
            Write-Host "⏱️ Clock started at $startTimeStr" -ForegroundColor Green
            return $true
        }
        
        "stop" {
            # Check if clock is running
            if (-not (Test-Path $clockFile)) {
                Write-Host "⚠️ No running clock found. Start a clock first with 'start'." -ForegroundColor Yellow
                return $false
            }
            
            # Get start time and calculate elapsed time
            $startTimeStr = Get-Content $clockFile
            $startTime = [DateTime]::ParseExact($startTimeStr, "yyyy-MM-dd HH:mm:ss.fff", $null)
            $endTime = Get-Date
            $elapsed = $endTime - $startTime
            
            # Format elapsed time
            $formattedTime = Format-TimeSpan -TimeSpan $elapsed
            
            # Stop the clock (remove the file)
            Remove-Item $clockFile
            
            Write-Host "⏱️ Clock stopped" -ForegroundColor Green
            Write-Host "⌛ Elapsed time: $formattedTime" -ForegroundColor Cyan
            Write-Host "🕒 Started: $startTimeStr" -ForegroundColor White
            Write-Host "🕒 Stopped: $($endTime.ToString("yyyy-MM-dd HH:mm:ss.fff"))" -ForegroundColor White
            
            return @{
                ElapsedTime = $formattedTime
                StartTime = $startTimeStr
                EndTime = $endTime.ToString("yyyy-MM-dd HH:mm:ss.fff")
                TotalSeconds = $elapsed.TotalSeconds
            }
        }
        
        "status" {
            # Check if clock is running
            if (-not (Test-Path $clockFile)) {
                Write-Host "No clock is currently running." -ForegroundColor Yellow
                Write-Host "Start a clock with: all my clock start" -ForegroundColor Gray
                return $false
            }
            
            # Get start time and calculate elapsed time
            $startTimeStr = Get-Content $clockFile
            $startTime = [DateTime]::ParseExact($startTimeStr, "yyyy-MM-dd HH:mm:ss.fff", $null)
            $currentTime = Get-Date
            $elapsed = $currentTime - $startTime
            
            # Format elapsed time
            $formattedTime = Format-TimeSpan -TimeSpan $elapsed
            
            Write-Host "⏱️ Clock is running" -ForegroundColor Green
            Write-Host "⌛ Current elapsed time: $formattedTime" -ForegroundColor Cyan
            Write-Host "🕒 Started: $startTimeStr" -ForegroundColor White
            
            return @{
                Running = $true
                ElapsedTime = $formattedTime
                StartTime = $startTimeStr
                TotalSeconds = $elapsed.TotalSeconds
            }
        }
    }
}
