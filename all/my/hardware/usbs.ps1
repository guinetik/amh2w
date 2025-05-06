function usbs { 
    try {
        Get-PnpDevice | Where-Object { $_.Class -eq "USB" } | Sort-Object -property FriendlyName | Format-Table -property FriendlyName, Status, InstanceId
        exit 0 # success
    }
    catch {
        "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
        exit 1
    }
}