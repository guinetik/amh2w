function portscan {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Subnet,  # e.g. "192.168.1"

        [Parameter(Position = 1, Mandatory = $true)]
        [int[]]$Port,     # e.g. 22 or 80,443

        [Parameter(Position = 2)]
        [int]$RangeStart = 1,

        [Parameter(Position = 3)]
        [int]$RangeEnd = 254,

        [Parameter(Position = 4)]
        [int]$TimeoutMs = 1000
    )

    try {
        if (-not $Subnet -match '^(\d{1,3}\.){2,3}\d{1,3}$') {
            return Err -Msg "Invalid subnet: $Subnet"
        }

        $results = @()
        $total = $RangeEnd - $RangeStart + 1
        $count = 0

        foreach ($i in $RangeStart..$RangeEnd) {
            $ip = "$Subnet.$i"
            $count++
            Write-Progress -Activity "Scanning $ip" -PercentComplete (($count / $total) * 100)

            if (Test-Connection -ComputerName $ip -Count 1 -Quiet -BufferSize 16 -ErrorAction SilentlyContinue) {
                foreach ($p in $Port) {
                    try {
                        $client = New-Object System.Net.Sockets.TcpClient
                        $async = $client.BeginConnect($ip, $p, $null, $null)
                        $wait = $async.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
                        if ($wait -and $client.Connected) {
                            $client.EndConnect($async)
                            $client.Close()
                            Write-Host "✅ $ip :$p is open" -ForegroundColor Green
                            $results += [PSCustomObject]@{ IP = $ip; Port = $p; Open = $true }
                        } else {
                            $client.Close()
                            $results += [PSCustomObject]@{ IP = $ip; Port = $p; Open = $false }
                        }
                    } catch {
                        $results += [PSCustomObject]@{ IP = $ip; Port = $p; Open = $false }
                    }
                }
            }
        }

        Write-Progress -Activity "Scan complete" -Completed
        $open = $results | Where-Object { $_.Open }

        if ($open.Count -eq 0) {
            Write-Host "⚠️ No open ports found." -ForegroundColor Yellow
        } else {
            Show-JsonTable $open
        }

        return Ok -Value $open -Message "$($open.Count) open ports found"
    }
    catch {
        return Err -Msg "Port scan failed: $_"
    }
}
