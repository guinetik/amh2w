# core/dispatch.ps1
# Enhanced command dispatching system

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
        
        Log-Debug "Dispatching in namespace: $Namespace"
        Log-Debug "Module root: $moduleRoot"
        Log-Debug "Arguments: $($Arguments -join ', ')"

        # If no subcommand or help requested, show help for this namespace
        if ((-not $Arguments -or $Arguments.Count -eq 0) -or 
            ($Arguments.Count -gt 0 -and $Arguments[0] -eq "help")) {
            
            # Extract namespace path components
            $namespaceParts = $Namespace -split ' '
            $currentPath = $moduleRoot
            
            # Build the actual path to the namespace
            foreach ($part in $namespaceParts) {
                if ($part -eq $namespaceParts[0]) {
                    # For the root namespace, just use the name
                    $currentPath = Join-Path -Path $currentPath -ChildPath $part
                } else {
                    # For sub-namespaces, navigate into the folder
                    $currentPath = Join-Path -Path $currentPath -ChildPath $part
                }
            }
            
            # Generate the script filename for the current namespace
            $lastPart = $namespaceParts[-1]
            $namespaceScript = "$lastPart.ps1"
            
            Log-Debug "Showing help for namespace: $Namespace at path $currentPath"
            
            Show-CommandHelp `
                -BasePath        $currentPath `
                -CurrentScript   $namespaceScript `
                -CurrentNamespace $Namespace
                
            return Ok -Value $true -Message "Help displayed for namespace: $Namespace"
        }

        # Otherwise, peel off the next command and dispatch
        $nextCommand = $Arguments[0]
        $remainingArgs = if ($Arguments.Count -gt 1) {
            $Arguments[1..($Arguments.Count - 1)]
        }
        else {
            @()
        }

        # Build the actual path to the namespace
        $namespaceParts = $Namespace -split ' '
        $currentPath = $moduleRoot
        
        foreach ($part in $namespaceParts) {
            $currentPath = Join-Path -Path $currentPath -ChildPath $part
        }
        
        Log-Debug "Invoking command: $nextCommand in namespace: $Namespace at path $currentPath"
        
        $result = Invoke-Command `
            -BasePath         $currentPath `
            -Command          $nextCommand `
            -Arguments        $remainingArgs `
            -CurrentNamespace $Namespace
            
        # Return the result directly
        return $result
    }
    catch {
        Log-Error "Error in namespace dispatch: $_" 
        Log-Debug "Stack trace: $($_.ScriptStackTrace)"
        return Err -Message "Error in namespace dispatch: $_"
    }
}

function Resolve-CommandPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandChain
    )
    
    try {
        # Compute module root
        $moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
        
        # Split command chain into parts (e.g. "all my homies hate windows" -> ["all", "my", "homies", "hate", "windows"])
        $commandParts = $CommandChain -split ' '
        
        if ($commandParts.Count -eq 0) {
            return Err -Message "Empty command chain"
        }
        
        $currentPath = $moduleRoot
        $currentNamespace = ""
        
        # Traverse the command parts to find the deepest valid namespace
        for ($i = 0; $i -lt $commandParts.Count; $i++) {
            $part = $commandParts[$i]
            $testPath = Join-Path -Path $currentPath -ChildPath $part
            
            # Check if this is a valid namespace
            if (Test-Path -Path $testPath -PathType Container) {
                # Check for the namespace script file
                $scriptPath = Join-Path -Path $testPath -ChildPath "$part.ps1"
                if (Test-Path -Path $scriptPath -PathType Leaf) {
                    # Valid namespace, continue deeper
                    $currentPath = $testPath
                    $currentNamespace = if ($currentNamespace -eq "") { $part } else { "$currentNamespace $part" }
                    continue
                }
            }
            
            # If we get here, we've reached the end of the namespace chain
            break
        }
        
        return Ok -Value @{
            Namespace = $currentNamespace
            Path = $currentPath
            RemainingParts = $commandParts[$i..($commandParts.Count - 1)]
        }
    }
    catch {
        return Err -Message "Error resolving command path: $_"
    }
}
