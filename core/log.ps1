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
    
    # Skip debug/trace messages unless verbose mode is enabled
    if (($Level -eq 'Debug' -or $Level -eq 'Trace') -and -not $global:AMH2W_LogConfig.Verbose) {
        return
    }
    
    # Get settings from context or global config
    $colors = if ($Context -and $Context.logColors) { $Context.logColors } else { $global:AMH2W_LogConfig.Colors }
    $prefixes = if ($Context -and $Context.prefixes) { $Context.prefixes } else { $global:AMH2W_LogConfig.Prefixes }
    
    $color = $colors[$Level]
    $prefix = $prefixes[$Level]
    
    # Format timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Write to console unless NoConsole is specified
    if (-not $NoConsole) {
        Write-Host -ForegroundColor $color "$prefix [$timestamp] $Message"
    }
    
    # Write to log file if enabled
    if ($global:AMH2W_LogConfig.LogToFile) {
        $logMessage = "[$timestamp] [$Level] $Message"
        Add-Content -Path $global:AMH2W_LogConfig.LogFilePath -Value $logMessage
    }
}

# Shorthand logging functions
function Log-Info    { param([string]$Message, [hashtable]$Context=$null) Write-Log -Level 'Info'    -Message $Message -Context $Context }
function Log-Success { param([string]$Message, [hashtable]$Context=$null) Write-Log -Level 'Success' -Message $Message -Context $Context }
function Log-Error   { param([string]$Message, [hashtable]$Context=$null) Write-Log -Level 'Error'   -Message $Message -Context $Context }
function Log-Warning { param([string]$Message, [hashtable]$Context=$null) Write-Log -Level 'Warning' -Message $Message -Context $Context }
function Log-Debug   { param([string]$Message, [hashtable]$Context=$null) Write-Log -Level 'Debug'   -Message $Message -Context $Context }
function Log-Trace   { param([string]$Message, [hashtable]$Context=$null) Write-Log -Level 'Trace'   -Message $Message -Context $Context }

# Enable or disable verbose logging
function Set-LogVerbosity {
    param([bool]$Verbose)
    $global:AMH2W_LogConfig.Verbose = $Verbose
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
