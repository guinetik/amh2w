# File: core\dispatch.ps1

function Invoke-Namespace {
    [CmdletBinding()]
    param(
        # e.g. "all" or "all my" or "all my homies hate windows"
        [Parameter(Mandatory = $true)]
        [string]$Namespace,

        # Everything after that namespace
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    try {
        $ErrorActionPreference = 'Stop'

        # Compute module root (parent of this core folder)
        $dispatchScript = $MyInvocation.MyCommand.Definition
        $moduleRoot = Split-Path -Parent (Split-Path -Parent $dispatchScript)

        # If no subcommand, show help for this namespace
        if (-not $Arguments -or $Arguments.Count -eq 0) {
            Show-CommandHelp `
                -BasePath        $moduleRoot `
                -CurrentScript   ($MyInvocation.MyCommand.Name + '.ps1') `
                -CurrentNamespace $Namespace
            return
        }

        # Otherwise, peel off the next command and dispatch
        $nextCommand = $Arguments[0]
        $remainingArgs = if ($Arguments.Count -gt 1) {
            $Arguments[1..($Arguments.Count - 1)]
        }
        else {
            @()
        }

        $success = Invoke-Command `
            -BasePath         $moduleRoot `
            -Command          $nextCommand `
            -Arguments        $remainingArgs `
            -CurrentNamespace $Namespace

        if (-not $success) { exit 1 }
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
        exit 1
    }
}
