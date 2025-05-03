function factor {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [int]$Number
    )

    try {
        if ($Number -lt 2) {
            return Err -Message "Can't factor numbers less than 2"
        }

        $n = $Number
        $factors = @()

        for ($div = 2; $div * $div -le $n; $div++) {
            while ($n % $div -eq 0) {
                $factors += $div
                $n /= $div
            }
        }

        if ($n -gt 1) {
            $factors += $n
        }

        $asText = "$Number = " + ($factors -join " × ")
        Write-Host ""
        Write-Host "🧮 Factors of $Number :" -ForegroundColor Cyan
        Write-Host $asText -ForegroundColor Green

        return Ok -Value $factors -Message "Prime factorization complete"
    }
    catch {
        return Err -Message "Factorization failed: $_"
    }
}
