# dont show this to my math teacher 
function primes {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [int]$UpTo
    )

    try {
        if ($UpTo -lt 2) {
            return Err -Message "There are no primes less than 2"
        }
        $result = Start-Clock
        $sieve = @($true) * ($UpTo + 1)
        $sieve[0] = $false
        $sieve[1] = $false

        for ($p = 2; $p * $p -le $UpTo; $p++) {
            if ($sieve[$p]) {
                for ($i = $p * $p; $i -le $UpTo; $i += $p) {
                    $sieve[$i] = $false
                }
            }
        }

        $primes = for ($i = 2; $i -le $UpTo; $i++) {
            if ($sieve[$i]) { $i }
        }

        Write-Host "🔢 Primes up to $UpTo : " -ForegroundColor Cyan
        Write-Host $primes | Format-Wide -Column 10
        $result = Stop-Clock
        return Ok -Value $primes -Message "$($primes.Count) primes found"
    }
    catch {
        return Err -Message "Prime generation failed: $_"
    }
}
