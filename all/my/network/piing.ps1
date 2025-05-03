function piing {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Hostname
    )

    try {
        $hosts = $Hostname -split ',' | ForEach-Object { $_.Trim() }
        if ($hosts.Count -eq 0) {
            return Err -Msg "No valid hosts provided"
        }

        Write-Progress "Pinging host(s)..." -Status "Sending ping requests"

        # Build task dictionary to preserve hostname in exception-safe way
        $taskMap = @{}
        foreach ($host_ in $hosts) {
            $ping = New-Object System.Net.NetworkInformation.Ping
            $taskMap[$host_] = $ping.SendPingAsync($host_, 5000)
        }

        # Wait individually to isolate bad hosts
        $results = @()
        foreach ($host_ in $taskMap.Keys) {
            try {
                $task = $taskMap[$host_]
                $task.Wait()
                $ping = $task.Result

                $result = [PSCustomObject]@{
                    Host    = $host_
                    Address = $ping.Address
                    Status  = $ping.Status
                    Latency = if ($ping.Status -eq "Success") { "$($ping.RoundtripTime / 2) ms" } else { "N/A" }
                    Success = $ping.Status -eq "Success"
                }

                if ($result.Success) {
                    Write-Host "✅ '$($result.Host)' is online ($($result.Latency) to IP $($result.Address))" -ForegroundColor Green
                }
                else {
                    Write-Host "⚠️ No reply from '$($result.Host)' (IP $($result.Address)) — check connection or host status." -ForegroundColor Yellow
                }

                $results += $result
            }
            catch {
                Write-Host "❌ Failed to ping '$host_': $($_.Exception.Message)" -ForegroundColor Red
                $results += [PSCustomObject]@{
                    Host    = $host_
                    Address = "N/A"
                    Status  = "Error"
                    Latency = "N/A"
                    Success = $false
                }
            }
        }

        Write-Progress "Done" -Completed

        $reachable = $results | Where-Object { $_.Success } | Measure-Object | Select-Object -ExpandProperty Count

        if ($reachable -gt 0) {
            return Ok -Value $results -Message "$reachable of $($hosts.Count) host(s) reachable"
        }
        else {
            return Err -Msg "All hosts unreachable" -Optional $true -Value $results
        }
    }
    catch {
        return Err -Msg "Ping command failed: $_"
    }
}
