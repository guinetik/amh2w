# all/my/homies/fetch.ps1
param(
    [Parameter(Position = 0)]
    [string]$Url,
    
    [Parameter(Position = 1)]
    [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS")]
    [string]$Method = "GET",
    
    [Parameter(Position = 2)]
    [string]$Body = "",
    
    [Parameter(Position = 3)]
    [string]$OutFile = "",
    
    [Parameter()]
    [string]$Headers = "",
    
    [Parameter()]
    [string]$Params = "",
    
    [Parameter()]
    [switch]$AsJson = $false,
    
    [Parameter()]
    [switch]$AsForm = $false,
    
    [Parameter()]
    [int]$Timeout = 30,
    
    [Parameter()]
    [string]$Username = "",
    
    [Parameter()]
    [string]$Password = "",
    
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$Context = New-PipelineContext

function Format-ByteSize {
    param(
        [long]$Bytes
    )
    
    if ($Bytes -ge 1GB) {
        return "{0:0.00} GB" -f ($Bytes / 1GB)
    }
    elseif ($Bytes -ge 1MB) {
        return "{0:0.00} MB" -f ($Bytes / 1MB)
    }
    elseif ($Bytes -ge 1KB) {
        return "{0:0.00} KB" -f ($Bytes / 1KB)
    }
    else {
        return "$Bytes bytes"
    }
}

function ConvertFrom-ParamString {
    param(
        [string]$ParamString
    )
    
    $params = @{}
    if (-not [string]::IsNullOrWhiteSpace($ParamString)) {
        $pairs = $ParamString -split ','
        foreach ($pair in $pairs) {
            $keyValue = $pair -split '='
            if ($keyValue.Length -eq 2) {
                $key = $keyValue[0].Trim()
                $value = $keyValue[1].Trim()
                $params[$key] = $value
            }
        }
    }
    
    return $params
}

function ConvertFrom-HeaderString {
    param(
        [string]$HeaderString
    )
    
    $headers = @{}
    if (-not [string]::IsNullOrWhiteSpace($HeaderString)) {
        $pairs = $HeaderString -split ','
        foreach ($pair in $pairs) {
            $keyValue = $pair -split '='
            if ($keyValue.Length -eq 2) {
                $key = $keyValue[0].Trim()
                $value = $keyValue[1].Trim()
                $headers[$key] = $value
            }
        }
    }
    
    return $headers
}

function fetch() {
    # Begin the HTTP request process
    Log info "Preparing HTTP $Method request to $Url" $Context

    try {
        # Start the clock for timing
        Start-Clock
    
        # Create the web request parameters
        $webParams = @{
            Uri             = $Url
            Method          = $Method
            TimeoutSec      = $Timeout
            UseBasicParsing = $true
        }
    
        # Add query parameters if provided
        if (-not [string]::IsNullOrWhiteSpace($Params)) {
            $queryParams = ConvertFrom-ParamString -ParamString $Params
        
            $uriBuilder = New-Object System.UriBuilder($Url)
            $query = [System.Web.HttpUtility]::ParseQueryString($uriBuilder.Query)
        
            foreach ($key in $queryParams.Keys) {
                $query[$key] = $queryParams[$key]
            }
        
            $uriBuilder.Query = $query.ToString()
            $webParams.Uri = $uriBuilder.Uri.ToString()
        }
    
        Log info "Final URL: $($webParams.Uri)" $Context
    
        # Add headers if provided
        if (-not [string]::IsNullOrWhiteSpace($Headers)) {
            $headerDict = ConvertFrom-HeaderString -HeaderString $Headers
            $webParams.Headers = $headerDict
        
            Log info "Added $($headerDict.Count) custom headers" $Context
        }
    
        # Add authentication if provided
        if (-not [string]::IsNullOrWhiteSpace($Username) -and -not [string]::IsNullOrWhiteSpace($Password)) {
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${Username}:${Password}")))
            if ($null -eq $webParams.Headers) {
                $webParams.Headers = @{}
            }
            $webParams.Headers["Authorization"] = "Basic $base64AuthInfo"
        
            Log info "Added Basic authentication" $Context
        }
    
        # Add body if provided
        if (-not [string]::IsNullOrWhiteSpace($Body)) {
            if ($AsJson) {
                $webParams.ContentType = "application/json"
                $webParams.Body = $Body
                Log info "Added JSON body" $Context
            }
            elseif ($AsForm) {
                $webParams.ContentType = "application/x-www-form-urlencoded"
                $webParams.Body = $Body
                Log info "Added form body" $Context
            }
            else {
                $webParams.Body = $Body
                Log info "Added raw body" $Context
            }
        }
    
        # Add output file if provided
        if (-not [string]::IsNullOrWhiteSpace($OutFile)) {
            $webParams.OutFile = $OutFile
            Log info "Will save response to file: $OutFile" $Context
        }
    
        # Execute the request
        Log info "Sending request..." $Context
    
        $response = Invoke-WebRequest @webParams
    
        # Stop the clock and get elapsed time
        $clockStopResult = Stop-Clock
    
        # Process the response
        $statusCode = $response.StatusCode
        $isSuccess = [int]$statusCode -ge 200 -and [int]$statusCode -lt 300
    
        if (-not [string]::IsNullOrWhiteSpace($OutFile)) {
            # Get file info for downloaded file
            $fileInfo = Get-Item $OutFile
            $fileSize = $fileInfo.Length
            $fileSizeFormatted = Format-ByteSize -Bytes $fileSize
        
            # Calculate download speed
            $totalSeconds = [double]$clockStopResult.value.TotalSeconds
            $downloadSpeedBps = $fileSize / $totalSeconds
            $downloadSpeedFormatted = Format-ByteSize -Bytes $downloadSpeedBps
        
            $message = "Downloaded $fileSizeFormatted to $OutFile in $($clockStopResult.value.ElapsedTime) ($downloadSpeedFormatted/s)"
            if ($isSuccess) {
                Log success $message $Context
            }
            else {
                Log error $message $Context
            }
        
            # Return result
            if ($isSuccess) {
                return Ok @{
                    StatusCode             = $statusCode
                    File                   = $OutFile
                    FileSize               = $fileSize
                    FileSizeFormatted      = $fileSizeFormatted
                    Duration               = $clockStopResult.value.ElapsedTime
                    DownloadSpeed          = $downloadSpeedBps
                    DownloadSpeedFormatted = "$downloadSpeedFormatted/s"
                    Clock                  = $clockStopResult.value
                }
            }
            else {
                return Err "Request failed with status code: $statusCode"
            }
        }
        else {
            # Process the response content
            $contentLength = 0
            if ($null -ne $response.Content) {
                $contentLength = $response.Content.Length
            }
            elseif ($null -ne $response.RawContent) {
                $contentLength = $response.RawContent.Length
            }
        
            $contentLengthFormatted = Format-ByteSize -Bytes $contentLength
        
            # Calculate download speed
            $totalSeconds = [double]$clockStopResult.value.TotalSeconds
            $downloadSpeedBps = $contentLength / $totalSeconds
            $downloadSpeedFormatted = Format-ByteSize -Bytes $downloadSpeedBps
        
            $message = "Received $contentLengthFormatted in $($clockStopResult.value.ElapsedTime) ($downloadSpeedFormatted/s)"
            if ($isSuccess) {
                Log success $message $Context
                Log success "Status: $statusCode - $($response.StatusDescription)" $Context
            }
            else {
                Log error $message $Context
                Log error "Status: $statusCode - $($response.StatusDescription)" $Context
            }
        
            # Return result
            if ($isSuccess) {
                # Try to parse content as JSON if it looks like JSON
                $responseContent = $response.Content
                $responseObject = $null
            
                if ($response.Content -and ($response.Content.StartsWith("{") -or $response.Content.StartsWith("["))) {
                    try {
                        $responseObject = $response.Content | ConvertFrom-Json
                    }
                    catch {
                        # Not valid JSON, ignore
                        $responseObject = $null
                    }
                }

                if ($Context.verbose) {
                    Write-Host "Response Status: $statusCode" -ForegroundColor Cyan
                
                    # If content is JSON, pretty print it with proper formatting
                    if ($null -ne $responseObject) {
                        Write-Host "Response Content:" -ForegroundColor Cyan
                        $output = Format-JsonWithTags $responseContent
                        Write-Host $output | ConvertTo-Json -Depth 3
                    }
                    else {
                        # Only show raw content if it's not already shown as formatted JSON
                        Write-Host "Response Content:" -ForegroundColor Cyan
                        Write-Host "  $responseContent"
                    }
                }
            
                return Ok @{
                    StatusCode             = $statusCode
                    Status                 = "$statusCode $($response.StatusDescription)"
                    Headers                = $response.Headers
                    Content                = $responseContent
                    ContentObject          = $responseObject
                    ContentLength          = $contentLength
                    ContentLengthFormatted = $contentLengthFormatted
                    Duration               = $clockStopResult.value.ElapsedTime
                    DownloadSpeed          = $downloadSpeedBps
                    DownloadSpeedFormatted = "$downloadSpeedFormatted/s"
                    Clock                  = $clockStopResult.value
                }
            }
            else {
                return Err "Request failed with status code: $statusCode"
            }
        }
    }
    catch {
        # Stop the clock even if there was an error
        Stop-Clock
        Log error "Request failed after $($clockStopResult.value.ElapsedTime): $_" $Context
        return Err "Request failed: $_"
    }
}

# Only run main if this script is NOT being dot-sourced
if ($Url) {
    fetch
}