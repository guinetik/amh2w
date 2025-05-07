<#
.SYNOPSIS
AMH2W - All My Homies Handle Windows - PowerShell utility library module.

.DESCRIPTION
AMH2W is a PowerShell utility library that provides a natural language-like command structure
for Windows system management, developer tools, and utility functions. This module implements
a hierarchical command system where commands are structured as sentences (e.g., "all my homies hate windows").

The module loads core components first, then loads all command chain scripts, and exports the main entry
point functions (all, uptime, and 🤓).

.NOTES
File: AMH2W.psm1
Project: All My Homies Handle Windows

Command Structure:
- all: Root namespace
- my: User-focused commands (uptime, shell, browser, etc.)
- homies: Extended utility layer (install, crypto, etc.)
- hate: Adapter for simplified interaction with complex systems
- windows: Windows-specific commands

.EXAMPLE
Import-Module AMH2W
all my uptime

.EXAMPLE
Import-Module AMH2W
all my homies hate windows version

.EXAMPLE
Import-Module AMH2W
🤓 amhhw version # Using the abbreviation system
#>


# Set the module root in an environment variable
$script:ModuleRoot = $PSScriptRoot

# Load the core/ files first
Write-Verbose "Loading core components..."
Get-ChildItem -Path (Join-Path $script:ModuleRoot 'core') -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
    Write-Verbose "Loaded core component: $($_.Name)"
}

# Load the command chain files
Write-Verbose "Loading command chain..."
Get-ChildItem -Path (Join-Path $script:ModuleRoot 'all') -Filter '*.ps1' -Recurse | ForEach-Object {
    . $_.FullName
    Write-Verbose "Loaded command: $($_.Name)"
}

# Export the 'all' function and any other standalone functions
Export-ModuleMember -Function all
Export-ModuleMember -Function uptime

<#
.SYNOPSIS
Abbreviation handler function for AMH2W commands.

.DESCRIPTION
Provides a shorthand system for AMH2W commands, allowing users to type abbreviated versions
of common command chains. For example, 'amhhw' expands to 'all my homies hate windows'.

The function maintains a mapping of abbreviations to full command chains and expands the
abbreviation before passing it to the main 'all' function for execution.

.PARAMETER Command
The command or abbreviation to execute.

.PARAMETER Arguments
Additional arguments to pass to the expanded command.

.EXAMPLE
🤓 amf
# Expands to 'all my files' and opens the file explorer

.EXAMPLE
🤓 amhhj view data.json
# Expands to 'all my homies hate json view data.json'

.NOTES
The abbreviation system follows a logical pattern:
- Single letters represent the first word (a = all)
- Additional letters add more words from the chain (am = all my)
- Abbreviations generally use the first letter of each word in the chain
#>
function 🤓 {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Command,
        
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    # Define abbreviation mappings
    $abbreviations = @{
        # Core command abbreviations
        "a"   = "all"
        "am"  = "all my"
        "amu" = "all my uptime"
        "amc" = "all my clock"
        "ams" = "all my shell"
        "amf" = "all my files"
        "amb" = "all my browser"
        
        # Homies abbreviations
        "amh"   = "all my homies"
        "amhi"  = "all my homies install"
        "amhic" = "all my homies install choco"
        "amhij" = "all my homies install jabba"
        
        # Hate abbreviations
        "amhh"   = "all my homies hate"
        "amhhf"  = "all my homies hate fetch"
        "amhhj"  = "all my homies hate json"
        "amhhw"  = "all my homies hate windows"
        "amhhwd" = "all my homies hate windows debloater"
    }
    
    # Check if command is an abbreviation
    if ($abbreviations.ContainsKey($Command)) {
        $expandedCommand = $abbreviations[$Command]
        Write-Verbose "Expanding abbreviation '$Command' to '$expandedCommand'"
        
        # Simply call the 'all' function with the expanded arguments
        $expandedParts = $expandedCommand -split ' '
        
        # Remove the first "all" since we'll call the all function directly
        if ($expandedParts[0] -eq "all") {
            $expandedParts = $expandedParts[1..($expandedParts.Length-1)]
        }
        
        # Call the all function with the expanded parts
        all @expandedParts @Arguments
    }
    else {
        # If not an abbreviation, pass through to 'all'
        all $Command @Arguments
    }
}

# Export the abbreviated function
Export-ModuleMember -Function 🤓
