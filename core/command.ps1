<#
.SYNOPSIS
Core command handling for the AMH2W PowerShell utility library.

.DESCRIPTION
Provides the central mechanism for processing AMH2W's command chains, managing namespaces,
and executing commands. This module implements the grammatical command structure that makes
AMH2W's syntax possible (e.g., "all my homies hate windows version").

The command system works through nested namespaces, where each part of a command chain can
either be a namespace (containing more commands) or an executable command.

.NOTES
File: core/command.ps1

Command chain structure:
1. Each word in a command represents a namespace or command
2. Namespaces contain other namespaces or commands
3. The system traverses the chain until it finds a final command to execute
4. If the chain ends in a namespace, help information is displayed
#>


<#
.SYNOPSIS
RetrieveS available namespaces and commands in a given directory.

.DESCRIPTION
Scans a specified directory to identify both subdirectories (which are considered namespaces)
and PowerShell script files (which are considered commands). This function is used to build the
command hierarchy and generate help information.

.PARAMETER BasePath
The directory path to scan for namespaces and commands.

.OUTPUTS
A hashtable with two properties:
- Namespaces: An array of directory names representing available namespaces
- Commands: An array of script filenames (without extensions) representing available commands

.EXAMPLE
$available = Get-AvailableCommands -BasePath "D:\Developer\amh2w\all\my"
$available.Namespaces # Returns subdirectories of "my"
$available.Commands   # Returns .ps1 files in the "my" directory
#>
function Get-AvailableCommands {
    param(
        [string]$BasePath
    )
    
    $result = @{
        Namespaces = @()
        Commands = @()
    }
    
    # Get subdirectories (namespaces)
    $dirs = Get-ChildItem -Path $BasePath -Directory | Select-Object -ExpandProperty Name
    if ($dirs) {
        $result.Namespaces = $dirs
    }
    
    # Get script files (commands)
    $files = Get-ChildItem -Path $BasePath -Filter "*.ps1" | 
             Where-Object { $_.BaseName -ne (Split-Path $BasePath -Leaf) } |
             Select-Object -ExpandProperty BaseName
    
    if ($files) {
        $result.Commands = $files
    }
    
    return $result
}

<#
.SYNOPSIS
Displays help information for a command or namespace.

.DESCRIPTION
Generates and displays help information for a specified command path, showing available
namespaces and commands that can be used at that level of the command hierarchy.
This function is called when a user invokes an incomplete command chain or explicitly
requests help.

.PARAMETER CommandPath
The directory path corresponding to the current level in the command chain.

.PARAMETER CommandChain
The string representation of the current command chain (for display purposes).

.EXAMPLE
Show-CommandHelp -CommandPath "D:\Developer\amh2w\all\my" -CommandChain "all my"
# Shows available namespaces and commands under the "all my" namespace

.NOTES
The output is color-coded for better readability:
- Command chain: Cyan
- Namespace labels: Yellow
- Namespace names: Green
- Commands: White
- Examples: Gray
#>
function Show-CommandHelp {
    param(
        [string]$CommandPath,
        [string]$CommandChain = ""
    )
    
    $available = Get-AvailableCommands -BasePath $CommandPath
    
    Write-Host "AMH2W Command Chain: $CommandChain" -ForegroundColor Cyan
    Write-Host ""
    
    if ($available.Namespaces.Count -gt 0) {
        Write-Host "Available Namespaces:" -ForegroundColor Yellow
        foreach ($ns in $available.Namespaces) {
            Write-Host "  $ns" -ForegroundColor Green
        }
        Write-Host ""
    }
    
    if ($available.Commands.Count -gt 0) {
        Write-Host "Available Commands:" -ForegroundColor Yellow
        foreach ($cmd in $available.Commands) {
            Write-Host "  $cmd" -ForegroundColor White
        }
        Write-Host ""
    }
    
    if ($available.Namespaces.Count -eq 0 -and $available.Commands.Count -eq 0) {
        Write-Host "No commands available in this namespace." -ForegroundColor Red
    }
    
    Write-Host "Example: $CommandChain [command]" -ForegroundColor Gray
}

<#
.SYNOPSIS
Processes and executes AMH2W command chains.

.DESCRIPTION
The core command chain execution engine for AMH2W. Takes a space-separated command chain
and processes it by navigating through the namespace hierarchy until it finds a command
to execute or determines that help information should be shown.

The function walks through each part of the command chain, checking if it's a namespace
(directory) or command (script file). If a command is found, it executes it with the
provided arguments. If the chain ends in a namespace, it displays help information.

.PARAMETER CommandChain
The space-separated command chain to process (e.g., "all my homies hate windows version").

.PARAMETER Arguments
Any additional arguments to pass to the final command in the chain.

.OUTPUTS
Returns the result of the executed command (as an Ok or Err object), or an Ok/Err object
to indicate whether the command chain was valid.

.EXAMPLE
Invoke-CommandChain -CommandChain "all my uptime" -Arguments @("full")
# Executes the 'uptime' command with the 'full' argument

.EXAMPLE
Invoke-CommandChain -CommandChain "all my homies hate json" -Arguments @("view", "data.json")
# Executes the 'json' command with 'view' and 'data.json' arguments

.NOTES
This function is the heart of AMH2W's grammar-based command system. It enables the
hierarchical navigation and execution that makes the library's syntax possible.
#>
function Invoke-CommandChain {
    param(
        [string]$CommandChain,
        [string[]]$Arguments
    )
    
    # Split command chain
    $parts = $CommandChain -split ' '
    
    # Get the module root
    $currentPath = $PSScriptRoot
    $moduleRoot = Split-Path -Parent $currentPath
    $currentPath = Join-Path $moduleRoot "all"
    
    # Navigate through the chain
    $chain = ""
    foreach ($part in $parts) {
        $chain = if ($chain) { "$chain $part" } else { $part }
        
        # Check if this part exists as a directory
        $nextPath = Join-Path $currentPath $part
        if (Test-Path $nextPath -PathType Container) {
            $currentPath = $nextPath
            
            # Load the corresponding script for this namespace
            $scriptPath = Join-Path $currentPath "$part.ps1"
            if (Test-Path $scriptPath) {
                # Already loaded in module initialization
            }
        }
        else {
            # Check if it's a script
            $scriptPath = Join-Path $currentPath "$part.ps1"
            if (Test-Path $scriptPath) {
                # Call the function with the provided arguments
                $commandFunction = Get-Command $part -ErrorAction SilentlyContinue
                if ($commandFunction) {
                    return & $commandFunction @Arguments
                }
                else {
                    return Err "Command function '$part' not found, but script exists."
                }
            }
            else {
                # Command not found, show help
                Show-CommandHelp -CommandPath $currentPath -CommandChain $chain
                return Err "Command or namespace '$part' not found."
            }
        }
    }
    
    # If we reach here, we just navigated to a namespace, show help
    Show-CommandHelp -CommandPath $currentPath -CommandChain $chain
    return Ok $null
}
