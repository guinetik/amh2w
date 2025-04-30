function New-PipelineContext {
    param(
        [bool]$PromptOnOptionalError = $true,
        [bool]$Verbose = $true,
        [hashtable]$LogColors = @{ 
            info = 'Gray'; 
            success = 'Green'; 
            error = 'Red'; 
            warn = 'Yellow' 
        }
    )

    return @{
        prompt = $PromptOnOptionalError
        verbose = $Verbose
        logColors = $LogColors
    }
}

function Invoke-Pipeline {
    param(
        [ScriptBlock[]]$Steps,
        [hashtable]$Context = (New-PipelineContext)
    )

    $stepNumber = 0
    $totalSteps = $Steps.Count
    
    foreach ($step in $Steps) {
        $stepNumber++
        Log info "Step $stepNumber / $totalSteps : Starting..." $Context
        $result = & $step
        if (-not $result.ok) {
            if ($result.optional) {
                Log warn "Optional step failed: $($result.error)" $Context
                if ($Context.prompt) {
                    $resp = Read-Host "❓ Continue anyway? (Y/N)"
                    if ($resp -ne "Y") {
                        Log error "Aborted by user input." $Context
                        exit 1
                    }
                }
                continue
            }

            Log error "Fatal error: $($result.error)" $Context
            exit 1
        }

        Log success "Step completed: $($result.value)" $Context
        
        # Pass the result to the next step
        $nextStep = $stepNumber
        if ($nextStep -lt $Steps.Count) {
            $Steps[$nextStep] = [ScriptBlock]::Create("param(`$input) $(${Steps[$nextStep]})")
            $Steps[$nextStep] = [ScriptBlock]::Create("$($result.value) | $(${Steps[$nextStep]})")
        }
    }
    
    Log success "Pipeline completed successfully." $Context
    return $true
}