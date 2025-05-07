<#
.SYNOPSIS
Enhanced logging system for the AMH2W PowerShell utility library.

.DESCRIPTION
Provides a comprehensive logging framework with multiple severity levels, console and file output options, 
customizable colors and prefixes, and context-aware logging. This module forms the foundation of the 
AMH2W diagnostic capabilities.

.NOTES
The logging system supports the following severity levels:
- Info: General informational messages
- Success: Operation completed successfully
- Error: Operation failed
- Warning: Potential issues that didn't prevent operation
- Debug: Detailed information for troubleshooting (only shown in verbose mode)
- Trace: Low-level execution tracing (only shown in verbose mode)

Global configuration is stored in $global:AMH2W_LogConfig.

File: core/log.ps1
#>


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

<#
.SYNOPSIS
Initializes the logging system.

.DESCRIPTION
Creates the log directory if file logging is enabled. Called automatically when 
the module is loaded.

.NOTES
This function is called automatically when the module is loaded and doesn't need
to be called directly unless the log file path has changed.
#>
function Initialize-Logging {
    if ($global:AMH2W_LogConfig.LogToFile) {
        $logDir = Split-Path -Parent $global:AMH2W_LogConfig.LogFilePath
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
    }
}

<#
.SYNOPSIS
Writes a log message with the specified severity level.

.DESCRIPTION
Core logging function that handles formatting, console output, and file logging.
Used by the severity-specific logging functions like Log-Info, Log-Error, etc.

.PARAMETER Level
The severity level of the log message. Valid values are: Info, Success, Error, Warning, Debug, Trace.

.PARAMETER Message
The message to log.

.PARAMETER Context
Optional hashtable containing context information or overrides for logging configuration.

.PARAMETER NoConsole
If specified, the log message will not be displayed in the console (but will still be written to the log file if enabled).

.EXAMPLE
Write-Log -Level 'Info' -Message "Operation started"

.EXAMPLE
Write-Log -Level 'Error' -Message "Failed to connect" -Context @{ LogConfig = @{ Colors = @{ Error = 'DarkRed' } } }
#>
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
            if ($global:AMH2W_PipelineContext.CurrentCommand) {
                $currentContext += "[$($global:AMH2W_PipelineContext.CurrentCommand)]"
            } else {
                $currentContext = "[$($global:AMH2W_PipelineContext.CurrentNamespace)]"
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

<#
.SYNOPSIS
Logs an informational message.

.DESCRIPTION
Logs a message with the 'Info' severity level.

.PARAMETER Message
The message to log.

.PARAMETER Context
Optional hashtable containing context information or overrides for logging configuration.

.EXAMPLE
Log-Info "Starting application initialization"

.EXAMPLE
Log-Info "Processing file $filename" -Context @{ Verbose = $true }
#>
function Log-Info {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context=$null
    )
    
    Write-Log -Level 'Info' -Message $Message -Context $Context
}

<#
.SYNOPSIS
Logs a success message.

.DESCRIPTION
Logs a message with the 'Success' severity level, indicating an operation completed successfully.

.PARAMETER Message
The message to log.

.PARAMETER Context
Optional hashtable containing context information or overrides for logging configuration.

.EXAMPLE
Log-Success "Configuration saved successfully"
#>
function Log-Success {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context=$null
    )
    
    Write-Log -Level 'Success' -Message $Message -Context $Context
}

<#
.SYNOPSIS
Logs an error message.

.DESCRIPTION
Logs a message with the 'Error' severity level, indicating an operation failed.

.PARAMETER Message
The message to log.

.PARAMETER Context
Optional hashtable containing context information or overrides for logging configuration.

.EXAMPLE
Log-Error "Failed to connect to server: $($_.Exception.Message)"
#>
function Log-Error {
    param(
        [Parameter(Mandatory=$true, HelpMessage="The message to log.")]
        [string]$Message,
        
        [Parameter(Mandatory=$false, HelpMessage="Optional hashtable containing context information or overrides for logging configuration.")]
        [hashtable]$Context=$null
    )
    
    Write-Log -Level 'Error' -Message $Message -Context $Context
}

<#
.SYNOPSIS
Logs a warning message.

.DESCRIPTION
Logs a message with the 'Warning' severity level, indicating a potential issue that didn't prevent the operation from completing.

.PARAMETER Message
The message to log.

.PARAMETER Context
Optional hashtable containing context information or overrides for logging configuration.

.EXAMPLE
Log-Warning "Connection timeout exceeded, retrying..."
#>
function Log-Warning {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context=$null
    )
    
    Write-Log -Level 'Warning' -Message $Message -Context $Context
}

<#
.SYNOPSIS
Logs a debug message.

.DESCRIPTION
Logs a message with the 'Debug' severity level. These messages are only displayed when verbose logging is enabled.

.PARAMETER Message
The message to log.

.PARAMETER Context
Optional hashtable containing context information or overrides for logging configuration.

.EXAMPLE
Log-Debug "Variable state: $($variable | ConvertTo-Json -Depth 3)"
#>
function Log-Debug {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context=$null
    )
    
    Write-Log -Level 'Debug' -Message $Message -Context $Context
}

<#
.SYNOPSIS
Logs a trace message.

.DESCRIPTION
Logs a message with the 'Trace' severity level for detailed execution flow tracking. These messages are only displayed when verbose logging is enabled.

.PARAMETER Message
The message to log.

.PARAMETER Context
Optional hashtable containing context information or overrides for logging configuration.

.EXAMPLE
Log-Trace "Entering function Process-Data"
#>
function Log-Trace {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context=$null
    )
    
    Write-Log -Level 'Trace' -Message $Message -Context $Context
}

<#
.SYNOPSIS
Enables or disables verbose logging.

.DESCRIPTION
Controls whether Debug and Trace level messages are displayed.

.PARAMETER Verbose
Boolean value indicating whether verbose logging should be enabled.

.EXAMPLE
Set-LogVerbosity $true  # Enable verbose logging
Set-LogVerbosity $false # Disable verbose logging
#>
function Set-LogVerbosity {
    param([bool]$Verbose)
    $global:AMH2W_LogConfig.Verbose = $Verbose
    
    # Also update pipeline context if it exists
    if (Test-Path 'variable:global:AMH2W_PipelineContext') {
        $global:AMH2W_PipelineContext.Verbose = $Verbose
    }
}

<#
.SYNOPSIS
Enables or disables logging to a file.

.DESCRIPTION
Controls whether log messages are written to a file in addition to being displayed in the console.

.PARAMETER Enabled
Boolean value indicating whether file logging should be enabled.

.PARAMETER FilePath
Optional path to the log file. If not specified, the default path from the global configuration is used.

.EXAMPLE
Set-LogToFile $true "$HOME\logs\myapp.log"  # Enable file logging to a custom path
Set-LogToFile $false                        # Disable file logging
#>
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

# Export the functions
Export-ModuleMember -Function Log-Info, Log-Success, Log-Error, Log-Warning, Log-Debug, Log-Trace, Set-LogVerbosity, Set-LogToFile