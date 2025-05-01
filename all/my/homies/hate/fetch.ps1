# all/my/homies/hate/fetch.ps1
# HTTP request utility with advanced features

# Examples:
# Basic GET request
# all my homies hate fetch "https://jsonplaceholder.typicode.com/posts/1"

# POST request with JSON body
# all my homies hate fetch "https://jsonplaceholder.typicode.com/posts" -Method POST -Body '{"title":"foo","body":"bar","userId":1}' -AsJson

# Download a file
# all my homies hate fetch "https://example.com/file.zip" -OutFile "C:\Downloads\file.zip"

# Request with headers
# all my homies hate fetch "https://api.example.com/data" -Headers "api-key=1234,content-type=application/json"

# Request with query parameters
# all my homies hate fetch "https://api.example.com/users" -Params "page=1,limit=10"

# JSON formatting options
# all my homies hate fetch "https://jsonplaceholder.typicode.com/users" -JsonFormat pretty (nicely formatted with syntax highlighting)
# all my homies hate fetch "https://jsonplaceholder.typicode.com/users" -JsonFormat raw (unformatted JSON)
# all my homies hate fetch "https://jsonplaceholder.typicode.com/users" -JsonFormat tree (tree-style view)
# all my homies hate fetch "https://jsonplaceholder.typicode.com/users" -JsonFormat table (tabular format)
# all my homies hate fetch "https://jsonplaceholder.typicode.com/users" -JsonFormat chart (visual chart if appropriate)

# Suppress output display
# all my homies hate fetch "https://jsonplaceholder.typicode.com/users" -NoPrint

