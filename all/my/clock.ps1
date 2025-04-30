# all/my/clock.ps1
param(
    [Parameter(Position = 0)]
    [ValidateSet("start", "stop", "status")]
    [string]$Action,
    
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'

$Context = New-PipelineContext
$clockFile = ""

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

function Start-Clock {
    # Define the path to the temporary file that will store the start time
    $clockFile = Join-Path -Path $env:TEMP -ChildPath "amh2w_clock.txt"
    # Check if clock is already running
    if (Test-Path $clockFile) {
        $startTime = Get-Content $clockFile
        Log warn "Clock is already running (started at $startTime)" $Context
        return Err "Clock is already running. Stop it first or use 'status' to check current time."
    }
    
    # Start the clock
    $startTime = Get-Date
    $startTimeStr = $startTime.ToString("yyyy-MM-dd HH:mm:ss.fff")
    Set-Content -Path $clockFile -Value $startTimeStr
    
    Log success "Clock started at $startTimeStr" $Context
    Write-Host "⏱️ Clock started at $startTimeStr" -ForegroundColor Green
    
    return Ok "Clock started at $startTimeStr"
}

function Stop-Clock {
    # Check if clock is running
    if (-not (Test-Path $clockFile)) {
        Log warn "No running clock found" $Context
        return Err "No running clock found. Start a clock first with 'start'."
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
    
    Log success "Clock stopped. Elapsed time: $formattedTime" $Context
    Write-Host "⏱️ Clock stopped" -ForegroundColor Green
    Write-Host "⌛ Elapsed time: $formattedTime" -ForegroundColor Cyan
    Write-Host "🕒 Started: $startTimeStr" -ForegroundColor White
    Write-Host "🕒 Stopped: $($endTime.ToString("yyyy-MM-dd HH:mm:ss.fff"))" -ForegroundColor White
    
    return Ok @{
        ElapsedTime  = $formattedTime
        StartTime    = $startTimeStr
        EndTime      = $endTime.ToString("yyyy-MM-dd HH:mm:ss.fff")
        TotalSeconds = $elapsed.TotalSeconds
    }
}

function Get-ClockStatus {
    # Check if clock is running
    if (-not (Test-Path $clockFile)) {
        Log info "No running clock found" $Context
        Write-Host "No clock is currently running." -ForegroundColor Yellow
        Write-Host "Start a clock with: all my clock start" -ForegroundColor Gray
        return Ok "No clock running"
    }
    
    # Get start time and calculate elapsed time
    $startTimeStr = Get-Content $clockFile
    $startTime = [DateTime]::ParseExact($startTimeStr, "yyyy-MM-dd HH:mm:ss.fff", $null)
    $currentTime = Get-Date
    $elapsed = $currentTime - $startTime
    
    # Format elapsed time
    $formattedTime = Format-TimeSpan -TimeSpan $elapsed
    
    Log info "Clock is running. Elapsed time: $formattedTime" $Context
    Write-Host "⏱️ Clock is running" -ForegroundColor Green
    Write-Host "⌛ Current elapsed time: $formattedTime" -ForegroundColor Cyan
    Write-Host "🕒 Started: $startTimeStr" -ForegroundColor White
    
    return Ok @{
        Running      = $true
        ElapsedTime  = $formattedTime
        StartTime    = $startTimeStr
        TotalSeconds = $elapsed.TotalSeconds
    }
}

function clock {
    # Call the appropriate function based on the Action parameter
    switch ($Action) {
        "start"  { return Start-Clock }
        "stop"   { return Stop-Clock }
        "status" { return Get-ClockStatus }
    }
}

if($Action) {
    clock
}