function wifip {
    [CmdletBinding()]
    param()

    try {
        $profiles = netsh wlan show profile |
            Where-Object { $_ -match ':\s(.+)$' } |
            ForEach-Object { $matches[1] }

        $results = @()

        foreach ($name in $profiles) {
            $details = netsh wlan show profile name="$name" key=clear

            $passwordLine = $details | Where-Object { $_ -match 'Key Content\s+:\s(.+)$' }

            if ($passwordLine) {
                $null = $passwordLine -match 'Key Content\s+:\s(.+)$'
                $password = $matches[1]
            } else {
                $password = "(none)"
            }

            $results += [PSCustomObject]@{
                Profile  = $name
                Password = $password
            }
        }

        if ($results.Count -eq 0) {
            Write-Host "❌ No saved Wi-Fi profiles found." -ForegroundColor Yellow
            return Err -Msg "No Wi-Fi profiles found"
        }

        Show-JsonTable $results
        return Ok -Value $results -Message "$($results.Count) Wi-Fi password(s) retrieved"
    }
    catch {
        return Err -Msg "Failed to retrieve Wi-Fi passwords: $_"
    }
}
