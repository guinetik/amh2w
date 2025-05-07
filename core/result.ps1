<#
.SYNOPSIS
Implements a Rust-inspired Ok/Err result pattern for error handling without exceptions.

.DESCRIPTION
This module provides a structured way to handle errors in AMH2W by returning result objects
instead of throwing exceptions. Functions return either an Ok object containing a value or 
an Err object containing an error message.

This enables pipeline-friendly error handling and command chaining.

.NOTES
The result pattern is inspired by Rust's Result type, which makes error handling explicit
and prevents exceptions from bubbling up and causing unexpected behavior.

File: core/result.ps1
#>


<#
.SYNOPSIS
Creates a success result object.

.DESCRIPTION
Returns a hashtable representing a successful operation, optionally containing a value and message.

.PARAMETER Value
The value returned by the successful operation. Can be any type.

.PARAMETER Message
An optional message describing the successful result.

.EXAMPLE
return Ok -Value $data

.EXAMPLE
return Ok -Value $user -Message "User created successfully"

.NOTES
Use this function to return success results from commands that support the AMH2W result pattern.
#>
function Ok {
    param($Value, $Message)
    return @{ ok = $true; value = $Value; message = $Message }
}

<#
.SYNOPSIS
Creates an error result object.

.DESCRIPTION
Returns a hashtable representing a failed operation, containing an error message and optional stack trace.

.PARAMETER Message
The error message describing what went wrong.

.PARAMETER Stack
An optional stack trace or additional error information.

.EXAMPLE
return Err "Connection failed"

.EXAMPLE
return Err -Message "File not found" -Stack $_.Exception.ToString()

.NOTES
Use this function to return error results from commands that support the AMH2W result pattern.
#>
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