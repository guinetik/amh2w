<#
.SYNOPSIS
Computes the prime factorization of a number.

.DESCRIPTION
Calculates and displays the prime factorization of an integer using trial division.
The result is displayed in a readable format with the multiplication symbol (×) between factors.

.PARAMETER Number
The positive integer to factorize. Must be 2 or greater.

.OUTPUTS
An Ok result object containing an array of the prime factors, or an Err result object if factorization fails.

.EXAMPLE
all factor 12
# Returns: 12 = 2 × 2 × 3

.EXAMPLE
all factor 123456789
# Returns the prime factorization of a large number

.NOTES
File: all/factor.ps1
Command: all factor
Performance: Uses a simple trial division algorithm suitable for moderate-sized numbers.
#>
function factor {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [int]$Number
    )

    try {
        if ($Number -lt 2) {
            return Err "Can't factor numbers less than 2"
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

        return Ok $factors "Prime factorization complete"
    }
    catch {
        return Err "Factorization failed: $_"
    }
}
