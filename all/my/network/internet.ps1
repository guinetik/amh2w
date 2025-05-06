function internet {
    [CmdletBinding()]
    param(
        [string[]]$Hosts = @(
            "bing.com", "cnn.com", "dropbox.com", "github.com", "google.com",
            "ibm.com", "live.com", "meta.com", "x.com", "youtube.com"
        )
    )

    try {
        if ($IsLinux) {
            Write-Host "⚠️  Linux not supported yet — implement with ping or fping" -ForegroundColor Yellow
            return Err -Message "Linux not yet supported"
        }

        Write-Progress -Activity "Pinging hosts..." -Status "Sending parallel requests"
        $tasks = $Hosts | ForEach-Object { (New-Object Net.NetworkInformation.Ping).SendPingAsync($_, 1000) }
        [Threading.Tasks.Task]::WaitAll($tasks)

        [int]$min = 9999999
        [int]$max = 0
        [int]$sum = 0
        [int]$success = 0
        [int]$total = $Hosts.Count

        $results = @()
        for ($i = 0; $i -lt $total; $i++) {
            $hostd = $Hosts[$i]
            $ping = $tasks[$i].Result
            $roundtrip = if ($ping.Status -eq "Success") { [int]$ping.RoundtripTime } else { $null }

            $results += [PSCustomObject]@{
                Host     = $hostd
                Status   = $ping.Status
                Latency  = $roundtrip
            }

            if ($ping.Status -eq "Success") {
                $success++
                $sum += $roundtrip
                if ($roundtrip -lt $min) { $min = $roundtrip }
                if ($roundtrip -gt $max) { $max = $roundtrip }
            }
        }

        Write-Progress "Done" -Completed

        $loss = $total - $success
        $emoji = "✅"
        $summary = ""

        if ($success -eq 0) {
            $emoji = "❌"
            $summary = "$emoji Internet offline (100% packet loss)"
        } elseif ($loss -gt 0) {
            $avg = [math]::Round($sum / $success, 1)
            $summary = "$emoji Partial connectivity: $loss/$total failed — avg $avg ms ($min...$max)"
        } else {
            $avg = [math]::Round($sum / $success, 1)
            $summary = "$emoji Online: $avg ms average latency ($min...$max ms)"
        }

        Write-Host "`n🌐 Internet Check:" -ForegroundColor Cyan
        Write-Host "------------------" -ForegroundColor Cyan
        Write-Host $summary -ForegroundColor Green

        return Ok -Value @{
            Summary = $summary
            Stats   = @{
                Average = $avg
                Min     = $min
                Max     = $max
                Loss    = $loss
                Total   = $total
                Success = $success
            }
            Results = $results
        }
    }
    catch {
        return Err -Message "Internet check failed: $_"
    }
}
