# core/result.ps1
# Simple success/error result pattern for command chaining

function Ok {
    param($Value, $Message)
    return @{ ok = $true; value = $Value; message = $Message }
}

function Err {
    param($Message, $Stack)
    return @{ ok = $false; error = $Message; stack = $Stack }
}

<#
.SYNOPSIS
Returns a boolean value indicating if the value is truthy.

.DESCRIPTION
So my initial intuition on powershell led me to a mistake that caused issues with how the pipeline interprets command arguments.
Basically everything is a string, so I needed a way to check if a value is truthy.
The switch type doesn't really work for outer level commands so I needed a way to check if a value is truthy.

.PARAMETER Value
The value to check if it's truthy.  

.EXAMPLE
Truthy "true"
Truthy "1"
Truthy "yes"
Truthy "y"
Truthy "s"
Truthy "sim"
Truthy "on"

.NOTES
TODO: Fix the pipeline so I can get rid of this.
#>
function Truthy {
    param($Value)
    $truthy = @("true", "1", "yes", "y", "s", "sim", "on")
    return $truthy -contains $Value.ToString().ToLower()
}