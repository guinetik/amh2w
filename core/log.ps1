# core/log.ps1
# Enhanced logging system for AMH2W

# Global logging configuration
$global:AMH2W_LogConfig = @{
    Enabled = $true
    Verbose = $false
    LogToFile = $false
    LogFilePath = "$HOME\.amh2w\logs\amh2w.log"
    Colors = @{
        Info = 'Gray'
        Success = 'Green'
        Error = 'Red'
        Warning = 'Yellow'
        Debug = 'Cyan'
        Trace = 'DarkGray'
    }
    Prefixes = @{
        Info = "ℹ️ "
        Success = "✅ "
        Error = "❌ "
        Warning = "⚠️ "
        Debug = "🐞 "
        Trace = "🔍 "
    }
}

# Ensures log directory exists if file logging is enabled
function Initialize-Logging {
    if ($global:AMH2W_LogConfig.LogToFile) {
        $logDir = Split-Path -Parent $global:AMH2W_LogConfig.LogFilePath
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
    }
}

# Main logging function
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Info', 'Success', 'Error', 'Warning', 'Debug', 'Trace')]
        [string]$Level,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context = $null,
        
        [Parameter(Mandatory=$false)]
        [switch]$NoConsole
    )
    
    # Skip if logging is disabled
    if (-not $global:AMH2W_LogConfig.Enabled) {
        return
    }
    
    # Check the verbose setting from global context if no context provided
    $verboseEnabled = $global:AMH2W_LogConfig.Verbose
    if ($Context -and $Context.ContainsKey('Verbose')) {
        $verboseEnabled = $Context.Verbose
    }
    elseif (Test-Path 'variable:global:AMH2W_PipelineContext') {
        $verboseEnabled = $verboseEnabled -or $global:AMH2W_PipelineContext.Verbose
    }
    
    # Skip debug/trace messages unless verbose mode is enabled
    if (($Level -eq 'Debug' -or $Level -eq 'Trace') -and -not $verboseEnabled) {
        return
    }
    
    # Get settings from context or global config
    $colors = $global:AMH2W_LogConfig.Colors
    $prefixes = $global:AMH2W_LogConfig.Prefixes
    
    if ($Context -and $Context.LogConfig) {
        if ($Context.LogConfig.Colors) {
            $colors = $Context.LogConfig.Colors
        }
        if ($Context.LogConfig.Prefixes) {
            $prefixes = $Context.LogConfig.Prefixes
        }
    }
    
    $color = $colors[$Level]
    $prefix = $prefixes[$Level]
    
    # Get current namespace/command context if available
    $currentContext = ""
    if (Test-Path 'variable:global:AMH2W_PipelineContext') {
        if ($global:AMH2W_PipelineContext.CurrentNamespace) {
            $currentContext = "[$($global:AMH2W_PipelineContext.CurrentNamespace)]"
            if ($global:AMH2W_PipelineContext.CurrentCommand) {
                $currentContext += "[$($global:AMH2W_PipelineContext.CurrentCommand)]"
            }
            $currentContext += " "
        }
    }
    
    # Format timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Write to console unless NoConsole is specified
    if (-not $NoConsole) {
        Write-Host -ForegroundColor $color "$prefix [$timestamp] $currentContext$Message"
    }
    
    # Write to log file if enabled
    if ($global:AMH2W_LogConfig.LogToFile) {
        $logMessage = "[$timestamp] [$Level] $currentContext$Message"
        Add-Content -Path $global:AMH2W_LogConfig.LogFilePath -Value $logMessage
    }
}

# Shorthand logging functions
function Log-Info {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context=$null
    )
    
    Write-Log -Level 'Info' -Message $Message -Context $Context
}

function Log-Success {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context=$null
    )
    
    Write-Log -Level 'Success' -Message $Message -Context $Context
}

function Log-Error {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context=$null
    )
    
    Write-Log -Level 'Error' -Message $Message -Context $Context
}

function Log-Warning {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context=$null
    )
    
    Write-Log -Level 'Warning' -Message $Message -Context $Context
}

function Log-Debug {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context=$null
    )
    
    Write-Log -Level 'Debug' -Message $Message -Context $Context
}

function Log-Trace {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context=$null
    )
    
    Write-Log -Level 'Trace' -Message $Message -Context $Context
}

# Enable or disable verbose logging
function Set-LogVerbosity {
    param([bool]$Verbose)
    $global:AMH2W_LogConfig.Verbose = $Verbose
    
    # Also update pipeline context if it exists
    if (Test-Path 'variable:global:AMH2W_PipelineContext') {
        $global:AMH2W_PipelineContext.Verbose = $Verbose
    }
}

# Enable or disable file logging
function Set-LogToFile {
    param(
        [bool]$Enabled,
        [string]$FilePath = $null
    )
    
    $global:AMH2W_LogConfig.LogToFile = $Enabled
    
    if ($FilePath) {
        $global:AMH2W_LogConfig.LogFilePath = $FilePath
    }
    
    if ($Enabled) {
        Initialize-Logging
    }
}

# Initialize logging on module load
Initialize-Logging

# Export functions
Export-ModuleMember -Function Write-Log, Log-Info, Log-Success, Log-Error, Log-Warning, Log-Debug, Log-Trace, Set-LogVerbosity, Set-LogToFile
