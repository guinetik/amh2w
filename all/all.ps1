# all/all.ps1
function all {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    # Fail fast on any error
    $ErrorActionPreference = 'Stop'
    $moduleRoot = $env:AMH2W_HOME
    Write-Host "moduleRoot: $moduleRoot"
    # If no args, do nothing (or uncomment the help call if you prefer)
    if (-not $Arguments -or $Arguments.Count -eq 0) {
        return
    }

    # If first arg is 'help', show namespace help
    if ($Arguments[0] -eq 'help') {
        Show-CommandHelp `
            -BasePath        $moduleRoot `
            -CurrentScript   'all.ps1' `
            -CurrentNamespace 'all'
        return
    }

    # Otherwise dispatch to the next command
    Invoke-Namespace -Namespace 'all' -Arguments  $Arguments
}

# (Exported automatically by AMH2W.psm1)
