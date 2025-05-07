function usbs {
    try {
        $devices = Get-PnpDevice | Where-Object { $_.Class -eq "USB" } | Sort-Object -Property FriendlyName
        if ($devices) {
            $devices | Format-Table FriendlyName, DeviceID, Status -AutoSize | Out-String | Write-Host
            return Ok $devices "USB devices found"
        }
        else {
            Write-Host "⚠️ No USB devices found." -ForegroundColor Yellow
            return Ok "No devices found"
        }
    }
    catch {
        Write-Host "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
        exit 1
    }
}