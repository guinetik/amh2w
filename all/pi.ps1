function pi {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [int]$Digits = 1000
    )

    try {

        Write-Host "🧮 Calculating π to $Digits digits..." -ForegroundColor Cyan

        if($Digits -gt 5000) {
            Write-Host "⌛ This may take a while..." -ForegroundColor Yellow
        }

        $Big = [bigint[]](0..10)

        $ndigits = 0
        $line = ""

        $q = $t = $k = $Big[1]
        $r =           $Big[0]
        $l = $n =      $Big[3]

        # Initial digit
        $nr = ( $Big[2] * $q + $r ) * $l
        $nn = ( $q * ( $Big[7] * $k + $Big[2] ) + $r * $l ) / ( $t * $l )
        $q *= $k
        $t *= $l
        $l += $Big[2]
        $k += $Big[1]
        $n = $nn
        $r = $nr

        $output = "$($n)."
        $ndigits++

        $nr = $Big[10] * ( $r - $n * $t )
        $n = ( ( $Big[10] * ( 3 * $q + $r ) ) / $t ) - 10 * $n
        $q *= $Big[10]
        $r = $nr

        while ($ndigits -lt $Digits) {
            if ($Big[4] * $q + $r - $t -lt $n * $t) {
                $line += "$n"
                $ndigits++

                if ($line.Length -ge 80) {
                    $output += "`n$line"
                    $line = ""
                }

                $nr = $Big[10] * ( $r - $n * $t )
                $n = ( ( $Big[10] * ( 3 * $q + $r ) ) / $t ) - 10 * $n
                $q *= $Big[10]
                $r = $nr
            } else {
                $nr = ( $Big[2] * $q + $r ) * $l
                $nn = ( $q * ( $Big[7] * $k + $Big[2] ) + $r * $l ) / ( $t * $l )
                $q *= $k
                $t *= $l
                $l += $Big[2]
                $k += $Big[1]
                $n = $nn
                $r = $nr
            }
        }

        $output += "`n$line" # flush remaining line

        Write-Host "🧮 π to $Digits digits:" -ForegroundColor Cyan
        Write-Typewriter $output -speed 10

        return Ok -Value $output -Message "Calculated π to $Digits digits"
    }
    catch {
        return Err -Message "Failed to calculate π: $_"
    }
}
