<#
.SYNOPSIS
Implements the classic FizzBuzz programming exercise.

.DESCRIPTION
Generates a sequence of numbers from 1 to N, replacing numbers divisible by 3 with "fiz",
numbers divisible by 5 with "buss", and numbers divisible by both with "fizbuss".

This is a variation on the traditional FizzBuzz interview question, using slightly different names.

.PARAMETER UpTo
The upper limit of the sequence to generate. Default is 100.

.OUTPUTS
An Ok result object if successful, or an Err result object if the operation fails.

.EXAMPLE
all fizbuss
# Runs the algorithm from 1 to 100 with default values

.EXAMPLE
all fizbuss 20
# Runs the algorithm from 1 to 20

.NOTES
File: all/fizbuss.ps1
Command: all fizbuss

Outputs with color coding:
- "fiz" (divisible by 3) in green
- "buss" (divisible by 5) in yellow
- "fizbuss" (divisible by both) in cyan
- Regular numbers in default color
#>
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
