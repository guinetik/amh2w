function fizbuss {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [int]$UpTo = 100
    )

    try {
        if ($UpTo -lt 1) {
            return Err -Message "Please enter a number greater than zero."
        }

        1..$UpTo | ForEach-Object {
            if ($_ % 15 -eq 0) {
                Write-Host "fizbuss" -ForegroundColor Cyan
            }
            elseif ($_ % 3 -eq 0) {
                Write-Host "fiz" -ForegroundColor Green
            }
            elseif ($_ % 5 -eq 0) {
                Write-Host "buss" -ForegroundColor Yellow
            }
            else {
                Write-Host $_
            }
        }

        return Ok -Message "Ran fizbuss from 1 to $UpTo"
    }
    catch {
        return Err -Message "fizbuss error: $_"
    }
}
