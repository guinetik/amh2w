# FTP/SFTP Client
# Supports both FTP (using .NET) and SFTP (using WinSCP)
# I used this for FTP: https://www.sftp.net/public-online-ftp-servers
# I used this for SFTP: https://sftpcloud.io/tools/free-sftp-server

function iftp {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateSet("connect", "ls", "download", "upload", "disconnect", "test")]
        [string] $Action,

        [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
        [object[]] $Rest
    )

    $result = switch ($Action) {
        "connect" {
            $server   = if ($Rest.Count -ge 1) { $Rest[0] } else { Read-Host "FTP/SFTP Server (e.g. host:port)" }
            $username = if ($Rest.Count -ge 2) { $Rest[1] } else { Read-Host "Username" }

            if ($Rest.Count -ge 3) {
                $rawPw = $Rest[2]
            } else {
                $rawPw = Read-Host "Password" -AsSecureString
            }

            # Normalize SecureString if user passed plain text somehow
            $password = if ($rawPw -is [System.Security.SecureString]) {
                $rawPw
            } else {
                ConvertTo-SecureString $rawPw -AsPlainText -Force
            }

            Connect-Rfs $server $username $password
        }

        "ls" {
            $remote = if ($Rest.Count -ge 1) { $Rest[0] } else { "/" }
            Get-RfsItem $remote
        }

        "download" {
            $remote = if ($Rest.Count -ge 1) { $Rest[0] } else { Read-Host "Remote file path" }
            $local  = if ($Rest.Count -ge 2) { $Rest[1] } else { Read-Host "Local file path" }
            Receive-RfsItem $remote $local
        }

        "upload" {
            $local  = if ($Rest.Count -ge 1) { $Rest[0] } else { Read-Host "Local file path" }
            $remote = if ($Rest.Count -ge 2) { $Rest[1] } else { Read-Host "Remote target path" }
            Send-RfsItem $local $remote
        }

        "disconnect"  { Disconnect-Rfs }
        "test"        { Test-Rfs }
    }

    return $result
}

# RFS (Remote File System) unified interface
$script:rfsSession = $null

function Connect-Rfs {
    param(
        [Parameter(Position = 0, Mandatory = $true)][string] $Server,
        [Parameter(Position = 1, Mandatory = $true)][string] $Username,
        [Parameter(Position = 2, Mandatory = $true)][SecureString] $Password
    )

    # Parse host:port
    if ($Server -match '(.+):(\d+)$') {
        $hostname = $matches[1]
        $port = [int]$matches[2]
    } else {
        $hostname = $Server
        $port = 21  # Default to FTP
    }

    # Determine protocol based on port
    $isSftp = $port -eq 22
    
    if ($isSftp) {
        return Connect-Sftp $hostname $port $Username $Password
    } else {
        return Connect-Ftp $Server $Username $Password
    }
}

function Connect-Sftp {
    param(
        [Parameter(Position = 0, Mandatory = $true)][string] $Hostname,
        [Parameter(Position = 1, Mandatory = $true)][int] $Port,
        [Parameter(Position = 2, Mandatory = $true)][string] $Username,
        [Parameter(Position = 3, Mandatory = $true)][SecureString] $Password
    )

    try {
        # Check if WinSCP is installed
        $winscpPaths = @(
            "C:\Program Files (x86)\WinSCP\WinSCPnet.dll",
            "C:\Program Files\WinSCP\WinSCPnet.dll",
            "$env:LOCALAPPDATA\Programs\WinSCP\WinSCPnet.dll"
        )
        
        $winscpPath = $null
        foreach ($path in $winscpPaths) {
            if (Test-Path $path) {
                $winscpPath = $path
                break
            }
        }
        
        if (-not $winscpPath) {
            return Err -Msg "WinSCP not found. Please install it using: choco install winscp"
        }
        
        Add-Type -Path $winscpPath
        
        # Convert SecureString to plain text
        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        )

        $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
            Protocol = [WinSCP.Protocol]::Sftp
            HostName = $Hostname
            PortNumber = $Port
            UserName = $Username
            Password = $plainPassword
            GiveUpSecurityAndAcceptAnySshHostKey = $true
        }

        $session = New-Object WinSCP.Session
        $session.Open($sessionOptions)

        $script:rfsSession = @{
            Type = "SFTP"
            Session = $session
            Server = "$Hostname`:$Port"
        }
        
        Log-Info "[sftp] Connected to $Hostname`:$Port as $Username"
        return Ok -Value "Connected to $Hostname`:$Port as $Username (SFTP)"
    } catch {
        Log-Error "[sftp] Connection failed: $_"
        return Err -Msg "Connection failed: $_"
    }
}

