function dns {
 
    try {
        $table = Import-CSV "$PSScriptRoot/../data/popular-domains.csv"

        $stopWatch = [system.diagnostics.stopwatch]::startNew()
        if ($IsLinux) {
            foreach ($row in $table) { $nop = dig $row.Domain +short }
        }
        else {
            Clear-DnsClientCache
            foreach ($row in $table) { $nop = Resolve-DNSName $row.Domain }
        }
        [float]$elapsed = $stopWatch.Elapsed.TotalSeconds * 1000.0
        $speed = [math]::round($elapsed / $table.Length, 1)
        if ($speed -lt 10.0) {
            WriteLine "✅ Internet DNS: $($speed)ms excellent lookup time"
        }
        elseif ($speed -lt 100.0) {
            WriteLine "✅ Internet DNS: $($speed)ms lookup time"
        }
        else {  
            WriteLine "⚠️ Internet DNS: $($speed)ms slow lookup time"
        }
        Return Ok -Value $speed
    }
    catch {
        Return Err -Msg "Error: $($Error[0])"
    }
}