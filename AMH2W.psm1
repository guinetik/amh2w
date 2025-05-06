# AMH2W.psm1 — Module Entry Point
# All My Homies Handle Windows - PowerShell utility library

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

# Abbreviation function for command shortcuts
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
