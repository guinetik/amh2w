# my.ps1
# Handles 'my' namespace commands

function my {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    # If no arguments, show help
    if (-not $Arguments -or $Arguments.Count -eq 0) {
        $currentPath = $PSScriptRoot
        Show-CommandHelp -CommandPath $currentPath -CommandChain "all my"
        return
    }
    
    # Process arguments
    $command = "my"
    $chain = "all $command"
    
    # Find the first non-namespace argument
    $argStart = 0
    $currentPath = $PSScriptRoot
    
    # Loop through arguments to build the command chain
    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        $arg = $Arguments[$i]
        $nextPath = Join-Path $currentPath $arg
        
        # Check if this is a namespace
        if (Test-Path $nextPath -PathType Container) {
            $chain += " $arg"
            $currentPath = $nextPath
            $argStart = $i + 1
        }
        else {
            # Check if it's a command
            $scriptPath = Join-Path $currentPath "$arg.ps1"
            if (Test-Path $scriptPath) {
                $chain += " $arg"
                $argStart = $i + 1
                
                # Call the command function
                $commandFunction = Get-Command $arg -ErrorAction SilentlyContinue
                if ($commandFunction) {
                    $remainingArgs = @()
                    if ($argStart -lt $Arguments.Count) {
                        $remainingArgs = $Arguments[$argStart..($Arguments.Count-1)]
                    }
                    
                    return & $commandFunction @remainingArgs
                }
                else {
                    Write-Host "Error: Command function '$arg' not found, but script exists." -ForegroundColor Red
                    return
                }
            }
            else {
                # Not a valid namespace or command
                break
            }
        }
    }
    
    # If we get here, show help for the current namespace
    Show-CommandHelp -CommandPath $currentPath -CommandChain $chain
}
