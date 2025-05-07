function hybernate {
    try {
        [system.threading.thread]::currentThread.currentCulture = [system.globalization.cultureInfo]"en-US"
        $CurrentTime = $((Get-Date).ToShortTimeString())
        Write-Host "It's $CurrentTime, going to sleep now... 😴💤"
        Start-Sleep -milliseconds 500
        & rundll32.exe powrprof.dll,SetSuspendState 1,1,0 # bHibernate,bForce,bWakeupEventsDisabled
        return Ok
    } catch {
        return Err "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    }
}