function Connect-Ftp {
    param(
        [Parameter(Position = 0, Mandatory = $true)][string] $Server,
        [Parameter(Position = 1, Mandatory = $true)][string] $Username,
        [Parameter(Position = 2, Mandatory = $true)][SecureString] $Password
    )

    try {
        $creds = New-Object System.Net.NetworkCredential($Username, $Password)

        # Clean up server string
        $Server = $Server -replace '^ftp://', ''

        # Attempt test connection immediately
        $uri = "ftp://$Server/"
        $req = [System.Net.FtpWebRequest]::Create($uri)
        $req.Method = [System.Net.WebRequestMethods+Ftp]::PrintWorkingDirectory
        $req.Credentials = $creds
        $res = $req.GetResponse()
        $res.Close()

        # Store session if successful
        $script:rfsSession = @{
            Type = "FTP"
            Server = $Server
            Creds = $creds
        }
        
        Log-Info "[ftp] Connected to $Server as $Username"
        return Ok -Value "Connected to $Server as $Username (FTP)"
    } catch {
        Log-Error "[ftp] Connection failed: $_"
        return Err -Msg "Connection failed: $_"
    }
}

function Get-RfsItem {
    param(
        [Parameter(Position = 0)][string] $RemotePath = "/"
    )

    if (-not $script:rfsSession) {
        return Err -Msg "Not connected."
    }

    switch ($script:rfsSession.Type) {
        "FTP" { return Get-FtpItem $RemotePath }
        "SFTP" { return Get-SftpItem $RemotePath }
    }
}

function Get-FtpItem {
    param([string] $RemotePath)

    try {
        $uri = "ftp://$($script:rfsSession.Server)$RemotePath"
        $req = [System.Net.FtpWebRequest]::Create($uri)
        $req.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
        $req.Credentials = $script:rfsSession.Creds
        $res = $req.GetResponse()
        $reader = New-Object IO.StreamReader $res.GetResponseStream()
        $content = $reader.ReadToEnd()
        $reader.Close(); $res.Close()
        
        # Write content as table
        Write-Host $content | Format-Table -AutoSize
        return Ok -Value $content
    } catch {
        Log-Error "[ftp] Failed to list directory: $_"
        return Err -Msg "Failed to list directory: $_"
    }
}

function Get-SftpItem {
    param([string] $RemotePath)

    try {
        $listing = $script:rfsSession.Session.ListDirectory($RemotePath)
        $output = ""
        foreach ($item in $listing.Files) {
            if ($item.Name -eq "." -or $item.Name -eq "..") { continue }
            $output += "{0,-40} {1,10} {2}`n" -f $item.Name, $item.Length, $item.LastWriteTime
        }
        Write-Host $output | Format-Table -AutoSize
        return Ok -Value $output
    } catch {
        Log-Error "[sftp] Failed to list directory: $_"
        return Err -Msg "Failed to list directory: $_"
    }
}

function Receive-RfsItem {
    param(
        [Parameter(Position = 0)][string] $RemotePath,
        [Parameter(Position = 1)][string] $LocalPath
    )

    if (-not $script:rfsSession) {
        return Err -Msg "Not connected."
    }

    switch ($script:rfsSession.Type) {
        "FTP" { return Receive-FtpItem $RemotePath $LocalPath }
        "SFTP" { return Receive-SftpItem $RemotePath $LocalPath }
    }
}

