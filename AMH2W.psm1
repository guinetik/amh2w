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
