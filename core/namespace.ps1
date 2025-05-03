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
                        return
                    }
                }
                else {
                    Write-Host "❌ Error: Command function '$arg' not found, but script exists." -ForegroundColor Red
                    return
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
