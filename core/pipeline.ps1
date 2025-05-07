<#
.SYNOPSIS
Enhanced pipeline execution system for the AMH2W PowerShell utility library.

.DESCRIPTION
Provides a comprehensive pipeline execution system for AMH2W with error handling, logging,
statistics, and context tracking. This module enables robust command chaining and multi-step
execution flows while maintaining state and providing rich error handling.

The pipeline system supports:
- Global execution context with shared data and history
- Ok/Err result pattern for consistent error handling
- Automatic logging with configurable verbosity
- Command history and performance statistics
- Optional error handling with user prompting

.NOTES
File: core/pipeline.ps1
Author: AMH2W Team

This module is the backbone of AMH2W's execution model, allowing commands to be chained
together while maintaining context and providing consistent error handling patterns.
#>


# Global pipeline context
$global:AMH2W_PipelineContext = @{
    Prompt = $true                      # Prompt on optional errors
    Verbose = $false                    # Verbose output
    ContinueOnError = $false            # Continue on optional errors
    LogConfig = @{                      # Logging configuration
        Colors = $global:AMH2W_LogConfig.Colors
        Prefixes = $global:AMH2W_LogConfig.Prefixes
    }
    Data = @{}                          # Shared data between steps
    History = @()                       # Command execution history
    CurrentCommand = ""                 # Current command being executed
    CurrentNamespace = ""               # Current namespace
}

<#
.SYNOPSIS
    Enhanced pipeline execution system for AMH2W.
.DESCRIPTION
    Provides a set of functions and a global context for building, executing, and managing multi-step pipelines with error handling, logging, and statistics.
    
    This module is intended for use in AMH2W automation and scripting scenarios where robust, stepwise execution is required.
.EXAMPLE
    # Run a pipeline with three steps
    $steps = @(
        { Ok -Value 1 -Message 'Step 1' },
        { Ok -Value 2 -Message 'Step 2' },
        { Ok -Value 3 -Message 'Step 3' }
    )
    Invoke-Pipeline -Steps $steps
.NOTES
    Author: AMH2W Team
    File: core/pipeline.ps1
#>

<#
.SYNOPSIS
Initializes or updates the global pipeline context.

.DESCRIPTION
Sets up the global pipeline context with options for prompting, error handling, logging, and shared data.
The context provides a global state that is shared across commands in the pipeline.

.PARAMETER PromptOnOptionalError
Whether to prompt the user on optional errors (default: $true).

.PARAMETER ContinueOnError
Whether to continue on optional errors without prompting (default: $false).

.PARAMETER LogConfig
Hashtable for logging configuration (default: global log config).

.PARAMETER Data
Hashtable for shared data between steps (default: empty).

.OUTPUTS
Returns the global pipeline context hashtable.

.EXAMPLE
New-PipelineContext -PromptOnOptionalError $false -ContinueOnError $true

.NOTES
This function should be called before starting a pipeline execution flow to configure
how errors and logging should be handled.
#>
function New-PipelineContext {
    param(
        [Parameter(Mandatory=$false)]
        [bool]$PromptOnOptionalError = $true,
        
        [Parameter(Mandatory=$false)]
        [bool]$ContinueOnError = $false,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$LogConfig = $null,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Data = @{}
    )

    # Use global log colors if none provided
    if ($null -eq $LogConfig) {
        $LogConfig = @{
            Colors = $global:AMH2W_LogConfig.Colors
            Prefixes = $global:AMH2W_LogConfig.Prefixes
        }
    }

    # Update the global context
    $global:AMH2W_PipelineContext.Prompt = $PromptOnOptionalError
    $global:AMH2W_PipelineContext.ContinueOnError = $ContinueOnError
    $global:AMH2W_PipelineContext.LogConfig = $LogConfig
    $global:AMH2W_PipelineContext.Data = $Data
    
    # Return the global context (for backward compatibility)
    return $global:AMH2W_PipelineContext
}

<#
.SYNOPSIS
    Returns the current global pipeline context.
.DESCRIPTION
    Retrieves the hashtable representing the current pipeline context, including logging, data, and history.
.EXAMPLE
    $ctx = Get-PipelineContext
#>
function Get-PipelineContext {
    # Return the global pipeline context
    return $global:AMH2W_PipelineContext
}

<#
.SYNOPSIS
    Sets the verbosity of pipeline output.
.DESCRIPTION
    Enables or disables verbose output for pipeline execution.
.PARAMETER Verbose
    Boolean to enable or disable verbose output.
.EXAMPLE
    Set-PipelineVerbose -Verbose $true
#>
function Set-PipelineVerbose {
    param([bool]$Verbose)
    $global:AMH2W_PipelineContext.Verbose = $Verbose
}

<#
.SYNOPSIS
    Sets the current command and namespace in the pipeline context.
.DESCRIPTION
    Updates the pipeline context to reflect the command and namespace currently being executed.
