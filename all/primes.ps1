<#
.SYNOPSIS
Generates prime numbers up to a specified limit.

.DESCRIPTION
Generates and displays all prime numbers up to a given limit using the Sieve of Eratosthenes
algorithm. The function includes time measurement using the clock functionality.

.PARAMETER UpTo
The upper limit for prime number generation. Must be 2 or greater.

.OUTPUTS
An Ok result object containing an array of prime numbers up to the specified limit,
or an Err result object if generation fails.

.EXAMPLE
all primes 100
# Generates all primes up to 100

.EXAMPLE
all primes 1000
# Generates all primes up to 1000

.NOTES
File: all/primes.ps1
Command: all primes

This implementation uses the Sieve of Eratosthenes algorithm, which is efficient for
finding all primes up to a moderate limit. The algorithm has O(n log log n) time complexity.

The function also starts and stops a clock to measure execution time, which is displayed
separately from the prime numbers themselves.
#>
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
        Start-Clock
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
        Stop-Clock
        return Ok -Value $primes -Message "$($primes.Count) primes found"
    }
    catch {
        return Err -Message "Prime generation failed: $_"
    }
}
