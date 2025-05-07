function Display-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Message
    )
    
    Write-Host -NoNewline "[$TestName] "
    if ($Success) {
        Write-Host -ForegroundColor Green "PASSED" -NoNewline
    } else {
        Write-Host -ForegroundColor Red "FAILED" -NoNewline
    }
    Write-Host ": $Message"
}

# Test local time (default)
$localResult = all time now
Display-TestResult -TestName "Local Time" -Success $localResult.Ok -Message $localResult.Message

# Test standard time zone ID
$tzResult = all time now "Eastern Standard Time"
Display-TestResult -TestName "Time Zone ID" -Success $tzResult.Ok -Message $tzResult.Message

# Test GMT/UTC offset
$utcResult = all time now "UTC+1"
Display-TestResult -TestName "UTC Offset" -Success $utcResult.Ok -Message $utcResult.Message

# Test GMT offset with minutes
$gmtResult = all time now "GMT-5:30"
Display-TestResult -TestName "GMT Offset with Minutes" -Success $gmtResult.Ok -Message $gmtResult.Message

# Test location name
$cityResult = all time now "Fortaleza"
Display-TestResult -TestName "City Name" -Success $cityResult.Ok -Message $cityResult.Message

# Test location with spaces
$multiWordResult = all time now "New York"
Display-TestResult -TestName "Multi-word Location" -Success $multiWordResult.Ok -Message $multiWordResult.Message

# Test invalid location (should return an error but not throw an exception)
$invalidResult = all time now "NonExistentPlace12345"
Display-TestResult -TestName "Invalid Location" -Success (-not $invalidResult.Ok) -Message "Should return an Err result for invalid location"