.PARAMETER Command
    The name of the command being executed.
.PARAMETER Namespace
    The namespace of the command.
.EXAMPLE
    Set-CurrentCommand -Command 'Install' -Namespace 'Core'
#>
function Set-CurrentCommand {
    param(
        [string]$Command,
        [string]$Namespace
    )
    
    $global:AMH2W_PipelineContext.CurrentCommand = $Command
    $global:AMH2W_PipelineContext.CurrentNamespace = $Namespace
    
    Log-Debug "Set current command: $Command in namespace: $Namespace"
}

<#
.SYNOPSIS
Executes a command with error handling and result formatting.

.DESCRIPTION
Runs a script block as a command, handling any exceptions and ensuring that the result
is properly formatted as an Ok or Err object according to the AMH2W result pattern.
This function also records execution history and performance metrics.

.PARAMETER CommandBlock
The script block to execute.

.PARAMETER CommandName
Name of the command (for logging and history). Default: "Command".

.PARAMETER Arguments
Arguments to pass to the script block.

.OUTPUTS
An Ok or Err result object from the command execution, or an Err object if an exception occurred.

.EXAMPLE
Invoke-CommandWithErrorHandling -CommandBlock { param($x) $x + 1 } -CommandName "Add" -Arguments @(5)

.NOTES
This function is used internally by the command system to execute commands in a safe
and consistent manner, with proper error handling and result formatting.
#>
function Invoke-CommandWithErrorHandling {
    param(
        [Parameter(Mandatory=$true)]
        [ScriptBlock]$CommandBlock,
        
        [Parameter(Mandatory=$false)]
        [string]$CommandName = "Command",
        
        [Parameter(Mandatory=$false)]
        [object[]]$Arguments = @()
    )
    
    $startTime = Get-Date
    
    try {
        Log-Debug "Executing $CommandName"
        $result = & $CommandBlock @Arguments
        
        # Ensure result is in the correct format (Ok/Err)
        if ($null -eq $result) {
            $result = Ok -Value $null -Message "$CommandName completed successfully"
        }
        elseif (-not ($result -is [Hashtable]) -or (-not $result.ContainsKey('ok'))) {
            # Wrap non-Ok/Err results in an Ok
            $result = Ok -Value $result -Message "$CommandName completed successfully"
        }
        
        # Record execution in history
        $executionRecord = @{
            Command = $CommandName
            StartTime = $startTime
            EndTime = Get-Date
            Duration = ((Get-Date) - $startTime).TotalMilliseconds
            Success = $result.ok
            Result = $result
        }
        $global:AMH2W_PipelineContext.History += $executionRecord
        
        return $result
    }
    catch {
        # Handle unexpected exceptions
        $errorMessage = "Error in $CommandName : $_"
        Log-Error $errorMessage
        
        # Create error result
        $errorResult = Err -Message $errorMessage
        
        # Record in history
        $executionRecord = @{
            Command = $CommandName
            StartTime = $startTime
            EndTime = Get-Date
            Duration = ((Get-Date) - $startTime).TotalMilliseconds
            Success = $false
            Result = $errorResult
        }
        $global:AMH2W_PipelineContext.History += $executionRecord
        
        return $errorResult
    }
}

<#
.SYNOPSIS
Executes a sequence of pipeline steps with error handling and logging.

.DESCRIPTION
Runs an array of script blocks as pipeline steps, handling errors according to the pipeline context
settings. Supports optional errors with user prompting, verbose logging, and performance tracking.

The pipeline execution follows these steps:
1. For each step in the pipeline:
   a. Execute the step and capture its result
   b. If the result is a failure (Err):
      - If it's optional, prompt the user or continue based on context settings
      - If it's not optional, abort the pipeline and return the error
   c. If the result is successful (Ok), continue to the next step
2. After all steps complete successfully, return the final result

.PARAMETER Steps
Array of script blocks representing pipeline steps.

.PARAMETER Context
Pipeline context to use (default: global context).

.PARAMETER PipelineName
Name for the pipeline (for logging). Default: "Pipeline".

.OUTPUTS
Returns the result of the final step if successful, or an Err object if any step failed.

.EXAMPLE
$steps = @(
    { Ok -Value "Step 1 data" },
    { param($prev) Ok -Value "Step 2 processed $($prev.value)" }
)
Invoke-Pipeline -Steps $steps -PipelineName "MyProcess"

