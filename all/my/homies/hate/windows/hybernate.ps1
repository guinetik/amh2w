function hybernate {
    try {
        [system.threading.thread]::currentThread.currentCulture = [system.globalization.cultureInfo]"en-US"
        $CurrentTime = $((Get-Date).ToShortTimeString())
        Write-Host "It's $CurrentTime, going to sleep now... 😴💤"
        Start-Sleep -milliseconds 500
        & rundll32.exe powrprof.dll,SetSuspendState 1,1,0 # bHibernate,bForce,bWakeupEventsDisabled
        exit 0 # success
    } catch {
        "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
        exit 1
    }
}
