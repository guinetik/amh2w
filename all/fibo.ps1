<#
.SYNOPSIS
Generates and displays Fibonacci numbers.

.DESCRIPTION
Calculates and displays the first N numbers in the Fibonacci sequence,
where each number is the sum of the two preceding ones, starting from 0 and 1.

.PARAMETER Count
The number of Fibonacci numbers to generate. Must be 1 or greater.

.OUTPUTS
An Ok result object containing an array of the generated Fibonacci numbers,
or an Err result object if generation fails.

.EXAMPLE
all fibo 10
# Displays the first 10 Fibonacci numbers: 0 1 1 2 3 5 8 13 21 34

.EXAMPLE
all fibo 5
# Displays the first 5 Fibonacci numbers: 0 1 1 2 3

.NOTES
File: all/fibo.ps1
Command: all fibo
Memory usage scales linearly with the number of fibonacci numbers requested.
#>
function fibo {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [int]$Count
    )

    try {
        if ($Count -lt 1) {
            return Err -Message "Must provide a number ≥ 1"
        }

        $fib = @(0)
        if ($Count -ge 2) { $fib += 1 }

        for ($i = 2; $i -lt $Count; $i++) {
            $fib += ($fib[$i - 1] + $fib[$i - 2])
        }

        Write-Host "`n🧬 First $Count Fibonacci number(s):" -ForegroundColor Cyan
        Write-Host $fib | Format-Wide -Column 8

        return Ok $fib "$Count Fibonacci numbers generated"
    }
    catch {
        return Err "Fibonacci generation failed: $_"
    }
}