function Receive-FtpItem {
    param([string] $RemotePath, [string] $LocalPath)

    try {
        # Convert PathInfo to string if needed
        if ($LocalPath -is [System.Management.Automation.PathInfo]) {
            $LocalPath = $LocalPath.Path
        }
        
        # If local path is not provided or is ".", use current directory
        if ([string]::IsNullOrEmpty($LocalPath) -or $LocalPath -eq ".") {
            $LocalPath = (Get-Location).Path
        }
        
        # If local path is not absolute, make it relative to current directory
        if (-not [System.IO.Path]::IsPathRooted($LocalPath)) {
            $LocalPath = Join-Path (Get-Location).Path $LocalPath
        }
        
        # If local path is a directory, append the remote filename
        if (Test-Path $LocalPath -PathType Container) {
            $remoteFileName = Split-Path -Path $RemotePath -Leaf
            $LocalPath = Join-Path $LocalPath $remoteFileName
        }
        
        # Ensure remote path starts with /
        if (-not $RemotePath.StartsWith("/")) {
            $RemotePath = "/" + $RemotePath
        }
        
        Log-Info "[ftp] 📥 Downloading '$RemotePath' to '$LocalPath'..."
        
        $uri = "ftp://$($script:rfsSession.Server)$RemotePath"
        $req = [System.Net.FtpWebRequest]::Create($uri)
        $req.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
        $req.Credentials = $script:rfsSession.Creds
        $res = $req.GetResponse()
        $stream = $res.GetResponseStream()
        $file = [System.IO.File]::Create($LocalPath)
        $buf = New-Object byte[] 8192
        $totalBytes = 0
        
        while (($n = $stream.Read($buf, 0, $buf.Length)) -gt 0) {
            $file.Write($buf, 0, $n)
            $totalBytes += $n
        }
        
        $file.Close()
        $stream.Close()
        $res.Close()
        
        $fileSize = [math]::Round($totalBytes / 1MB, 2)
        Log-Info "[ftp] ✅ Downloaded successfully to '$LocalPath' ($fileSize MB)"
        
        return Ok -Value "Downloaded to $LocalPath"
    } catch {
        Log-Error "[ftp] ❌ Download failed: $_"
        return Err -Msg "Download failed: $_"
    }
}

function Receive-SftpItem {
    param([string] $RemotePath, [string] $LocalPath)

    try {
        # If local path is not provided or is ".", use current directory
        if ([string]::IsNullOrEmpty($LocalPath) -or $LocalPath -eq ".") {
            $LocalPath = (Get-Location).Path
        }
        
        # If local path is not absolute, make it relative to current directory
        if (-not [System.IO.Path]::IsPathRooted($LocalPath)) {
            $LocalPath = Join-Path (Get-Location).Path $LocalPath
        }
        
        # If local path is a directory, append the remote filename
        if (Test-Path $LocalPath -PathType Container) {
            $remoteFileName = Split-Path -Path $RemotePath -Leaf
            $LocalPath = Join-Path $LocalPath $remoteFileName
        }
        
        Log-Info "[sftp] 📥 Downloading '$RemotePath' to '$LocalPath'..."
        
        $transferResult = $script:rfsSession.Session.GetFiles($RemotePath, $LocalPath, $false)
        $transferResult.Check()
        
        if (Test-Path $LocalPath) {
            $fileInfo = Get-Item $LocalPath
            $fileSize = [math]::Round($fileInfo.Length / 1MB, 2)
            Log-Info "[sftp] ✅ Downloaded successfully to '$LocalPath' ($fileSize MB)"
        } else {
            Log-Info "[sftp] ✅ Downloaded successfully to '$LocalPath'"
        }
        
        return Ok -Value "Downloaded to $LocalPath"
    } catch {
        Log-Error "[sftp] ❌ Download failed: $_"
        return Err -Msg "Download failed: $_"
    }
}

function Send-RfsItem {
    param(
        [Parameter(Position = 0)][string] $LocalPath,
        [Parameter(Position = 1)][string] $RemotePath
    )

    if (-not $script:rfsSession) {
        return Err -Msg "Not connected."
    }

    switch ($script:rfsSession.Type) {
        "FTP" { return Send-FtpItem $LocalPath $RemotePath }
        "SFTP" { return Send-SftpItem $LocalPath $RemotePath }
    }
}

