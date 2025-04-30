# all/my/homies/homies.ps1
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'

function homies() {
    # Check if we have arguments
    if ($Arguments.Count -eq 0) {
        Show-CommandHelp -BasePath $BasePath -CurrentScript "homies.ps1" -CurrentNamespace "all my homies"
        exit 0
    }

    # Get the next command in the chain
    $nextCommand = $Arguments[0]
    $remainingArgs = $Arguments[1..$Arguments.Count]

    # Use our command discovery utility to find and execute the command
    $success = Invoke-Command -BasePath $BasePath -Command $nextCommand -Arguments $remainingArgs -CurrentNamespace "all my homies"

    if (-not $success) {
        exit 1
    }
}