.NOTES
This function is the heart of AMH2W's pipeline execution system, allowing a series of steps
to be executed with consistent error handling, logging, and state management.
#>
function Invoke-Pipeline {
    param(
        [Parameter(Mandatory=$true)]
        [ScriptBlock[]]$Steps,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Context = $null,
        
        [Parameter(Mandatory=$false)]
        [string]$PipelineName = "Pipeline"
    )

    # Use global context if none provided
    if ($null -eq $Context) {
        $Context = $global:AMH2W_PipelineContext
    }

    $stepNumber = 0
    $totalSteps = $Steps.Count
    $pipelineResult = $null
    
    Log-Info "Starting $PipelineName execution with $totalSteps steps"
    
    foreach ($step in $Steps) {
        $stepNumber++
        $stepStartTime = Get-Date
        
        # If verbose, show more details about the step
        if ($Context.Verbose) {
            $stepText = $step.ToString()
            Log-Debug "Step $stepNumber / $totalSteps - Code: $stepText"
        } else {
            Log-Info "Step $stepNumber / $totalSteps - Starting..." -Context $Context
        }
        
        # Execute the step
        try {
            $result = & $step
            
            # Record execution in history
            $executionRecord = @{
                StepNumber = $stepNumber
                StartTime = $stepStartTime
                EndTime = Get-Date
                Duration = ((Get-Date) - $stepStartTime).TotalMilliseconds
                Success = $result.ok
                Result = $result
            }
            $Context.History += $executionRecord
            
            # Handle results
            if (-not $result.ok) {
                # Handle failures based on whether they're optional
                if ($result.optional) {
                    Log-Warning "Optional step failed: $($result.error)" -Context $Context
                    
                    # Show stack trace in verbose mode
                    if ($Context.Verbose -and $result.stack) {
                        Log-Debug "Stack trace:"
                        foreach ($frame in $result.stack) {
                            Log-Debug "  $frame"
                        }
                    }
                    
                    # Prompt to continue if configured
                    if ($Context.Prompt) {
                        $resp = Read-Host "❓ Continue anyway? (Y/N)"
                        if ($resp -ne "Y") {
                            Log-Error "Pipeline aborted by user input." -Context $Context
                            return $result  # Return the failure result
                        }
                    } elseif (-not $Context.ContinueOnError) {
                        Log-Error "Pipeline aborted due to error in optional step." -Context $Context
                        return $result  # Return the failure result
                    }
                    
                    # Continue execution
                    continue
                } else {
                    # Handle non-optional failures
                    Log-Error "Fatal error: $($result)" -Context $Context
                    
                    # Show stack trace
                    if ($result.stack) {
                        Log-Error "Stack trace:"
                        foreach ($frame in $result.stack) {
                            Log-Error "  $frame"
                        }
                    }
                    
                    return $result  # Return the failure result
                }
            }

            # Success path
            if ($result.message) {
                $successMsg = $result.message
            } else {
                $successMsg = "Step completed successfully"
            }
            
            Log-Success "$successMsg" -Context $Context
            
            # Store last result to pass to next step if needed
            $pipelineResult = $result
        }
        catch {
            # Handle unexpected exceptions
            $errorMessage = "Unhandled exception in step $stepNumber : $_"
            Log-Error $errorMessage -Context $Context
            
            # Create error result with stack trace
            $errorResult = Err -Message $errorMessage
            
            # Record in history
            $executionRecord = @{
                StepNumber = $stepNumber
                StartTime = $stepStartTime
                EndTime = Get-Date
                Duration = ((Get-Date) - $stepStartTime).TotalMilliseconds
                Success = $false
                Result = $errorResult
            }
            $Context.History += $executionRecord
            
            return $errorResult  # Return the failure result
        }
    }
    
    # If we get here, pipeline completed successfully
    Log-Success "$PipelineName completed successfully ($totalSteps steps)." -Context $Context
    
    # Return the last result or an OK if there wasn't one
    if ($null -eq $pipelineResult) {
        return Ok -Value $true -Message "$PipelineName completed successfully"
    } else {
        return $pipelineResult
    }
}

<#
.SYNOPSIS
    Returns statistics about the most recent pipeline execution.
.DESCRIPTION
    Provides summary statistics such as total steps, completed, failed, and average duration from the pipeline context history.
.PARAMETER Context
    Pipeline context to use (default: global context).
.EXAMPLE
    Get-PipelineStats
#>
function Get-PipelineStats {
    param(
        [Parameter(Mandatory=$false)]
        [hashtable]$Context = $null
    )
    
    if ($null -eq $Context) {
        $Context = $global:AMH2W_PipelineContext
    }
    
    if (-not $Context.History -or $Context.History.Count -eq 0) {
        return @{
            TotalSteps = 0
            Completed = 0
            Failed = 0
            TotalDuration = 0
            AverageDuration = 0
        }
    }
    
    $completed = ($Context.History | Where-Object { $_.Success -eq $true }).Count
    $failed = ($Context.History | Where-Object { $_.Success -eq $false }).Count
    $totalDuration = ($Context.History | Measure-Object -Property Duration -Sum).Sum
    $avgDuration = ($Context.History | Measure-Object -Property Duration -Average).Average
    
    return @{
        TotalSteps = $Context.History.Count
        Completed = $completed
        Failed = $failed
        TotalDuration = $totalDuration
        AverageDuration = $avgDuration
    }
}

# Initialize the global context
New-PipelineContext | Out-Null