function fetch {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Url,
        
        [Parameter(Position = 1)]
        [ValidateSet("highlight", "view", "tree", "table", "explore", "pretty", "raw", "chart")]
        [string]$JsonFormat = "highlight",
        
        [Parameter(Position = 2)]
        [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS")]
        [string]$Method = "GET",
        
        [Parameter(Position = 3)]
        [string]$Body = "",
        
        [Parameter(Position = 4)]
        [string]$OutFile = "",
        
        [Parameter(Position = 5)]
        [string]$Headers = "",
        
        [Parameter(Position = 6)]
        [string]$Params = "",
        
        [Parameter(Position = 7)]
        [switch]$AsJson = $false,
        
        [Parameter(Position = 8)]
        [switch]$AsForm = $false,
        
        [Parameter(Position = 9)]
        [int]$Timeout = 30,
        
        [Parameter(Position = 10)]
        [string]$Username = "",
        
        [Parameter(Position = 11)]
        [string]$Password = "",
        
        [Parameter(Position = 12)]
        [switch]$NoPrint = $false,
        
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    try {
        Log-Info "Preparing HTTP $Method request to $Url"
        
        # If URL is missing, return error
        if ([string]::IsNullOrEmpty($Url)) {
            Log-Error "URL cannot be empty"
            return Err "URL cannot be empty. Please provide a valid URL."
        }
        
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
        
        Log-Debug "Final URL: $($webParams.Uri)"
        
        # Add headers if provided
        if (-not [string]::IsNullOrWhiteSpace($Headers)) {
            $headerDict = ConvertFrom-HeaderString -HeaderString $Headers
            $webParams.Headers = $headerDict
            
            Log-Debug "Added $($headerDict.Count) custom headers"
        }
        
        # Add authentication if provided
        if (-not [string]::IsNullOrWhiteSpace($Username) -and -not [string]::IsNullOrWhiteSpace($Password)) {
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${Username}:${Password}")))
            if ($null -eq $webParams.Headers) {
                $webParams.Headers = @{}
            }
            $webParams.Headers["Authorization"] = "Basic $base64AuthInfo"
            
            Log-Debug "Added Basic authentication"
        }
        
        # Add body if provided
        if (-not [string]::IsNullOrWhiteSpace($Body)) {
            if ($AsJson) {
                $webParams.ContentType = "application/json"
                $webParams.Body = $Body
                Log-Debug "Added JSON body"
            }
            elseif ($AsForm) {
                $webParams.ContentType = "application/x-www-form-urlencoded"
                $webParams.Body = $Body
                Log-Debug "Added form body"
            }
            else {
                $webParams.Body = $Body
                Log-Debug "Added raw body"
            }
        }
        
        # Add output file if provided
        if (-not [string]::IsNullOrWhiteSpace($OutFile)) {
            $webParams.OutFile = $OutFile
            Log-Info "Will save response to file: $OutFile"
        }
        
        # Execute the request
        Log-Info "Sending request..."
        
        $response = Invoke-WebRequest @webParams
        
        # Stop the clock and get elapsed time
        $clockResult = Stop-Clock
        
        # Process the response
        $statusCode = $response.StatusCode
        $isSuccess = [int]$statusCode -ge 200 -and [int]$statusCode -lt 300
        
        if (-not [string]::IsNullOrWhiteSpace($OutFile)) {
            # Get file info for downloaded file
            $fileInfo = Get-Item $OutFile
            $fileSize = $fileInfo.Length
            $fileSizeFormatted = Format-ByteSize -Bytes $fileSize
            
            # Calculate download speed
            $totalSeconds = [double]$clockResult.value.TotalSeconds
            $downloadSpeedBps = $fileSize / $totalSeconds
            $downloadSpeedFormatted = Format-ByteSize -Bytes $downloadSpeedBps
            
            $message = "Downloaded $fileSizeFormatted to $OutFile in $($clockResult.value.ElapsedTime) ($downloadSpeedFormatted/s)"
            if ($isSuccess) {
                Log-Success $message
            }
            else {
                Log-Error $message
            }
            
            # Return result
            if ($isSuccess) {
                return Ok -Value @{
                    StatusCode             = $statusCode
                    File                   = $OutFile
                    FileSize               = $fileSize
                    FileSizeFormatted      = $fileSizeFormatted
                    Duration               = $clockResult.value.ElapsedTime
                    DownloadSpeed          = $downloadSpeedBps
                    DownloadSpeedFormatted = "$downloadSpeedFormatted/s"
                    Clock                  = $clockResult.value
                } -Message "File downloaded successfully to $OutFile"
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
            $totalSeconds = [double]$clockResult.value.TotalSeconds
            $downloadSpeedBps = $contentLength / $totalSeconds
            $downloadSpeedFormatted = Format-ByteSize -Bytes $downloadSpeedBps
            
            $message = "Received $contentLengthFormatted in $($clockResult.value.ElapsedTime) ($downloadSpeedFormatted/s)"
            if ($isSuccess) {
                Log-Success $message
                Log-Success "Status: $statusCode - $($response.StatusDescription)"
            }
            else {
                Log-Error $message
                Log-Error "Status: $statusCode - $($response.StatusDescription)"
            }
            
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
            
            # Print response content if not suppressed
            if (-not $NoPrint) {
                Write-Host "--------------------------------"
                Write-Host "Response Status: $statusCode" -ForegroundColor Cyan
                # If content is JSON, use JSON utility
                if ($null -ne $responseObject) {
                    Write-Host "Formatted JSON: $JsonFormat"
                    # switch based on JsonFormat
                    switch ($JsonFormat) {
                        "pretty" {
                            Format-JsonWithTags -JsonObject $responseObject
                        }
                        "highlight" {
                            Format-JsonWithTags -JsonObject $responseObject
                        }
                        "raw" {
                            Write-Host $responseContent
                        }
                        "tree" {
                            Show-JsonTree -JsonObject $responseObject -MaxDepth 10
                        }
                        "table" {
                            Show-JsonTable -JsonObject $responseObject
                        }
                        "chart" {
                            Show-JsonBarChart -Data $responseObject
                        }
                        "explore" {
                            Invoke-JsonExplorer -JsonObject $responseObject
                        }
                    }
                }
                else {
                    # Show raw content if it's not JSON
                    Write-Host "Response Content:" -ForegroundColor Cyan
                    Write-Host $responseContent
                }
            }
            
            # Return result
            if ($isSuccess) {
                return Ok -Value @{
                    StatusCode             = $statusCode
                    Status                 = "$statusCode $($response.StatusDescription)"
                    Headers                = $response.Headers
                    Content                = $responseContent
                    ContentObject          = $responseObject
                    ContentLength          = $contentLength
                    ContentLengthFormatted = $contentLengthFormatted
                    Duration               = $clockResult.value.ElapsedTime
                    DownloadSpeed          = $downloadSpeedBps
                    DownloadSpeedFormatted = "$downloadSpeedFormatted/s"
                    Clock                  = $clockResult.value
                } -Message "Request completed successfully"
            }
            else {
                return Err "Request failed with status code: $statusCode"
            }
        }
    }
    catch {
        # Stop the clock even if there was an error
        try { Stop-Clock } catch { }
        Log-Error "Request failed: $_"
        return Err "Request failed: $_"
    }
}

# Helper function to format byte sizes
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

# Helper function to convert parameter string to hashtable
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

# Helper function to convert header string to hashtable
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

# Only run main if this script is NOT being dot-sourced
if ($MyInvocation.InvocationName -ne '.' -and $MyInvocation.MyCommand.Name -eq 'fetch.ps1') {
    fetch @PSBoundParameters
}
