<#
.SYNOPSIS
    Namespace command dispatcher for AMH2W.
.DESCRIPTION
    Implements a namespace pattern (like a struct) for command dispatching. This script forwards the command chain and arguments to reach inner scripts or sub-namespaces, centralizing boilerplate logic for all top-level namespaces.
    
    This allows you to avoid repeating the same command chain parsing logic in every namespace script. Instead, each namespace script can simply call this function to handle forwarding and help display.
.EXAMPLE
    # Example usage in a namespace script (see all/my/homies/hate/windows/windows.ps1):
    function windows {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )
        return namespace "windows" "all my homies hate windows" @Arguments
    }
.NOTES
    Author: AMH2W Team
    File: core/namespace.ps1
#>

<#!
.SYNOPSIS
    Dispatches commands within a namespace, forwarding to inner scripts or showing help.
.DESCRIPTION
    Forwards the command chain and arguments to reach inner scripts or sub-namespaces. If no further arguments are provided, displays help for the current namespace. This function is intended to be called from top-level namespace scripts to centralize command dispatching logic.
.PARAMETER NamespaceName
    The name of the current namespace (e.g., 'windows').
.PARAMETER CommandChain
    The full command chain up to this point (e.g., 'all my homies hate windows').
.PARAMETER Arguments
    Remaining arguments to process, which may include sub-namespaces or commands.
.EXAMPLE
    # In a namespace script:
    namespace "windows" "all my homies hate windows" @Arguments
#>
function namespace {
    param(
        [Parameter(Mandatory = $true)]
        [string]$NamespaceName,

        [Parameter(Mandatory = $true)]
        [string]$CommandChain,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    # Show help if no arguments passed
    if (-not $Arguments -or $Arguments.Count -eq 0) {
        $currentPath = $PSScriptRoot
        Show-CommandHelp -CommandPath $currentPath -CommandChain $CommandChain
        return
    }

    $chain = $CommandChain
    $currentPath = $PSScriptRoot
    $argStart = 0

    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        $arg = $Arguments[$i]
        $nextPath = Join-Path $currentPath $arg

        if (Test-Path $nextPath -PathType Container) {
            $chain += " $arg"
            $currentPath = $nextPath
            $argStart = $i + 1
        }
        else {
            $scriptPath = Join-Path $currentPath "$arg.ps1"
            if (Test-Path $scriptPath) {
                $chain += " $arg"
                $argStart = $i + 1

                $commandFunction = Get-Command $arg -ErrorAction SilentlyContinue
                if ($commandFunction) {
                    $remainingArgs = @()
                    if ($argStart -lt $Arguments.Count) {
                        $remainingArgs = $Arguments[$argStart..($Arguments.Count - 1)]
                    }
                    try {
                        return & $commandFunction @remainingArgs
                    }
                    catch {
                        Write-Host "❌ Error: Command function '$arg' failed: $_" -ForegroundColor Red
                        return Err "Command function '$arg' failed: $_"
                    }
                }
                else {
                    Write-Host "❌ Error: Command function '$arg' not found, but script exists." -ForegroundColor Red
                    return Err "Command function '$arg' not found, but script exists."
                }
            }
            else {
                break
            }
        }
    }

    # If no command matched, show help for current path
    Show-CommandHelp -CommandPath $currentPath -CommandChain $chain
}
