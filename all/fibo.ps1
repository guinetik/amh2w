function fibo {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [int]$Count
    )

    try {
        if ($Count -lt 1) {
            return Err -Msg "Must provide a number ≥ 1"
        }

        $fib = @(0)
        if ($Count -ge 2) { $fib += 1 }

        for ($i = 2; $i -lt $Count; $i++) {
            $fib += ($fib[$i - 1] + $fib[$i - 2])
        }

        Write-Host "`n🧬 First $Count Fibonacci number(s):" -ForegroundColor Cyan
        Write-Host $fib | Format-Wide -Column 8

        return Ok -Value $fib -Message "$Count Fibonacci numbers generated"
    }
    catch {
        return Err -Msg "Fibonacci generation failed: $_"
    }
}