function Send-FtpItem {
    param([string] $LocalPath, [string] $RemotePath)

    try {
        # Convert PathInfo to string if needed
        if ($LocalPath -is [System.Management.Automation.PathInfo]) {
            $LocalPath = $LocalPath.Path
        }
        
        # If local path is not absolute, make it relative to current directory
        if (-not [System.IO.Path]::IsPathRooted($LocalPath)) {
            $LocalPath = Join-Path (Get-Location).Path $LocalPath
        }
        
        # Check if local file exists
        if (-not (Test-Path $LocalPath -PathType Leaf)) {
            throw "Local file not found: $LocalPath"
        }
        
        # If remote path is not provided or is relative, handle it properly
        if ([string]::IsNullOrEmpty($RemotePath) -or $RemotePath -eq "." -or $RemotePath -eq "./") {
            $RemotePath = "/"
        }
        
        # If remote path doesn't include filename, append local filename
        if ($RemotePath.EndsWith("/") -or $RemotePath -eq "/") {
            $localFileName = Split-Path -Path $LocalPath -Leaf
            $RemotePath = $RemotePath.TrimEnd('/') + "/" + $localFileName
        }
        
        # Ensure remote path starts with /
        if (-not $RemotePath.StartsWith("/")) {
            $RemotePath = "/" + $RemotePath
        }
        
        Log-Info "[ftp] 📤 Uploading '$LocalPath' to '$RemotePath'..."
        
        $uri = "ftp://$($script:rfsSession.Server)$RemotePath"
        $req = [System.Net.FtpWebRequest]::Create($uri)
        $req.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
        $req.Credentials = $script:rfsSession.Creds
        $req.UseBinary = $true
        
        $bytes = [System.IO.File]::ReadAllBytes($LocalPath)
        $req.ContentLength = $bytes.Length
        
        $stream = $req.GetRequestStream()
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Close()
        
        $response = $req.GetResponse()
        $response.Close()
        
        $fileSize = [math]::Round($bytes.Length / 1MB, 2)
        Log-Info "[ftp] ✅ Uploaded successfully to '$RemotePath' ($fileSize MB)"
        
        return Ok -Value "Uploaded to $RemotePath"
    } catch {
        Log-Error "[ftp] ❌ Upload failed: $_"
        return Err -Msg "Upload failed: $_"
    }
}

function Send-SftpItem {
    param([string] $LocalPath, [string] $RemotePath)

    try {
        # Convert PathInfo to string if needed
        if ($LocalPath -is [System.Management.Automation.PathInfo]) {
            $LocalPath = $LocalPath.Path
        }
        
        # If local path is not absolute, make it relative to current directory
        if (-not [System.IO.Path]::IsPathRooted($LocalPath)) {
            $LocalPath = Join-Path (Get-Location).Path $LocalPath
        }
        
        # Check if local file exists
        if (-not (Test-Path $LocalPath -PathType Leaf)) {
            throw "Local file not found: $LocalPath"
        }
        
        # If remote path is not provided or is relative, handle it properly
        if ([string]::IsNullOrEmpty($RemotePath) -or $RemotePath -eq "." -or $RemotePath -eq "./") {
            $RemotePath = "/"
        }
        
        # If remote path is a directory, append local filename
        if ($RemotePath.EndsWith("/")) {
            $localFileName = Split-Path -Path $LocalPath -Leaf
            $RemotePath = $RemotePath + $localFileName
        }
        
        Log-Info "[sftp] 📤 Uploading '$LocalPath' to '$RemotePath'..."
        
        $transferResult = $script:rfsSession.Session.PutFiles($LocalPath, $RemotePath, $false)
        $transferResult.Check()
        
        $fileInfo = Get-Item $LocalPath
        $fileSize = [math]::Round($fileInfo.Length / 1MB, 2)
        Log-Info "[sftp] ✅ Uploaded successfully to '$RemotePath' ($fileSize MB)"
        
        return Ok -Value "Uploaded to $RemotePath"
    } catch {
        Log-Error "[sftp] ❌ Upload failed: $_"
        return Err -Msg "Upload failed: $_"
    }
}

function Disconnect-Rfs {
    if (-not $script:rfsSession) {
        return Ok -Value "No active session."
    }

    try {
        switch ($script:rfsSession.Type) {
            "SFTP" {
                $script:rfsSession.Session.Dispose()
            }
        }
        $script:rfsSession = $null
        Log-Info "Session ended."
        return Ok -Value "Session ended."
    } catch {
        Log-Error "Disconnect failed: $_"
        return Err -Msg "Disconnect failed: $_"
    }
}

function Test-Rfs {
    if (-not $script:rfsSession) {
        return Err -Msg "No active session."
    }

    try {
        switch ($script:rfsSession.Type) {
            "FTP" {
                $uri = "ftp://$($script:rfsSession.Server)/"
                $req = [System.Net.FtpWebRequest]::Create($uri)
                $req.Method = [System.Net.WebRequestMethods+Ftp]::PrintWorkingDirectory
                $req.Credentials = $script:rfsSession.Creds
                $res = $req.GetResponse()
                $res.Close()
            }
            "SFTP" {
                $script:rfsSession.Session.FileExists("/")
            }
        }
        Log-Info "Connection test passed for $($script:rfsSession.Server)"
        return Ok -Value "Connection test passed"
    } catch {
        Log-Error "Connection test failed: $_"
        return Err -Msg "Connection test failed: $_"
    }
}

# Export only the main function
Export-ModuleMember -Function iftp