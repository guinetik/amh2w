<#
.SYNOPSIS
Main entry point function for the AMH2W command chain system.

.DESCRIPTION
The core function of AMH2W that processes command chains and routes them to the appropriate
commands or namespaces. This function is the primary entry point for all AMH2W commands
and serves as the root of the command hierarchy.

The function navigates through the command chain, identifying namespaces (directories) and
commands (script files) until it either executes a command or displays help information
for a namespace.

.PARAMETER Arguments
An array of strings representing the command chain and its arguments. The first arguments
are treated as potential namespaces or commands, and the remaining arguments are passed
to the final command if one is found.

.OUTPUTS
Returns an Ok or Err result object from the executed command, or an Ok result object with
a message if help information was displayed.

.EXAMPLE
all my uptime
# Executes the 'uptime' command in the 'my' namespace

.EXAMPLE
all my homies hate windows version
# Navigates through multiple namespaces to execute the 'version' command

.EXAMPLE
all
# With no arguments, displays help information for the root namespace

.NOTES
This function is the foundation of AMH2W's grammatical command structure, allowing commands
to be written in a sentence-like format that is both intuitive and expressive.
#>


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
        # Handle unexpected exceptions
        $errorMessage = "COMMAND CHAIN FAILED"
        $line = $_.InvocationInfo.ScriptLineNumber
        $stack = $_.Exception.StackTrace
        $file = $_.InvocationInfo.ScriptName
        Log-Error $errorMessage
        Log-Error "Error in $file - Line $line"
        Log-Error $_
        Log-Error $stack
        return Err "Error in command chain execution: $_"
    }
}
