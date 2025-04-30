# all/my/browser.ps1
param(
    [Parameter(Position = 0)]
    [string]$Url,
    
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'

$Context = New-PipelineContext

function browser() {
    # Add http:// prefix if missing
    if (-not ($Url -match "^https?://") -and -not ($Url -match "^www\.")) {
        $Url = "https://$Url"
        Log info "Added https:// prefix to URL: $Url" $Context
    }
    elseif ($Url -match "^www\.") {
        $Url = "https://$Url"
        Log info "Added https:// prefix to URL: $Url" $Context
    }

    # Open URL in default browser
    Log info "Opening URL in default browser: $Url" $Context

    $result = Invoke-Pipeline -Steps @(
        {
            try {
                Start-Process $Url
                return Ok "Browser launched with URL: $Url"
            }
            catch {
                return Err "Failed to open URL in browser: $_"
            }
        }
    ) -Context $Context

    if ($result) {
        Write-Host "✅ URL opened in default browser: $Url" -ForegroundColor Green
    }

    # Return result for pipeline
    return Ok "URL opened in default browser: $Url"
}

# Validate URL
if ($Url) {
    browser
}