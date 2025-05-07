# core/pipeline.ps1
# Enhanced pipeline execution system for AMH2W

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

function Get-PipelineContext {
    # Return the global pipeline context
    return $global:AMH2W_PipelineContext
}

function Set-PipelineVerbose {
    param([bool]$Verbose)
    $global:AMH2W_PipelineContext.Verbose = $Verbose
}

function Set-CurrentCommand {
    param(
        [string]$Command,
        [string]$Namespace
    )
    
    $global:AMH2W_PipelineContext.CurrentCommand = $Command
    $global:AMH2W_PipelineContext.CurrentNamespace = $Namespace
    
    Log-Debug "Set current command: $Command in namespace: $Namespace"
}

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
