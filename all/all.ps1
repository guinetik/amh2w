# all.ps1
# Entry point for command chain

function all {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    # If no arguments, show help
    if (-not $Arguments -or $Arguments.Count -eq 0) {
        $moduleRoot = $PSScriptRoot
        WriteLine "Welcome to all"
        Show-CommandHelp -CommandPath $moduleRoot -CommandChain "all"
        return Ok "Help displayed for root namespace"
    }
    
    # Process arguments
    $command = "all"
    $chain = $command
    
    # Find the first non-namespace argument
    $argStart = 0
    $currentPath = $PSScriptRoot
    
    try {
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
                        
                        # Set current command and namespace in the pipeline context
                        Set-CurrentCommand -Command $arg -Namespace $chain
                        
                        # Execute the command with error handling
                        $commandBlock = {
                            param($cmdArgs)
                            & $commandFunction @cmdArgs
                        }
                        
                        $result = Invoke-CommandWithErrorHandling -CommandBlock $commandBlock -CommandName $chain -Arguments @(,$remainingArgs)
                        return $result
                    }
                    else {
                        Log-Error "Command function '$arg' not found, but script exists."
                        return Err "Command function '$arg' not found, but script exists."
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
        return Ok "Help displayed for namespace: $chain"
    }
    catch {
        Log-Error "Error in command chain execution: $_"
        return Err "Error in command chain execution: $_"
    }
}
