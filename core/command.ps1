# core/command.ps1
# Utility functions for command discovery and execution

function Get-AvailableCommands {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BasePath,
        
        [Parameter(Mandatory=$false)]
        [string]$ExcludeFile = $null
    )
    
    $result = @{
        Namespaces = @()
        Commands = @()
    }
    
    # Get subfolders (namespaces)
    $subDirectories = Get-ChildItem -Path $BasePath -Directory | Select-Object -ExpandProperty Name
    if ($subDirectories.Count -gt 0) {
        $result.Namespaces = $subDirectories
    }
    
    # Get command files (excluding the specified file if any)
    $commandFiles = Get-ChildItem -Path $BasePath -Filter "*.ps1" 
    if ($ExcludeFile) {
        $commandFiles = $commandFiles | Where-Object { $_.Name -ne $ExcludeFile }
    }
    
    if ($commandFiles.Count -gt 0) {
        $result.Commands = $commandFiles | Select-Object -ExpandProperty BaseName
    }
    
    return $result
}

function Find-CommandPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BasePath,
        
        [Parameter(Mandatory=$true)]
        [string]$Command
    )
    
    # First, check if it's a subfolder with a command script
    $namespacePath = Join-Path -Path $BasePath -ChildPath "$Command\$Command.ps1"
    
    if (Test-Path $namespacePath) {
        return @{
            Type = "namespace"
            Path = $namespacePath
        }
    }
    
    # If not a namespace, check if it's a direct script file
    $scriptPath = Join-Path -Path $BasePath -ChildPath "$Command.ps1"
    
    if (Test-Path $scriptPath) {
        return @{
            Type = "command"
            Path = $scriptPath
        }
    }
    
    # Command not found
    return $null
}

function Show-CommandHelp {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BasePath,
        
        [Parameter(Mandatory=$false)]
        [string]$CurrentNamespace = "",
        
        [Parameter(Mandatory=$false)]
        [string]$CurrentScript = ""
    )
    
    $commands = Get-AvailableCommands -BasePath $BasePath -ExcludeFile $CurrentScript
    
    $namespacePrefix = if ($CurrentNamespace) { "$CurrentNamespace " } else { "" }
    
    Write-Host "Usage: $namespacePrefix[command]" -ForegroundColor Yellow
    
    # Show available namespaces
    if ($commands.Namespaces.Count -gt 0) {
        Write-Host "Available namespaces:" -ForegroundColor Cyan
        foreach ($namespace in $commands.Namespaces) {
            Write-Host "  $namespace" -ForegroundColor White
        }
    }
    
    # Show available commands
    if ($commands.Commands.Count -gt 0) {
        Write-Host "Available commands:" -ForegroundColor Cyan
        foreach ($command in $commands.Commands) {
            Write-Host "  $command" -ForegroundColor White
        }
    }
}

function Invoke-Command {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BasePath,
        
        [Parameter(Mandatory=$true)]
        [string]$Command,
        
        [Parameter(Mandatory=$false)]
        [string[]]$Arguments = @(),
        
        [Parameter(Mandatory=$false)]
        [string]$CurrentNamespace = ""
    )
    
    $commandInfo = Find-CommandPath -BasePath $BasePath -Command $Command
    
    if ($null -eq $commandInfo) {
        $namespacePrefix = if ($CurrentNamespace) { "$CurrentNamespace " } else { "" }
        Write-Host "Command not found: $namespacePrefix$Command" -ForegroundColor Red
        return $false
    }
    
    # Execute the command
    try {
        & $commandInfo.Path @Arguments
    } catch {
        Write-Host "Error executing command: $Command" -ForegroundColor Red
        Write-Host "Error details: $_" -ForegroundColor Red
        Write-Host "Arguments: $($Arguments -join ' ')" -ForegroundColor Red
        return $false
    }
    return $true
}