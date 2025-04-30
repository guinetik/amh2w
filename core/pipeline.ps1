# core/pipeline.ps1
# Enhanced pipeline execution system for AMH2W

function New-PipelineContext {
    param(
        [Parameter(Mandatory=$false)]
        [bool]$PromptOnOptionalError = $true,
        
        [Parameter(Mandatory=$false)]
        [bool]$Verbose = $false,
        
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

    return @{
        Prompt = $PromptOnOptionalError
        Verbose = $Verbose
        ContinueOnError = $ContinueOnError
        LogConfig = $LogConfig
        Data = $Data
        History = @()  # Store execution history
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

    # Create default context if none provided
    if ($null -eq $Context) {
        $Context = New-PipelineContext
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
                    Log-Error "Fatal error: $($result.error)" -Context $Context
                    
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
        [Parameter(Mandatory=$true)]
        [hashtable]$Context
    )
    
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
