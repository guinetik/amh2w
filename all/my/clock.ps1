# clock.ps1
# Provides timing functionality

function clock {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("start", "stop", "status")]
        [string]$Action = "status",
        
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    switch ($Action) {
        "start" {
            $result = Start-Clock
            if ($result) {
                return Ok -Value $result -Message "Clock started successfully"
            } else {
                return Err -Message "Failed to start clock"
            }
        }
        
        "stop" {
            $result = Stop-Clock
            if ($result.ok) {
                return Ok -Value $result.value -Message "Clock stopped successfully"
            } else {
                return Err -Message $result.error
            }
        }
        
        "status" {
            $result = Get-ClockStatus
            return Ok -Value $result -Message "Clock status retrieved"
        }
    }
}

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

# Start the clock
function Start-Clock {
    # Define the path to the temporary file that will store the start time
    $clockFile = Join-Path -Path $env:TEMP -ChildPath "amh2w_clock.txt"
    
    # Check if clock is already running
    if (Test-Path $clockFile) {
        $startTime = Get-Content $clockFile
        Log-Warning "Clock is already running (started at $startTime)"
        return $false
    }
    
    # Start the clock
    $startTime = Get-Date
    $startTimeStr = $startTime.ToString("yyyy-MM-dd HH:mm:ss.fff")
    Set-Content -Path $clockFile -Value $startTimeStr
    
    Log-Success "Clock started at $startTimeStr"
    return $true
}

# Stop the clock
function Stop-Clock {
    # Define the path to the temporary file that will store the start time
    $clockFile = Join-Path -Path $env:TEMP -ChildPath "amh2w_clock.txt"
    
    # Check if clock is running
    if (-not (Test-Path $clockFile)) {
        Log-Warning "No running clock found. Start a clock first with 'start'."
        return Err -Message "No running clock found"
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
    
    Log-Success "Clock stopped"
    Log-Info "Elapsed time: $formattedTime"
    Log-Debug "Started: $startTimeStr"
    Log-Debug "Stopped: $($endTime.ToString("yyyy-MM-dd HH:mm:ss.fff"))"
    
    return Ok -Value @{
        ElapsedTime = $formattedTime
        StartTime = $startTimeStr
        EndTime = $endTime.ToString("yyyy-MM-dd HH:mm:ss.fff")
        TotalSeconds = $elapsed.TotalSeconds
    }
}

# Get clock status
function Get-ClockStatus {
    # Define the path to the temporary file that will store the start time
    $clockFile = Join-Path -Path $env:TEMP -ChildPath "amh2w_clock.txt"
    
    # Check if clock is running
    if (-not (Test-Path $clockFile)) {
        Log-Info "No clock is currently running."
        return @{
            Running = $false
        }
    }
    
    # Get start time and calculate elapsed time
    $startTimeStr = Get-Content $clockFile
    $startTime = [DateTime]::ParseExact($startTimeStr, "yyyy-MM-dd HH:mm:ss.fff", $null)
    $currentTime = Get-Date
    $elapsed = $currentTime - $startTime
    
    # Format elapsed time
    $formattedTime = Format-TimeSpan -TimeSpan $elapsed
    
    Log-Success "Clock is running"
    Log-Info "Current elapsed time: $formattedTime"
    Log-Debug "Started: $startTimeStr"
    
    return @{
        Running = $true
        ElapsedTime = $formattedTime
        StartTime = $startTimeStr
        TotalSeconds = $elapsed.TotalSeconds
    }
}

# Check if verbose mode is enabled
function Get-VerboseMode {
    # This is a placeholder for a more complex implementation
    # that might check for global settings or environment variables
    return $VerbosePreference -eq "Continue"
}

# Only run main if this script is NOT being dot-sourced
if ($MyInvocation.InvocationName -ne '.' -and $MyInvocation.MyCommand.Name -eq 'clock.ps1') {
    clock @PSBoundParameters
}
