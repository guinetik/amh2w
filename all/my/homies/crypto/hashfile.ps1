function hashfile {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Path,

        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateSet("md5", "sha1", "sha256", "sha512")]
        [string]$Algorithm
    )

    try {
        if (-not (Test-Path $Path)) {
            return Err -Message "File not found at path: $Path"
        }

        $stream = [System.IO.File]::OpenRead($Path)
        $hashAlgo = switch ($Algorithm) {
            "md5"    { [System.Security.Cryptography.MD5]::Create() }
            "sha1"   { [System.Security.Cryptography.SHA1]::Create() }
            "sha256" { [System.Security.Cryptography.SHA256]::Create() }
            "sha512" { [System.Security.Cryptography.SHA512]::Create() }
        }

        $hash = ($hashAlgo.ComputeHash($stream) | ForEach-Object { $_.ToString("x2") }) -join ""
        $stream.Close()

        $result = [PSCustomObject]@{
            File     = $Path
            Algorithm = $Algorithm.ToUpper()
            Hash      = $hash
        }

        Show-JsonTable @($result)
        return Ok -Value $result -Message "$Algorithm hash computed"
    }
    catch {
        return Err -Message "Hashing failed: $_"
    }
}
