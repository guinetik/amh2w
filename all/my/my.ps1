# File: all/my/my.ps1

function my {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    # Fail fast on any error
    $ErrorActionPreference = 'Stop'

    # Compute module root reliably (two levels up from this script)
    $moduleRoot = (Resolve-Path -Path (Join-Path $PSScriptRoot '..\..')).Path

    # If no args, do nothing (or uncomment the help call if you prefer)
    if (-not $Arguments -or $Arguments.Count -eq 0) {
        return
    }

    # If first arg is 'help', show namespace help
    if ($Arguments[0] -eq 'help') {
        Show-CommandHelp `
            -BasePath        $moduleRoot `
            -CurrentScript   'my.ps1' `
            -CurrentNamespace 'all my'
        return
    }

    # Otherwise dispatch to the next command
    Invoke-Namespace `
        -Namespace 'all my' `
        -Arguments  $Arguments
}

# (Exported automatically by AMH2W.psm1)
