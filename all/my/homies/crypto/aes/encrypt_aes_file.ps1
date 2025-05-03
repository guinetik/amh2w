function encryptfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [SecureString]$Password
    )

    function DeriveKeyFromPassword {
        param([SecureString]$Password)
        $sha = [System.Security.Cryptography.SHA256]::Create()
        # Convert SecureString to string
        $passwordString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
        return $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($passwordString))
    }

    function EncryptFileInternal {
        [CmdletBinding(DefaultParameterSetName = 'SecureString')]
        param(
            [Parameter(Mandatory = $true)]
            [string[]]$FileName,
    
            [Parameter(Mandatory = $true)]
            [byte[]]$KeyBytes,
    
            [string]$Algorithm = 'AES',
            [System.Security.Cryptography.CipherMode]$CipherMode = [System.Security.Cryptography.CipherMode]::CBC,
            [System.Security.Cryptography.PaddingMode]$PaddingMode = [System.Security.Cryptography.PaddingMode]::PKCS7
        )
    
        try {
            $Crypto = [System.Security.Cryptography.SymmetricAlgorithm]::Create($Algorithm)
            $Crypto.KeySize = $KeyBytes.Length * 8
            $Crypto.Key = $KeyBytes
            $Crypto.Mode = $CipherMode
            $Crypto.Padding = $PaddingMode
    
            $results = @()
            $Files = Get-Item -LiteralPath $FileName
    
            foreach ($File in $Files) {
                $DestinationFile = Join-Path $File.DirectoryName "$($File.BaseName)_encrypted$($File.Extension)"
    
                $reader = $null
                $writer = $null
                $cryptoStream = $null
                try {
                    $reader = [System.IO.File]::OpenRead($File.FullName)
                    $writer = [System.IO.File]::Open($DestinationFile, [System.IO.FileMode]::Create)
    
                    $Crypto.GenerateIV()
                    $writer.Write([System.BitConverter]::GetBytes($Crypto.IV.Length), 0, 4)
                    $writer.Write($Crypto.IV, 0, $Crypto.IV.Length)
    
                    $transform = $Crypto.CreateEncryptor()
                    $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($writer, $transform, 'Write')
                    $reader.CopyTo($cryptoStream)
    
                    $cryptoStream.FlushFinalBlock()
    
                    $info = Get-Item $DestinationFile
                    $info | Add-Member NoteProperty SourceFile   $File.FullName
                    $info | Add-Member NoteProperty Algorithm    $Algorithm
                    $info | Add-Member NoteProperty CipherMode   $Crypto.Mode
                    $info | Add-Member NoteProperty PaddingMode  $Crypto.Padding
    
                    $results += $info
                }
                catch {
                    if ($writer) { $writer.Close() }
                    if (Test-Path $DestinationFile) { Remove-Item $DestinationFile -Force }
                    Write-Error "Encryption failed for $($File.FullName): $_"
                }
                finally {
                    if ($cryptoStream) { $cryptoStream.Close() }
                    if ($reader) { $reader.Close() }
                    if ($writer) { $writer.Close() }
                }
            }
    
            return Ok -Value $results -Message "$($results.Count) file(s) encrypted"
        }
        catch {
            return Err -Message "Encryption error: $_"
        }
    }

    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $keyBytes = DeriveKeyFromPassword $Password
        $result = EncryptFileInternal -FileName $Path -KeyBytes $keyBytes
        $stopwatch.Stop()
        if ($result.ok) {
            Write-Host "✅ File encrypted in $([math]::Round($stopwatch.Elapsed.TotalSeconds, 1)) sec" -ForegroundColor Green
        }
        return $result
    }
    catch {
        Write-Host "Error: Command function '$arg' failed: $_" -ForegroundColor Red
        return Err -Message "Top-level error: $_"
    }
}
