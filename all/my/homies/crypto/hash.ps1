function hash {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Text,

        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateSet("md5", "sha1", "sha256", "sha512")]
        [string]$Algorithm
    )

    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)

        $hasher = switch ($Algorithm) {
            "md5"    { [System.Security.Cryptography.MD5]::Create() }
            "sha1"   { [System.Security.Cryptography.SHA1]::Create() }
            "sha256" { [System.Security.Cryptography.SHA256]::Create() }
            "sha512" { [System.Security.Cryptography.SHA512]::Create() }
        }

        $hashBytes = $hasher.ComputeHash($bytes)
        $hash = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })

        Write-Host "🔐 $Algorithm`:" -ForegroundColor Cyan
        Write-Host "   $hash" -ForegroundColor Green

        return Ok -Value $hash -Message "$Algorithm hash generated"
    }
    catch {
        return Err -Message "$Algorithm hashing failed: $_"
    }
} 